import { media } from "@kit.MediaKit"
import hilog from "@ohos.hilog"
import { fileIo } from "@kit.CoreFileKit";

const DOMAIN = 0x0000;

export function playFinishedSound(context:Context){
  let resDir = context.resourceDir
  playSound(`file://${resDir}/glass.wav`)
}

export function playSound(fileUrl: string) {
  media.createAVPlayer()
    .then(async (player) => {
      try {
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
      } catch (e) {
        hilog.error(DOMAIN, "playSound", JSON.stringify(e))
      }
    })
}