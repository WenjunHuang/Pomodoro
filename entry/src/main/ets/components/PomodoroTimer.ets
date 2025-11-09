import { AnimatorResult, curves } from '@kit.ArkUI';
import { drawCircleSector, drawTicks } from '../utils/DrawingUtils';
import { PomodoroTicker } from './PomodoroTicker';

export interface Running {
  type: 'running';
  elapsedTimeMS: number;
  totalTimeMS: number;
}

export interface Paused {
  type: 'paused';
  elapsedTimeMS: number;
  totalTimeMS: number;
}

export interface Stopped {
  type: 'stopped';
}

export interface Finished {
  type: 'finished'
}

export interface Transition {
  type: 'transition';
  from: TimerState;
  to: TimerState;
}

export type TimerState = Running | Paused | Stopped | Finished | Transition

@ComponentV2
export struct PomodoroTimer {
  @Require @Param pomodoroCount: number
  @Require @Param pomodoroSeconds: number
  @Event onStateChanged?: (state: TimerState) => void = undefined
  @Event onStarted?: (state: TimerState) => void = undefined
  @Event onPaused?: (state: TimerState) => void = undefined
  @Event onResumed?: (state: TimerState) => void = undefined
  @Event onCancelled?: (state: TimerState) => void = undefined
  @Event onFinished?: (state: TimerState) => void = undefined
  @Event onRunning?: (state: TimerState) => void = undefined
  @Param autoStart: boolean = false
  @Param initState: TimerState = { type: "stopped" }
  @Local isCircleBouncing: boolean = false
  @Local circleScale: number = 1
  @Local state: TimerState = this.initState
  private tickTimer?: number
  private pomodoroContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true))
  private static readonly FPS: number = 90
  private static readonly TICK_MS: number = 1000 / PomodoroTimer.FPS // fps: 90
  private static readonly CIRCLE_STEPS: number = Math.floor(PomodoroTimer.FPS / 2) // 因为每秒90帧，所以45帧等于半秒
  private bouncingAnim: AnimatorResult = this.getUIContext().createAnimator({
    duration: 200,
    easing: "ease-in-out",
    delay: 0,
    fill: "both",
    direction: "alternate",
    iterations: 2,
    begin: 1,
    end: 1.05,
  })

  @Monitor("isCircleBouncing")
  onCircleBouncing() {
    if (this.isCircleBouncing) {
      this.bouncingAnim.cancel()
      this.bouncingAnim.onFrame = (value) => this.circleScale = value
      this.bouncingAnim.play()
      this.isCircleBouncing = false
    }
  }

  private clearTimer() {
    if (this.tickTimer !== undefined) {
      this.tickTimer = undefined
    }
  }

  private schedule(fn: () => void) {
    this.tickTimer = setTimeout(fn, PomodoroTimer.TICK_MS)
  }

  private drawProgress(elapsed: number, total: number) {
    let remaining = total - elapsed
    drawCircleSector(this.pomodoroContext, 0, (remaining / total) * 360, Color.White)
  }

  private startTicking() {
    const tick = () => {
      if (this.state.type !== 'running') {
        this.clearTimer()
        return
      }
      if (this.state.elapsedTimeMS >= this.state.totalTimeMS) {
        this.state = { type: 'finished' }
        this.clearTimer()
        return
      }
      this.state.elapsedTimeMS += PomodoroTimer.TICK_MS
      this.onStateChanged && this.onStateChanged({
        type: "running",
        elapsedTimeMS: this.state.elapsedTimeMS,
        totalTimeMS: this.state.totalTimeMS
      })
      this.onRunning && this.onRunning({
        type: "running",
        elapsedTimeMS: this.state.elapsedTimeMS,
        totalTimeMS: this.state.totalTimeMS
      })
      this.drawProgress(this.state.elapsedTimeMS, this.state.totalTimeMS)
      this.schedule(tick)
    }
    this.schedule(tick)
  }

  private scheduleCycleAnimation(from: number, to: number, total: number, callback?: () => void) {
    let current = from;
    let isReverse = from > to;
    const delta = total / PomodoroTimer.CIRCLE_STEPS
    const tick = () => {
      if (isReverse) {
        if (current > to) {
          current = Math.max(to, current - delta)
          this.drawProgress(current, total)
          this.schedule(tick)
        } else {
          callback && callback()
        }
      } else {
        if (current < to) {
          current = Math.min(to, current + delta)
          this.drawProgress(current, total)
          this.schedule(tick)
        } else {
          callback && callback()
        }
      }
    }
    this.schedule(tick)
  }

  @Monitor("initState")
  onInitStateChanged() {
    if (this.initState.type === "stopped" || this.initState.type === "transition") {
      this.state = this.initState
    }
  }

  @Monitor('state')
  onStatusChanged(monitor: IMonitor) {
    let before = monitor.value<TimerState>('state')!.before
    let after = monitor.value<TimerState>('state')!.now

    this.clearTimer()

    // 启动bouncing动画
    if (before.type === 'transition' &&
      (after.type === 'running' || after.type === 'stopped' || after.type === 'finished')) {
      this.isCircleBouncing = true
    } else {
      this.isCircleBouncing = false
    }

    if (after.type === 'running') {
      this.startTicking()
    } else if (after.type === 'transition') {
      const from = after.from
      const to = after.to
      if ((from.type === 'running' || from.type === 'paused') && to.type === 'stopped') {
        // 从运行或暂停状态到停止状态，先运行扇形动画
        this.scheduleCycleAnimation(from.elapsedTimeMS, from.totalTimeMS, from.totalTimeMS, () => {
          this.state = to
        })
      } else if (from.type === 'stopped' && to.type === 'running') {
        // 启动时钟前，先显示扇形动画
        this.scheduleCycleAnimation(to.totalTimeMS, 0, to.totalTimeMS, () => {
          this.state = to
        })
      } else {
        // 由外部设置的状态变更，直接应用目标状态
        this.state = to
      }
    }

    if (after.type !== 'transition') {
      this.onStateChanged && this.onStateChanged(after)
    }

    //调用事件通知
    if (before.type === "transition" && before.from.type === "stopped" && after.type === "running") {
      this.onStarted && this.onStarted(after)
    } else if (before.type === "running" && after.type === "paused") {
      this.onPaused && this.onPaused(after)
    } else if (before.type === "paused" && after.type === "running") {
      this.onResumed && this.onResumed(after)
    } else if (before.type === "running" && after.type === "finished") {
      this.onFinished && this.onFinished(after)
    } else if (before.type === "transition" && (before.from.type === "running" || before.from.type === "paused") &&
      after.type === "stopped") {
      this.onCancelled && this.onCancelled(after)
    }
  }

  @Builder
  buildRunning() {
    if (this.state.type !== 'stopped' && this.state.type !== 'finished') {
      Canvas(this.pomodoroContext)
        .width('100%')
        .height('100%')
        .opacity(this.state.type !== 'paused' ? 1.0 : 0.5)
        .animation({ curve: Curve.Ease })
    }
  }

  aboutToAppear(): void {
    if (this.autoStart) {
      this.state = {
        type: 'running',
        elapsedTimeMS: 0, totalTimeMS: this.pomodoroCount * this.pomodoroSeconds * 1000
      }
      this.onStateChanged && this.onStateChanged(this.state)
      this.onStarted && this.onStarted(this.state)
    }
  }

  build() {
    Stack() {
      Column() {
        this.buildRunning()
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding(20)
      .borderWidth(8)
      .borderRadius('50%')
      .borderColor(Color.Transparent)
      .width('100%')
      .height('100%')

      if (this.state.type === 'paused') {
        Image($r('app.media.pause'))
          .width('30%')
          .height('30%')
          .fillColor(Color.White)
      } else if (this.state.type === 'stopped') {
        Image($r('app.media.play'))
          .width('30%')
          .height('30%')
          .fillColor(Color.White)
      }

      // 必须这样写否则触发不了更新
      if (this.isCircleBouncing) {
        this.buildCycleBorder()
      } else {
        this.buildCycleBorder()
      }
    }
    .aspectRatio(1) // 强制宽高比1:1
  }

  @Builder
  buildCycleBorder() {
    Stack() {
      PomodoroTicker({
        tickLength: PomodoroTicker.MAX_TICK_LENGTH,
        ticksCount: this.pomodoroCount,
        tickAnim: !this.isCircleBouncing && (this.state.type === 'stopped' || this.state.type === 'finished')
      })

      Column() {
        Column()
          .width('100%')
          .height('100%')
          .borderColor(Color.White)
          .borderWidth(8)
          .borderRadius('50%');
      }
      .padding(12)
      .width('100%')
      .height('100%');
    }
    .width('100%')
    .height('100%')
    .scale({ x: this.circleScale, y: this.circleScale })
    // .transition(this.isCircleBouncing ?
    //   TransitionEffect.scale({ x: 1.0, y: 1.0 })
    //     .animation({ duration: 10000, delay: 200, curve: Curve.EaseInOut }) : TransitionEffect.IDENTITY)
    .gesture(
      LongPressGesture()
        .onAction(() => {
          if (this.state.type !== 'transition') {
            if (this.state.type === 'running' || this.state.type === 'paused') {
              this.state = { type: 'transition', from: this.state, to: { type: 'stopped' } };
            }
          }
        })
    )
    .gesture(TapGesture()
      .onAction(() => {
        if (this.state.type === 'stopped') {
          this.state = {
            type: 'transition',
            from: this.state,
            to: {
              type: 'running',
              elapsedTimeMS: 0, totalTimeMS: this.pomodoroCount * this.pomodoroSeconds * 1000
            }
          };
        } else if (this.state.type === 'running') {
          this.state = { type: 'paused', elapsedTimeMS: this.state.elapsedTimeMS, totalTimeMS: this.state.totalTimeMS };
        } else if (this.state.type === 'paused') {
          this.state =
            { type: 'running', elapsedTimeMS: this.state.elapsedTimeMS, totalTimeMS: this.state.totalTimeMS };
        }
      })
    )
  }
}