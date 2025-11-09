import { PomodoroTimer, TimerState } from '../components/PomodoroTimer'
import { Setting } from '../model/Setting'
import { PersistenceV2 } from '@kit.ArkUI'
import { getDisabledColor } from '../utils/ColorUtils'
import { padNumber, remainingMinutes, remainingSecondsWithoutMinutes } from '../utils/DateTimeUtils'
import { playFinishedSound } from '../utils/SoundUtils'
import { DAILY_GOAL_PAGE } from './Pages'
import { LiveViewController } from '../utils/LiveViewUtils'
import { common } from '@kit.AbilityKit'

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
  @Local settings: Setting = PersistenceV2.connect(Setting, () => new Setting())!
  @Consumer('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @Local finishedPomodoros: number = 0
  @Local phrase: Phrase = Phrase.POMODORO
  @Local autoStart: boolean = false
  @Local timerState: TimerState = { type: "stopped" }
  private liveViewController = new LiveViewController(this.getUIContext().getHostContext()! as common.UIAbilityContext)

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

  @Builder
  private buildPhraseRunning(phraseText: ResourceStr) {
    Column() {
      Text(phraseText)
        .phraseTextStyle()
        .margin({ bottom: 8 })
      if (this.timerState.type === "running" || this.timerState.type === 'paused') {
        Text(`${remainingMinutes(this.timerState.elapsedTimeMS,
          this.timerState.totalTimeMS)}:${padNumber(remainingSecondsWithoutMinutes(this.timerState.elapsedTimeMS,
          this.timerState.totalTimeMS), 2)}`)
          .phraseTextStyle()
      }
    }
    .margin({ top: 64 })
  }

  /**
   * 构建阶段信息显示行
   * @param phraseText - 阶段文本
   * @param duration - 持续时间
   */
  @Builder
  private buildPhraseInfoRow(param: PhraseInfoTextParam) {
    Row() {
      Image($r("app.media.up_down"))
        .fillColor(Color.White)
        .height(24)
      Text(param.phraseText)
        .phraseTextStyle()
      Text(`${param.duration}`)
        .phraseDurationTextStyle()
        .margin({ left: 4 })
      Text($r("app.string.min"))
        .phraseDurationTextStyle()
        .margin({ left: 4 })
    }.justifyContent(FlexAlign.Center)
    .transition(
      TransitionEffect.OPACITY.combine(
        TransitionEffect.asymmetric(TransitionEffect.translate({ y: "-100%" }),
          TransitionEffect.translate({ y: "100%" }))).animation({ duration: 200, curve: Curve.EaseInOut }))
    .margin({ top: 64 })
    .onClick(() => {
      if (this.phrase === Phrase.POMODORO) {
        this.phrase = Phrase.SHORT_BREAK
        this.autoStart = false
      } else if (this.phrase === Phrase.SHORT_BREAK) {
        this.phrase = Phrase.LONG_BREAK
        this.autoStart = false
      } else {
        this.phrase = Phrase.POMODORO
        this.autoStart = false
      }
    })
  }

  @Builder
  buildTimer() {
    if (this.phrase === Phrase.POMODORO) {
      PomodoroTimer({
        pomodoroCount: this.settings.pomodoro,
        pomodoroSeconds: this.settings.pomodoroSeconds,
        initState: this.timerState,
        autoStart: this.autoStart,
        onStarted: async (event) => {
          if (event.type === "running") {
            if (this.settings.showLiveView) {
              await this.liveViewController.startLiveView($r("app.string.setting_pomodoro"),
                event.totalTimeMS - event.elapsedTimeMS, "working.svg", false)
            }
          }
        },
        onRunning: async (event) => {
          if (event.type === "running") {
            if (this.settings.showLiveView) {
              await this.liveViewController.updateTimer($r("app.string.setting_pomodoro"),
                event.totalTimeMS - event.elapsedTimeMS, false)
            }
          }
        },
        onPaused: async (event) => {
          await this.liveViewController.pauseTimer()
        },
        onResumed: async (event) => {
          await this.liveViewController.continueTimer()
        },
        onCancelled: async (event) => {
          await this.liveViewController.stopLiveView()
        },
        onStateChanged: async (state) => {
          this.timerState = state
          if (state.type === 'finished') {
            playFinishedSound(this.getUIContext().getHostContext()!!)
            await this.liveViewController.stopLiveView()

            let finished = this.settings.increaseTodayFinishedPomodoroCount()
            this.finishedPomodoros = finished

            if (finished >= this.settings.dailyGoal) {
              this.timerState = { type: "stopped" }
              this.pageInfos.pushPathByName(DAILY_GOAL_PAGE, null)
            } else {
              this.timerState = { type: "stopped" }
              if (this.finishedPomodoros % this.settings.pomodorosUntilLongBreak == 0) {
                // 开始长休
                this.phrase = Phrase.LONG_BREAK
                if (this.settings.autostartBreaks) {
                  this.autoStart = true
                } else {
                  this.autoStart = false
                }
              } else if (this.finishedPomodoros % this.settings.break == 0) {
                //开始短休
                this.phrase = Phrase.SHORT_BREAK
                if (this.settings.autostartBreaks) {
                  this.autoStart = true
                } else {
                  this.autoStart = false
                }
              } else {
                this.phrase = Phrase.POMODORO
                if (this.settings.autostartPomodoros) {
                  this.autoStart = true
                } else {
                  this.autoStart = false
                }
              }
            }
          }
        },
      })
        .width('80%')
        .margin({ bottom: 64 })
    } else if (this.phrase === Phrase.SHORT_BREAK) {
      PomodoroTimer({
        pomodoroCount: this.settings.break,
        pomodoroSeconds: this.settings.pomodoroSeconds,
        autoStart: this.autoStart,
        initState: this.timerState,
        onStarted: async (event) => {
          if (event.type === "running") {
            if (this.settings.showLiveView) {
              await this.liveViewController.startLiveView($r("app.string.setting_break"),
                event.totalTimeMS - event.elapsedTimeMS, "break.svg", false)
            }
          }
        },
        onRunning: async (event) => {
          if (event.type === "running") {
            if (this.settings.showLiveView) {
              await this.liveViewController.updateTimer($r("app.string.setting_break"),
                event.totalTimeMS - event.elapsedTimeMS, false)
            }
          }
        },
        onPaused: async (event) => {
          await this.liveViewController.pauseTimer()
        },
        onResumed: async (event) => {
          await this.liveViewController.continueTimer()
        },
        onCancelled: async (event) => {
          await this.liveViewController.stopLiveView()
        },
        onStateChanged: async (state) => {
          this.timerState = state
          if (state.type === 'finished') {
            playFinishedSound(this.getUIContext().getHostContext()!!)
            await this.liveViewController.stopLiveView()

            this.phrase = Phrase.POMODORO
            this.timerState = { type: "stopped" }
            if (this.settings.autostartPomodoros) {
              this.autoStart = true
            } else {
              this.autoStart = false
            }
          }
        },
      }).width('80%')
        .margin({ bottom: 64 })
    } else {
      PomodoroTimer({
        pomodoroCount: this.settings.longBreak,
        pomodoroSeconds: this.settings.pomodoroSeconds,
        autoStart: this.autoStart,
        initState: this.timerState,
        onStarted: async (event) => {
          if (event.type === "running") {
            if (this.settings.showLiveView) {
              await this.liveViewController.startLiveView($r("app.string.setting_long_break"),
                event.totalTimeMS - event.elapsedTimeMS, "break.svg", false)
            }
          }
        },
        onRunning: async (event) => {
          if (event.type === "running") {
            if (this.settings.showLiveView) {
              await this.liveViewController.updateTimer($r("app.string.setting_long_break"),
                event.totalTimeMS - event.elapsedTimeMS, false)
            }
          }
        },
        onPaused: async (event) => {
          await this.liveViewController.pauseTimer()
        },
        onResumed: async (event) => {
          await this.liveViewController.continueTimer()
        },
        onCancelled: async (event) => {
          await this.liveViewController.stopLiveView()
        },
        onStateChanged: async (state) => {
          this.timerState = state
          if (state.type === 'finished') {
            playFinishedSound(this.getUIContext().getHostContext()!!)
            await this.liveViewController.stopLiveView()

            this.phrase = Phrase.POMODORO
            this.timerState = { type: "stopped" }
            if (this.settings.autostartPomodoros) {
              this.autoStart = true
            } else {
              this.autoStart = false
            }
          }
        },
      }).width('80%')
        .margin({ bottom: 64 })
    }
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
            .visibility(this.timerState.type === 'stopped' ? Visibility.Visible : Visibility.Hidden)
        }
        .width('100%')
        .enabled(this.timerState.type === 'stopped')
        .onClick(() => {
          this.pageInfos.pushDestination({ name: "Setting" }).catch(() => {
          })
        })
        .margin({ bottom: 24 })

        // 番茄钟计时器
        this.buildTimer()

        // 进度显示区域
        Row() {
          ForEach(Array.from({ length: Math.ceil(this.settings.dailyGoal / 3) }), (_: number, slot) => {
            this.buildProgressRow(slot)
          })
        }
        .width("50%")
        .justifyContent(FlexAlign.Center)

        // 阶段信息显示行
        if (this.timerState.type === 'stopped' || this.timerState.type === 'finished') {
          if (this.phrase === Phrase.POMODORO) {
            this.buildPhraseInfoRow({ phraseText: $r("app.string.setting_pomodoro"), duration: this.settings.pomodoro })
          } else if (this.phrase === Phrase.SHORT_BREAK) {
            this.buildPhraseInfoRow({ phraseText: $r("app.string.setting_break"), duration: this.settings.break })
          } else if (this.phrase === Phrase.LONG_BREAK) {
            this.buildPhraseInfoRow({
              phraseText: $r("app.string.setting_long_break"),
              duration: this.settings.longBreak
            })
          }
        } else if (this.timerState.type === 'running' || this.timerState.type === 'paused') {
          if (this.phrase === Phrase.POMODORO) {
            this.buildPhraseRunning($r("app.string.setting_pomodoro"))
          } else if (this.phrase === Phrase.SHORT_BREAK) {
            this.buildPhraseRunning($r("app.string.setting_break"))
          } else if (this.phrase === Phrase.LONG_BREAK) {
            this.buildPhraseRunning($r("app.string.setting_long_break"))
          }
        }

        Blank()
        if (this.timerState.type === 'paused') {
          Text($r("app.string.reset"))
            .phraseTextStyle()
            .onClick(() => {
              this.timerState = { type: "transition", from: this.timerState, to: { type: "stopped" } }
            })
        }
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

class PhraseInfoTextParam {
  phraseText: ResourceStr = ""
  duration: number = 0
}