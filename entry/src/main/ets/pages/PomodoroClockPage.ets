import { PomodoroTimer } from '../components/PomodoroTimer'
import {
  getPhraseTotalMS,
  increaseTodayFinishedPomodoroCount,
  makePlainSettingFrom,
  Setting,
  todayFinishedPomodoroCount
} from '../model/Setting'
import { PersistenceV2 } from '@kit.ArkUI'
import { getDisabledColor } from '../utils/ColorUtils'
import { padNumber, remainingMinutes, remainingSecondsWithoutMinutes } from '../utils/DateTimeUtils'
import { Phrase, TimerState } from '../model/Pomodoro'
import { worker } from '@kit.ArkTS'
import { WorkerEvent } from '../workers/TimerWorker'
import { postCommandToWorker } from '../utils/WorkerUtils'
import { Logger } from '../utils/LogUtil'
import { LiveViewController } from '../utils/LiveViewUtils'


@Builder
export function PomodoroClockPageBuilder() {
  PomodoroClockPage()
}

@ComponentV2
export struct PomodoroClockPage {
  @Local settings: Setting = PersistenceV2.connect(Setting, () => new Setting())!
  @Consumer('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  // @Consumer('timerWorker') timerWorker: worker.ThreadWorker =
  //   new worker.ThreadWorker("entry/ets/workers/TimerWorker.ets")
  @Local finishedPomodoros: number = 0
  @Local phrase: Phrase = Phrase.POMODORO
  @Local autoStart: boolean = false
  @Local timerState: TimerState = { type: "stopped" }
  private timerWorker: worker.ThreadWorker | undefined = undefined

  /**
   * 构建单个进度点
   * @param index - 进度点索引
   */
  @Builder
  private buildProgressDot(index: number) {
    Circle()
      .width(todayFinishedPomodoroCount(this.settings) >= (index + 1) ? 4 : 2)
      .aspectRatio(1)
      .flexShrink(1)
      .fill(todayFinishedPomodoroCount(this.settings) >= (index + 1) ? Color.White : getDisabledColor("#FFFFFF"))
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

  private pomodoroCountOfPhrase() {
    if (this.phrase === Phrase.POMODORO) {
      return this.settings.pomodoro
    } else if (this.phrase === Phrase.SHORT_BREAK) {
      return this.settings.break
    } else {
      return this.settings.longBreak
    }
  }

  private getTimerWorker(): worker.ThreadWorker {
    if (this.timerWorker) {
      return this.timerWorker
    }
    let timerWorker: worker.ThreadWorker = new worker.ThreadWorker("entry/ets/workers/TimerWorker.ets")
    this.timerWorker = timerWorker
    return timerWorker
  }

  @Builder
  buildTimer() {
    PomodoroTimer({
      phrase: this.phrase,
      pomodoroCount: this.pomodoroCountOfPhrase(),
      pomodoroSeconds: this.settings.pomodoroSeconds,
      state: this.timerState,
      onReadyToRun: () => {
        try {
          let timerWorker = this.getTimerWorker()
          timerWorker.onmessage = (event) => {
            let workerEvent = event.data as WorkerEvent
            if (workerEvent.event == "onCancelled") {
              this.timerState = { type: "prestop" }
            } else {
              if (workerEvent.event == "onFinished") {
                if (workerEvent.phrase === Phrase.POMODORO) {
                  let finished = increaseTodayFinishedPomodoroCount(this.settings)
                  if (finished % this.settings.pomodorosUntilLongBreak === 0) {
                    this.phrase = Phrase.LONG_BREAK
                    if (this.settings.autostartBreaks) {
                      postCommandToWorker(timerWorker,
                        { type: "start", phrase: Phrase.LONG_BREAK, setting: makePlainSettingFrom(this.settings) })
                    } else {
                      this.timerState = { type: "stopped" }
                    }
                  } else {
                    this.phrase = Phrase.SHORT_BREAK
                    if (this.settings.autostartBreaks) {
                      postCommandToWorker(timerWorker,
                        { type: "start", phrase: Phrase.SHORT_BREAK, setting: makePlainSettingFrom(this.settings) })
                    } else {
                      this.timerState = { type: "stopped" }
                    }
                  }
                } else {
                  this.phrase = Phrase.POMODORO
                  if (this.settings.autostartPomodoros) {
                    postCommandToWorker(timerWorker,
                      { type: "start", phrase: Phrase.POMODORO, setting: makePlainSettingFrom(this.settings) })
                  } else {
                    this.timerState = { type: "stopped" }
                  }
                }
              } else {
                this.phrase = workerEvent.phrase
                this.timerState = workerEvent.state
                if (this.settings.showLiveView) {
                  if ((workerEvent.event === "onStarted" && this.timerState.type === "running") ||
                    (workerEvent.event === "onRunning" && this.timerState.type === "running")) {
                    if (this.phrase === Phrase.POMODORO) {
                      LiveViewController.startOrUpdateLiveView($r("app.string.setting_pomodoro"),
                        this.timerState.totalTimeMS - this.timerState.elapsedTimeMS, "working.svg", false)
                    } else if (this.phrase === Phrase.SHORT_BREAK) {
                      LiveViewController.startOrUpdateLiveView($r("app.string.setting_break"),
                        this.timerState.totalTimeMS - this.timerState.elapsedTimeMS, "break.svg", false)
                    } else {
                      LiveViewController.startOrUpdateLiveView($r("app.string.setting_long_break"),
                        this.timerState.totalTimeMS - this.timerState.elapsedTimeMS, "break.svg", false)
                    }
                  } else if (workerEvent.event === "onPaused") {
                    LiveViewController.pauseTimer()
                  } else if (workerEvent.event === "onResumed") {
                    LiveViewController.continueTimer()
                  }
                }
              }
            }
          }

          let plain = makePlainSettingFrom(this.settings)
          postCommandToWorker(timerWorker, { type: "start", phrase: this.phrase, setting: plain })
        } catch (error) {
          Logger.error("Error PostMessage:%{public}s", JSON.stringify(error))
        }
      },
      onReadyToStop: () => {
        this.timerState = { type: "stopped" }
      },
      onTap: () => {
        if (this.timerState.type === "stopped") {
          this.timerState =
            { type: "prerun", elapsedTimeMS: 0, totalTimeMS: getPhraseTotalMS(this.settings, this.phrase) }
        } else if (this.timerState.type === "running") {
          this.timerWorker && postCommandToWorker(this.timerWorker, { type: "pause" })
        } else if (this.timerState.type === "paused") {
          this.timerWorker && postCommandToWorker(this.timerWorker, { type: "resume" })
        }
      },
      onLongTap: () => {
        if (this.timerState.type === "running" || this.timerState.type === "paused") {
          this.timerWorker && postCommandToWorker(this.timerWorker, { type: "cancel" })
        }
      }
    }).width('80%')
      .margin({ bottom: 64 })
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
              this.timerWorker && postCommandToWorker(this.timerWorker, { type: "cancel" })
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