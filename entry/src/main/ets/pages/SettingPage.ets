import { PersistenceV2 } from '@kit.ArkUI'
import { Setting, SoundTheme } from '../model/Setting'
import { ThemeColors } from '../model/ThemeColors'
import { adjustHexColor, getDisabledColor } from '../utils/ColorUtils'
import { media } from '@kit.MediaKit';
import { audio, audioHaptic } from '@kit.AudioKit';
import { notificationManager } from '@kit.NotificationKit';
import { ringtone } from '@kit.RingtoneKit';
import resourceManager from '@ohos.resourceManager';
import { vibrator, Vibrator, VibrateOptions } from '@kit.SensorServiceKit';
import hilog from '@ohos.hilog';

// import { systemSoundManager } from '@kit.AudioKit';
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

class SwitchCardParam {
  label: ResourceStr = ""
  isSwitchOnSelected: boolean = true
  isSwitchOffSelected: boolean = true
  onSwitchOn?: () => void
  onSwitchOff?: () => void
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
            this.numberCard("14", $r("app.string.setting_pomodoro"))
            Blank(8)
            this.numberCard("1", $r("app.string.setting_break"))
            Blank(8)
            this.numberCard("1", $r("app.string.setting_long_break"))
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

          Text($r("app.string.setting_other_preferences"))
            .labelTextStyle()
            .margin({ bottom: 24, top: 24 })
          Row() {
            this.numberCard("4", $r("app.string.setting_pomodoros_until_long_break"))
            Blank(8)
            this.numberCard("6", $r("app.string.setting_daily_goal"))
          }.width("100%")

          Blank(12)
          this.switchCard({
            label: $r("app.string.setting_vibrate"),
            isSwitchOnSelected: this.settings.vibrate,
            isSwitchOffSelected: !this.settings.vibrate,
            onSwitchOn: async () => {
              this.settings.vibrate = true
              try {
                await vibrator.startVibration({ type: "time", duration: 2000 }, { usage: "notification" })
              } catch (e) {
                console.error(JSON.stringify(e))
              }
            },
            onSwitchOff: () => {
              this.settings.vibrate = false
            }
          })
          Blank(12)
          this.switchCard({
            label: $r("app.string.setting_autostart_breaks"),
            isSwitchOnSelected: this.settings.autostartBreaks,
            isSwitchOffSelected: !this.settings.autostartBreaks,
            onSwitchOn: () => {
              this.settings.autostartBreaks = true
            },
            onSwitchOff: () => {
              this.settings.autostartBreaks = false
            }
          })
          Blank(12)
          this.switchCard({
            label: $r("app.string.setting_autostart_pomodoros"),
            isSwitchOnSelected: this.settings.autostartPomodoros,
            isSwitchOffSelected: !this.settings.autostartPomodoros,
            onSwitchOn: () => {
              this.settings.autostartPomodoros = true
            },
            onSwitchOff: () => {
              this.settings.autostartPomodoros = false
            }
          })
          Blank(12)
          this.switchCard({
            label: $r("app.string.setting_show_notification"),
            isSwitchOnSelected: this.settings.showNotification,
            isSwitchOffSelected: !this.settings.showNotification,
            onSwitchOn: () => {
              this.settings.showNotification = true
            },
            onSwitchOff: () => {
              this.settings.showNotification = false
            }
          })
          Blank(12)
          this.switchCard({
            label: $r("app.string.setting_keep_phone_awake"),
            isSwitchOnSelected: this.settings.keepPhoneAwake,
            isSwitchOffSelected: !this.settings.keepPhoneAwake,
            onSwitchOn: () => {
              this.settings.keepPhoneAwake = true
            },
            onSwitchOff: () => {
              this.settings.keepPhoneAwake = false
            }
          })

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
  private switchCard(param: SwitchCardParam) {
    Column() {
      Row() {
        Image($r("app.media.check"))
          .width(48)
          .height(48)
          .aspectRatio(1)
          .fillColor(param.isSwitchOnSelected ? Color.White : getDisabledColor("#FFFFFF"))
          .enabled(!param.isSwitchOnSelected)
          .onClick(async (event) => {
            param.onSwitchOn && param.onSwitchOn()
          })
          .animation({ duration: 100, curve: Curve.Ease })
          .margin({ right: 16 })
        Image($r("app.media.cross"))
          .width(48)
          .height(48)
          .aspectRatio(1)
          .fillColor(param.isSwitchOffSelected ? Color.White : getDisabledColor("#FFFFFF"))
          .enabled(!param.isSwitchOffSelected)
          .onClick((event) => {
            param.onSwitchOff && param.onSwitchOff()
          })
          .animation({ duration: 100, curve: Curve.Ease })
      }
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 8 })

      Text(param.label)
        .labelTextStyle()
    }
    .padding({ top: 16, bottom: 16 })
    .backgroundColor(this.labelBackground())
    .animation({ duration: 200, curve: Curve.Ease })
    .width("100%")
  }

  @Builder
  private numberCard(duration: string, label: Resource) {
    Column() {
      Text(duration)
        .durationTextStyle()
        .margin({ bottom: 16 })
      Text(label)
        .labelTextStyle()
    }
    .padding({ top: 16, bottom: 16 })
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
                .width(48)
                .height(48)
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