import { ComponentContent, PersistenceV2, promptAction } from '@kit.ArkUI';
import { Setting } from '../model/Setting';
import { ThemeColors } from '../model/ThemeColors';
import { adjustHexColor, getDisabledColor, getMaskColor } from '../utils/ColorUtils';
import { vibrator } from '@kit.SensorServiceKit';

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

class NumCardParam {
  duration: string = ""
  label: ResourceStr = ""
  onClick?: () => void
}

@ComponentV2
export struct SettingPage {
  @Local settings: Setting = PersistenceV2.connect( Setting,() => new Setting())!
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
          Row() {
            Image($r("app.media.angle_left"))
              .fillColor(Color.White)
              .width(24)
              .height(24)
              .onClick(() => this.pageInfos.pop())
          }
          .justifyContent(FlexAlign.Start)
          .width('100%')

          Text($r("app.string.setting_durations"))
            .labelTextStyle()
            .margin({ bottom: 24, top: 8 })
          Row() {
            this.numberCard({
              duration: `${this.settings.pomodoro}`,
              label: $r("app.string.setting_pomodoro"),
              onClick: async () => {
                await this.showNumberDialog(
                  this.settings.pomodoro,
                  $r("app.string.setting_pomodoro"),
                  (v: number) => (this.settings.pomodoro = v)
                )
              }
            })
            Blank(8)
            this.numberCard({
              duration: `${this.settings.break}`, label: $r("app.string.setting_break"), onClick: async () => {
                await this.showNumberDialog(
                  this.settings.break,
                  $r("app.string.setting_break"),
                  (v: number) => (this.settings.break = v)
                )
              }
            })
            Blank(8)
            this.numberCard({
              duration: `${this.settings.longBreak}`, label: $r("app.string.setting_long_break"), onClick: async () => {
                await this.showNumberDialog(
                  this.settings.longBreak,
                  $r("app.string.setting_long_break"),
                  (v: number) => (this.settings.longBreak = v)
                )
              }
            })
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
            this.numberCard({
              duration: `${this.settings.pomodorosUntilLongBreak}`,
              label: $r("app.string.setting_pomodoros_until_long_break"),
              onClick: async () => {
                await this.showNumberDialog(
                  this.settings.pomodorosUntilLongBreak,
                  $r("app.string.setting_pomodoros_until_long_break"),
                  (v: number) => (this.settings.pomodorosUntilLongBreak = v)
                )
              }
            })
            Blank(8)
            this.numberCard({
              duration: `${this.settings.dailyGoal}`, label: $r("app.string.setting_daily_goal"), onClick: async () => {
                await this.showNumberDialog(
                  this.settings.dailyGoal,
                  $r("app.string.setting_daily_goal"),
                  (v: number) => (this.settings.dailyGoal = v)
                )
              }
            })
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
          .onClick(async () => {
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
          .onClick(() => {
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
  private numberCard(param: NumCardParam) {
    Column() {
      Text(param.duration)
        .durationTextStyle()
        .margin({ bottom: 16 })
      Text(param.label)
        .labelTextStyle()
    }
    .padding({ top: 16, bottom: 16 })
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.labelBackground())
    .animation({ duration: 200, curve: Curve.Ease })
    .layoutWeight(1)
    .onClick(() => {
      param.onClick && param.onClick()
    })
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
          .onClick(() => {
            this.settings.colorTheme = color
          })
        }
      })
    }
  }

  private labelBackground(): ResourceColor {
    return adjustHexColor(this.settings.colorTheme, 1.2)
  }

  private async showNumberDialog(initial: number, label: ResourceStr, onChange: (value: number) => void) {
    await PromptActionClass.openDialog(
      this.getUIContext(),
      new ComponentContent(this.getUIContext(), wrapBuilder(numberSetting), new NumberSettingParam(initial, label)),
      (result) => {
        if (result) {
          onChange(result as number)
        }
      }
    )
  }
}

class NumberSettingParam {
  count: number
  label: ResourceStr

  constructor(count: number, label: ResourceStr) {
    this.count = count
    this.label = label
  }

  setCount(count: number): NumberSettingParam {
    return new NumberSettingParam(count, this.label)
  }
}

@Builder
function numberSetting(param: NumberSettingParam) {
  Column() {
    Text(param.label)
      .labelTextStyle()
      .margin({ bottom: 24 })
    Row() {
      Image($r("app.media.minus"))
        .fillColor(Color.White)
        .width(48)
        .height(48)
        .margin({ right: 24 })
        .onClick((e) => {
          if (param.count > 1) {
            PromptActionClass.updateDialog(param.setCount(param.count - 1))
          }
        })
      Text(`${param.count}`)
        .fontColor(Color.White)
        .fontSize(64)
        .fontWeight(FontWeight.Bold)
      Image($r("app.media.plus"))
        .fillColor(Color.White)
        .width(48)
        .height(48)
        .margin({ left: 24 })
        .onClick(() => {
          PromptActionClass.updateDialog(param.setCount(param.count + 1))
        })
    }
    .justifyContent(FlexAlign.Center)

    Image($r("app.media.check"))
      .fillColor(Color.White)
      .width(48)
      .height(48)
      .onClick(() => {
        PromptActionClass.closeDialog(param.count)
      })
  }.justifyContent(FlexAlign.Center)
}

class PromptActionClass {
  static ctx?: UIContext;
  static contentNode?: ComponentContent<Object>;
  static options?: promptAction.BaseDialogOptions;
  static onResult?: (v: Object | undefined) => void

  static updateDialog(value: Object) {
    PromptActionClass.contentNode?.update(value)
  }

  static async openDialog(ctx: UIContext, contentNode: ComponentContent<Object>,
    onResult?: (v: Object | undefined) => void, options?: promptAction.BaseDialogOptions) {
    PromptActionClass.ctx = ctx
    PromptActionClass.contentNode = contentNode
    PromptActionClass.onResult = onResult
    let opts = options ?? {}
    opts.autoCancel = false
    opts.maskColor = getMaskColor(0x66)
    await ctx.getPromptAction().openCustomDialog(contentNode, opts)
  }

  static async closeDialog(result?: Object) {
    if (PromptActionClass.ctx && PromptActionClass.contentNode) {
      await PromptActionClass.ctx.getPromptAction().closeCustomDialog(PromptActionClass.contentNode)
      PromptActionClass.onResult && PromptActionClass.onResult(result)
    }
  }
}