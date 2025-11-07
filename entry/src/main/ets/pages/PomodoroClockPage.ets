import { PomodoroTimer } from '../components/PomodoroTimer'
import { Setting } from '../model/Setting'
import { PersistenceV2 } from '@kit.ArkUI'
import { getDisabledColor } from '../utils/ColorUtils'


enum Phrase {
  POMODORO,
  SHORT_BREAK,
  LONG_BREAK
}

@Builder
export function PomodoroClockPageBuilder() {
  PomodoroClockPage()
}

@ComponentV2
export struct PomodoroClockPage {
  @Local settings: Setting = PersistenceV2.globalConnect({ type: Setting, defaultCreator: () => new Setting() })!
  @Consumer('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @Local phrase: Phrase = Phrase.POMODORO
  @Local isClickEnabled: boolean = true

  /**
   * 构建单个进度点
   * @param index - 进度点索引
   */
  @Builder
  private buildProgressDot(index: number) {
    Circle()
      .width(this.settings.todayFinishedPomodoroCount() >= (index + 1) ? 4 : 2)
      .aspectRatio(1)
      .flexShrink(1)
      .fill(this.settings.todayFinishedPomodoroCount() >= (index + 1) ? Color.White : getDisabledColor("#FFFFFF"))
  }

  /**
   * 构建空白占位点
   */
  @Builder
  private buildPlaceholderDot() {
    Circle()
      .width(4)
      .aspectRatio(1)
      .flexShrink(1)
      .fill(Color.Transparent)
  }

  /**
   * 构建进度点行
   * @param slot - 行索引
   */
  @Builder
  private buildProgressRow(slot: number) {
    Row() {
      ForEach(Array.from({ length: 3 }), (_: number, i) => {
        // 计算当前点的索引
        if (slot * 3 + i < this.settings.dailyGoal) {
          // 构建进度点
          this.buildProgressDot(slot * 3 + i)
        } else {
          // 构建占位点
          this.buildPlaceholderDot()
        }
      })
    }
    .width(28)
    .flexShrink(1)
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  /**
   * 构建阶段信息显示行
   * @param phraseText - 阶段文本
   * @param duration - 持续时间
   */
  @Builder
  private buildPhraseInfoRow(phraseText: Resource, duration: number) {
    Row() {
      Image($r("app.media.up_down"))
        .fillColor(Color.White)
        .height(24)
      Text(phraseText)
        .phraseTextStyle()
      Text(`${duration}`)
        .phraseDurationTextStyle()
        .margin({ left: 4 })
      Text($r("app.string.min"))
        .phraseDurationTextStyle()
        .margin({ left: 4 })
    }.justifyContent(FlexAlign.Center)
    .transition(TransitionEffect.OPACITY
      .combine(TransitionEffect.translate({ y: "50%" }))
      .animation({ duration: 200, curve: Curve.Ease }))
    .margin({ top: 64 })
    .onClick(() => {
      if (this.isClickEnabled) {
        if (this.phrase === Phrase.POMODORO) {
          this.phrase = Phrase.SHORT_BREAK
        } else if (this.phrase === Phrase.SHORT_BREAK) {
          this.phrase = Phrase.LONG_BREAK
        } else {
          this.phrase = Phrase.POMODORO
        }
      }
    })
  }

  build() {
    NavDestination() {
      Column() {
        // 设置按钮区域
        Row() {
          Blank()
          Image($r("app.media.list"))
            .width(24)
            .height(24)
            .fillColor(Color.White)
            .visibility(this.isClickEnabled ? Visibility.Visible : Visibility.Hidden)
        }
        .width('100%')
        .onClick(() => {
          if (this.isClickEnabled) {
            this.pageInfos.pushDestination({ name: "Setting" })
          }
        })
        .margin({ bottom: 24 })

        // 番茄钟计时器
        PomodoroTimer({
          pomodoroCount: this.settings.pomodoro,
          pomodoroSeconds: 60,
          autoStart: true,
          onStarted: () => {
            this.isClickEnabled = false
          },
          onCancelled: () => {
            this.isClickEnabled = true
          },
          onFinished: () => {
          },
          onRunning: (elapsed, total) => {
            // 空回调，可根据需要添加处理逻辑
          },
        }).width('80%')
          .margin({ bottom: 64 })

        // 进度显示区域
        Row() {
          ForEach(Array.from({ length: Math.ceil(this.settings.dailyGoal / 3) }), (_: number, slot) => {
            this.buildProgressRow(slot)
          })
        }
        .width("50%")
        .justifyContent(FlexAlign.Center)

        // 阶段信息显示行
        if (this.phrase === Phrase.POMODORO) {
          this.buildPhraseInfoRow($r("app.string.setting_pomodoro"), this.settings.pomodoro)
        } else if (this.phrase === Phrase.SHORT_BREAK) {
          this.buildPhraseInfoRow($r("app.string.setting_break"), this.settings.break)
        } else if (this.phrase === Phrase.LONG_BREAK) {
          this.buildPhraseInfoRow($r("app.string.setting_long_break"), this.settings.longBreak)
        }

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

@Extend(Text)
function phraseTextStyle() {
  .fontColor(Color.White)
  .fontSize(12)
  .textAlign(TextAlign.Center)
}

@Extend(Text)
function phraseDurationTextStyle() {
  .fontColor(getDisabledColor("#FFFFFF", 0xcc))
  .fontSize(12)
  .textAlign(TextAlign.Center)
}
