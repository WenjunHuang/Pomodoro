import { Setting } from "../model/Setting"
import { PersistenceV2 } from "@kit.ArkUI"

@Extend(Image)
function labelIconStyle() {
  .fillColor(Color.White)
  .width(24)
  .height(24)
}

@Builder
export function DailyGoalPageBuilder() {
  DailyGoalPage()
}

@ComponentV2
export struct DailyGoalPage {
  @Local settings: Setting = PersistenceV2.connect(Setting, () => new Setting())!
  @Consumer('pageInfos') pageInfos: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column() {
        Row() {
          Image($r("app.media.angle_left"))
            .labelIconStyle()
            .onClick(() => this.pageInfos.pop())
        }
        .justifyContent(FlexAlign.Start)
        .width('100%')

        Column() {
          Image($r("app.media.confetti"))
            .width("60%")
            .margin({ bottom: 64 })
          Text($r("app.string.daily_goal"))
            .fontColor(Color.White)
            .fontSize(14)
        }.justifyContent(FlexAlign.Center)
        .layoutWeight(1)
      }.width('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .hideTitleBar(true)
    .backgroundColor(this.settings.colorTheme)
    .animation({ duration: 300, curve: Curve.Ease })
    .onBackPressed(() => {
      this.pageInfos.pop()
      return true
    })
  }
}