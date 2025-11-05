import { PomodoroTimer } from '../components/PomodoroTimer'
import { Setting } from '../model/Setting'
import { PersistenceV2 } from '@kit.ArkUI'

@Builder
export function PomodoroClockPageBuilder() {
  PomodoroClockPage()
}

@ComponentV2
export struct PomodoroClockPage {
  @Local settings: Setting = PersistenceV2.globalConnect({ type: Setting, defaultCreator: () => new Setting() })!
  @Consumer('pageInfos') pageInfos: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
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
        .onClick((event) => {
          this.pageInfos.pushDestination({ name: "Setting" })
        })

        Blank()
        PomodoroTimer({
          pomodoroCount: this.settings.pomodoro, pomodoroSeconds: 60, onRunning: (elapsed, total) => {
          }
        }).width('90%')
        Blank()
      }
    }
    .backgroundColor(this.settings.colorTheme)
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
  }
}