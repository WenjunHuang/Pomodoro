import { PersistenceV2 } from '@kit.ArkUI'
import { Setting } from '../model/Setting'

@Builder
export function SettingPageBuilder() {
  SettingPage()
}

@ComponentV2
export struct SettingPage {
  @Local settings: Setting = PersistenceV2.globalConnect({ type: Setting, defaultCreator: () => new Setting() })!
  @Consumer('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  private scroller: Scroller = new Scroller()

  build() {
    NavDestination() {
      Scroll(this.scroller) {
        Column() {
          Text($r("app.string.setting_durations"))
            .textAlign(TextAlign.Center)
            .fontColor(Color.White)
            .width("100%")
            .margin({bottom:24})
          Row({space: 16}) {
            Column() {
              Text("14")
                .margin({ bottom: 16 })
              Text($r("app.string.setting_pomodoro"))
            }
            .padding({ top: 24, bottom: 24 })
            .alignItems(HorizontalAlign.Center)
            .backgroundColor("#77FFFF77")
            .width("33%")

            Column() {
              Text("14")
                .margin({ bottom: 16 })
              Text($r("app.string.setting_pomodoro"))
            }
            .padding({ top: 24, bottom: 24 })
            .alignItems(HorizontalAlign.Center)
            .backgroundColor("#77FFFF77")
            .width("33%")

            Column() {
              Text("14")
                .margin({ bottom: 16 })
              Text($r("app.string.setting_pomodoro"))
            }
            .padding({ top: 24, bottom: 24 })
            .alignItems(HorizontalAlign.Center)
            .backgroundColor("#77FFFF77")
            .width("33%")
          }
          .width('100%')
        }.width('100%')
      }

    }
    .width('100%')
    .height('100%')
    .hideTitleBar(true)
    .backgroundColor(
      this.settings.colorTheme)
    .onBackPressed(() => {
      this.pageInfos.pop()
      return true
    })
  }
}