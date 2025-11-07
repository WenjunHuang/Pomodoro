import { PomodoroTimer } from '../components/PomodoroTimer'
import { Setting } from '../model/Setting'
import { PersistenceV2 } from '@kit.ArkUI'
import { getDisabledColor } from '../utils/ColorUtils'

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
        }
        .width('100%')
        .onClick(() => {
          this.pageInfos.pushDestination({ name: "Setting" })
        })
        .margin({ bottom: 24 })

        PomodoroTimer({
          pomodoroCount: this.settings.pomodoro, pomodoroSeconds: 60, onRunning: (elapsed, total) => {
          },
        })
          .width('80%')
          .margin({ bottom: 64 })

        Row() {
          ForEach(Array.from({ length: Math.ceil(this.settings.dailyGoal / 3) }), (_: number, slot) => {
            Row() {
              ForEach(Array.from({ length: 3 }), (_: number, i) => {
                if ((slot * 3 + i) < this.settings.dailyGoal) {
                  Circle()
                    .width(this.settings.todayFinishedPomodoroCount() >= (slot * 3 + i + 1) ? 4 : 2)
                    .aspectRatio(1)
                    .flexShrink(1)
                    .fill(this.settings.todayFinishedPomodoroCount() >= (slot * 3 + i + 1) ? Color.White :
                      getDisabledColor("#FFFFFF"))
                } else {
                  Circle()
                    .width(4)
                    .aspectRatio(1)
                    .flexShrink(1)
                    .fill(Color.Transparent)
                }
              })
            }
            .width(28)
            .flexShrink(1)
            .justifyContent(FlexAlign.SpaceEvenly)
          }
          )
        }
        .width("50%")
        .justifyContent(FlexAlign.Center)

        Blank()
      }
      .padding(16)
      .width('100%')
      .height('100%')
    }
    .backgroundColor(this.settings.colorTheme)
    .hideTitleBar(true)
  }
}