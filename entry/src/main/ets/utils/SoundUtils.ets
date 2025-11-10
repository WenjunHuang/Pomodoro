import { media } from '@kit.MediaKit';
import { fileIo } from '@kit.CoreFileKit';
import { Logger } from './LogUtil';
import { vibrator } from '@kit.SensorServiceKit';

export function playFinishedSound(context: Context) {
  let resDir = context.resourceDir
  playSound(`file://${resDir}/glass.wav`)
}

export function playVibrate() {
  vibrator.startVibration({ type: "time", duration: 1000 }, { usage: "notification" })
    .catch((be: BusinessError<Object>) => {
      Logger.error("PlayVibrate: %{public}d, %{public}s", be.code, be.message)
    })
}

export function playSound(fileUrl: string) {
  media.createAVPlayer()
    .then(async (player) => {
      let f = await fileIo.open(fileUrl, fileIo.OpenMode.READ_ONLY)
      player.on('stateChange', async (state, reason) => {
        switch (state) {
          case 'initialized':
            player.prepare()
            break
          case 'prepared':
            player.play()
            break
          case 'completed':
            player.release()
            break
          case "released":
            fileIo.close(f)
        }
      })
      player.fdSrc = { fd: f.fd, offset: 0 }
    }).catch((be: BusinessError<Object>) => {
    Logger.error("PlaySound: %{public}d, %{public}s", be.code, be.message)
  })
}