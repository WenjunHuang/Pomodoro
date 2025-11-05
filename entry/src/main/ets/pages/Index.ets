import { AppStorageV2, PersistenceV2, uiObserver } from '@kit.ArkUI'
import { Setting } from '../model/Setting';
import { PomodoroTimer } from '../components/PomodoroTimer';

@Entry
@ComponentV2
export default struct Index {
  @Local settings: Setting = PersistenceV2.globalConnect({ type: Setting, defaultCreator: () => new Setting() })!
  @Provider('pageInfos')
  pageInfos: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.pageInfos) {
      Column() {
        Row() {
          Blank()
          Image($r("app.media.list"))
            .width(24)
            .height(24)
            .fillColor(Color.White)
            .margin({ right: 16 })
        }
        .width('100%')
        .margin({ top: 16, bottom: 24 })

        Blank()
        PomodoroTimer({
          pomodoroCount: this.settings.pomodoro, pomodoroSeconds: 60, onRunning: (elapsed, total) => {
          }
        }).width('90%')
        Blank()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.settings.colorTheme)
  }
}