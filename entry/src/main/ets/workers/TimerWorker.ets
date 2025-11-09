import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS';
import { TICK_MS, TimerState, Phrase } from '../model/Pomodoro';
import { Setting } from '../model/Setting';
import { Logger } from '../utils/LogUtil';

const workerPort: ThreadWorkerGlobalScope = worker.workerPort;

let timerState: TimerState = { type: "stopped" }
let tickTimer: number | undefined = undefined
let setting: Setting | undefined = undefined
let phrase: Phrase | undefined = undefined

type WorkerEventType = "onStarted" | "onRunning" | "onCancelled" | "onFinished" | "onPaused" | "onResumed"

export interface StartCommand {
  type: "start"
  phrase: Phrase,
  setting: Setting,
}

export interface CancelCommand {
  type: 'cancel'
}

export interface PauseCommand {
  type: 'pause'
}

export interface ResumeCommand {
  type: 'resume'
}

export type WorkerCommand = StartCommand | CancelCommand | PauseCommand | ResumeCommand

export interface WorkerEvent {
  event: WorkerEventType
  phrase: Phrase,
  state: TimerState
}

function clearTimer() {
  if (tickTimer !== undefined) {
    tickTimer = undefined
  }
}

function schedule(fn: () => void) {
  tickTimer = setTimeout(fn, TICK_MS)
}

function startTicking() {
  const tick = () => {
    if (timerState.type !== 'running') {
      clearTimer()
      return
    }
    if (timerState.elapsedTimeMS >= timerState.totalTimeMS) {
      timerState = { type: 'finished' }
      clearTimer()

      let event: WorkerEvent = { event: "onFinished", phrase: phrase!, state: timerState }
      postEvent(event)
    } else {
      timerState.elapsedTimeMS += TICK_MS

      let event: WorkerEvent = { event: "onRunning", phrase: phrase!, state: timerState }
      postEvent(event)
      schedule(tick)
    }
  }
  schedule(tick)
}

function postEvent(event: WorkerEvent) {
  try {
    workerPort.postMessage(event)
  } catch (e) {
    let be = e as BusinessError<Object>
    Logger.error("Worker PostEvent:%{Public}d, %{Public}s", be.code, be.message)
  }

}



/**
 * Defines the event handler to be called when the worker thread receives a message sent by the host thread.
 * The event handler is executed in the worker thread.
 *
 * @param event message data
 */
workerPort.onmessage = (event: MessageEvents) => {
  let command = event.data as WorkerCommand
  if (command.type === "start") {
    phrase = command.phrase
    setting = command.setting

    let totalTimeMS = 0
    switch (phrase) {
      case Phrase.POMODORO:
        totalTimeMS = setting.pomodoroSeconds * setting.pomodoro * 1000
        break;
      case Phrase.SHORT_BREAK:
        totalTimeMS = setting.pomodoroSeconds * setting.break * 1000
        break
      case Phrase.LONG_BREAK:
        totalTimeMS = setting.pomodoroSeconds * setting.longBreak * 1000
    }

    timerState = { type: "running", elapsedTimeMS: 0, totalTimeMS: totalTimeMS }
    let event: WorkerEvent = {
      event: "onStarted",
      phrase: phrase,
      state: timerState
    }
    postEvent(event)
    startTicking()
  } else if (command.type === "pause") {
    if (timerState.type === "running") {
      timerState = { type: "paused", elapsedTimeMS: timerState.elapsedTimeMS, totalTimeMS: timerState.totalTimeMS }
      let event: WorkerEvent = {
        event: "onPaused",
        state: timerState,
        phrase: phrase!
      }
      postEvent(event)
    }
  } else if (command.type === "resume") {
    if (timerState.type === "paused") {
      timerState = { type: "running", elapsedTimeMS: timerState.elapsedTimeMS, totalTimeMS: timerState.totalTimeMS }
      postEvent({ event: "onResumed", phrase: phrase!, state: timerState })
      startTicking()
    }
  } else if (command.type = "cancel") {
    if (timerState.type === "running" || timerState.type === "paused") {
      timerState = { type: "stopped" }
      postEvent({ event: "onCancelled", phrase: phrase!, state: timerState })
    }
  }
};

/**
 * Defines the event handler to be called when the worker receives a message that cannot be deserialized.
 * The event handler is executed in the worker thread.
 *
 * @param event message data
 */
workerPort.onmessageerror = (event: MessageEvents) => {
};

/**
 * Defines the event handler to be called when an exception occurs during worker execution.
 * The event handler is executed in the worker thread.
 *
 * @param event error message
 */
workerPort.onerror = (event: ErrorEvent) => {
};
// onStateChanged: async (state) => {
//   this.timerState = state
//   if (state.type === 'finished') {
//     playFinishedSound(this.getUIContext().getHostContext()!!)
//     LiveViewController.resetLastUpdatedTime()
//
//     let finished = this.settings.increaseTodayFinishedPomodoroCount()
//     this.finishedPomodoros = finished
//
//     if (finished >= this.settings.dailyGoal) {
//       this.timerState = { type: "stopped" }
//       this.pageInfos.pushPathByName(DAILY_GOAL_PAGE, null)
//     } else {
//       this.timerState = { type: "stopped" }
//       if (this.finishedPomodoros % this.settings.pomodorosUntilLongBreak == 0) {
//         // 开始长休
//         this.phrase = Phrase.LONG_BREAK
//         if (this.settings.autostartBreaks) {
//           this.autoStart = true
//         } else {
//           this.autoStart = false
//         }
//       } else if (this.finishedPomodoros % this.settings.break == 0) {
//         //开始短休
//         this.phrase = Phrase.SHORT_BREAK
//         if (this.settings.autostartBreaks) {
//           this.autoStart = true
//         } else {
//           this.autoStart = false
//         }
//       } else {
//         this.phrase = Phrase.POMODORO
//         if (this.settings.autostartPomodoros) {
//           this.autoStart = true
//         } else {
//           this.autoStart = false
//         }
//       }
//     }
//   }
// },