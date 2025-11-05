import { PersistenceV2 } from '@kit.ArkUI'
import { Setting } from '../model/Setting'
import { themeColor, ThemeColors } from '../model/ThemeColors'
import { LabelTextStyle } from '../styles/SettingStyles'
import { adjustHexColor } from '../utils/ColorUtils'

@Builder
export function SettingPageBuilder() {
  SettingPage()
}

@Extend(Text)
function labelTextStyle() {
  .fontColor(Color.White)
  .fontSize(12)
  .textAlign(TextAlign.Center)
}

@Extend(Text)
function durationTextStyle() {
  .fontColor(Color.White)
  .fontSize(32)
  .fontWeight(FontWeight.Bold)
  .textAlign(TextAlign.Center)
}

@AnimatableExtend(NavDestination)
function animatableBackgroundColor(color: ResourceColor) {
  .backgroundColor(color) // 调用系统属性接口，逐帧回调函数每帧修改可动画属性的值，实现逐帧布局的效果。
}

@ComponentV2
export struct SettingPage {
  @Local settings: Setting = PersistenceV2.globalConnect({ type: Setting, defaultCreator: () => new Setting() })!
  @Consumer('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  private scroller: Scroller = new Scroller()
  // 颜色主题行数据
  private readonly colorThemeRows: Array<Array<string>> = [
    [ThemeColors.Coral, "", ThemeColors.LightGreen, "", ThemeColors.Turquoise, "", ThemeColors.Lavender, "",
      ThemeColors.DarkPurple],
    [ThemeColors.Mint, "", ThemeColors.GrayBlue, "", ThemeColors.Sage, "", ThemeColors.SeaGreen, "",
      ThemeColors.NavyBlue],
    [ThemeColors.Teal, "", ThemeColors.SageGreen, "", ThemeColors.Salmon, "", ThemeColors.OrangeRed, "",
      ThemeColors.Gold],
    [ThemeColors.Crimson, "", ThemeColors.Brown, "", ThemeColors.LightBlue, "", ThemeColors.Charcoal, "",
      ThemeColors.Emerald]
  ]

  build() {
    NavDestination() {
      Scroll(this.scroller) {
        Column() {
          Text($r("app.string.setting_durations"))
            .labelTextStyle()
            .margin({ bottom: 24, top: 24 })
          Row() {
            this.durationCard("14", $r("app.string.setting_pomodoro"))
            Blank(8)
            this.durationCard("1", $r("app.string.setting_break"))
            Blank(8)
            this.durationCard("1", $r("app.string.setting_long_break"))
          }
          .width('100%')

          Text($r("app.string.setting_color_themes"))
            .labelTextStyle()
            .margin({ bottom: 24, top: 24 })
          Column() {
            ForEach(this.colorThemeRows, (colors: Array<string>, rowIndex: number) => {
              if (rowIndex > 0) {
                Blank(6)
              }
              this.colorRow(colors)
            })
          }
          .width("100%")
          .padding(8)
          .animation({ duration: 200, curve: Curve.Ease })
          .background(this.labelBackground())

          Text($r("app.string.setting_sound_themes"))
            .labelTextStyle()
            .margin({ bottom: 24, top: 24 })
        }.width('100%')
        .padding(16)
      }
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

  @Builder
  private durationCard(duration: string, label: Resource) {
    Column() {
      Text(duration)
        .durationTextStyle()
        .margin({ bottom: 16 })
      Text(label)
        .labelTextStyle()
    }
    .padding({ top: 24, bottom: 24 })
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.labelBackground())
    .animation({ duration: 200, curve: Curve.Ease })
    .layoutWeight(1)
  }

  @Builder
  private colorRow(colors: Array<string>) {
    Row() {
      ForEach(colors, (color: string) => {
        if (color === "") {
          Blank(6)
        } else {
          Stack() {
            Rect()
              .radiusWidth(5)
              .width("100%")
              .height("100%")
              .fill(color)
            if (this.settings.colorTheme === color) {
              Image($r('app.media.check')).fillColor(Color.White)
                .width("80%")
                .height("80%")
                .transition(TransitionEffect.OPACITY.animation({ duration: 200, curve: Curve.Ease }))
            }
          }
          .layoutWeight(1)
          .aspectRatio(1)
          .onClick((event) => {
            this.settings.colorTheme = color
          })
        }
      })
    }
  }

  private labelBackground(): ResourceColor {
    return adjustHexColor(this.settings.colorTheme, 1.2)
  }
}