import { curves } from '@kit.ArkUI';
import { drawCircleSector, drawTicks } from '../utils/DrawingUtils';

interface Running {
  type: 'running';
  elapsedTimeMS: number;
  totalTimeMS: number;
}

interface Paused {
  type: 'paused';
  elapsedTimeMS: number;
  totalTimeMS: number;
}

interface Stopped {
  type: 'stopped';
}

interface Finished {
  type: 'finished'
}

interface Transition {
  type: 'transition';
  from: PomodoroState;
  to: PomodoroState;
}

type PomodoroState = Running | Paused | Stopped | Finished | Transition

@ObservedV2
class BouncingBorderModifier implements AttributeModifier<CommonAttribute> {
  @Trace isBouncing: boolean = false

  constructor(isBouncing?: boolean) {
    this.isBouncing = isBouncing ?? false
  }

  applyNormalAttribute(instance: CommonAttribute): void {
    if (this.isBouncing) {
      instance.transition(TransitionEffect.asymmetric(TransitionEffect.scale({ x: 1.05, y: 1.05 })
        .animation({ curve: curves.springMotion(0.6, 1.2), delay: 100 }), TransitionEffect.IDENTITY))
    } else {
    }
  }
}

@ComponentV2
export struct PomodoroTimer {
  @Param onFinished?: () => void = undefined
  @Param onPaused?: (elapsedTimeMS: number) => void = undefined
  @Param onCancelled?: () => void = undefined
  @Param onStarted?: () => void = undefined
  @Param onRunning?: (elapsedTimeMS: number, totalTimeMS: number) => void = undefined
  @Param onResume?: () => void = undefined
  @Param autoStart: boolean = false
  @Param @Require pomodoroCount: number
  @Param @Require pomodoroSeconds: number
  @Local isCircleBouncing: boolean = false
  @Local state: PomodoroState = { type: 'stopped' }
  private pomodoroContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true))
  private tickContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true))
  private tickTimer?: number
  private static readonly FPS: number = 90
  private static readonly TICK_MS: number = 1000 / PomodoroTimer.FPS // fps: 90
  private static readonly CIRCLE_STEPS: number = Math.floor(PomodoroTimer.FPS / 2) // 因为每秒90帧，所以45帧等于半秒

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
      this.drawProgress(this.state.elapsedTimeMS, this.state.totalTimeMS)
      this.onRunning && this.onRunning(this.state.elapsedTimeMS, this.state.totalTimeMS)
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

  @Monitor('state')
  onStatusChanged(monitor: IMonitor) {
    let before = monitor.value<PomodoroState>('state')!.before
    let after = monitor.value<PomodoroState>('state')!.now

    this.clearTimer()

    // 启动bouncing动画
    if (before.type === 'transition' &&
      (after.type === 'running' || after.type === 'stopped' || after.type === 'finished')) {
      this.isCircleBouncing = true
    } else {
      this.isCircleBouncing = false
    }

    // 启动扇形动画
    if (after.type === 'running') {
      this.startTicking()
    } else if (after.type === 'transition') {
      const from = after.from
      const to = after.to
      if (from.type === 'running' || from.type === 'paused') {
        this.scheduleCycleAnimation(from.elapsedTimeMS, from.totalTimeMS, from.totalTimeMS, () => {
          this.state = to
        })
      } else if (from.type === 'stopped' && to.type === 'running') {
        this.scheduleCycleAnimation(to.totalTimeMS, 0, to.totalTimeMS, () => {
          this.state = to
        })
      }
    }


    // 调用回调函数
    if (after.type === 'stopped') {
      this.onCancelled && this.onCancelled()
    }
    if (after.type === 'finished') {
      this.onFinished && this.onFinished()
    }
    if (after.type === 'running') {
      this.onStarted && this.onStarted()
    }
    if (after.type === 'paused') {
      this.onPaused && this.onPaused(after.elapsedTimeMS)
    }
  }

  @Builder
  buildRunning() {
    if (this.state.type !== 'stopped') {
      Canvas(this.pomodoroContext)
        .width('100%')
        .height('100%')
        .opacity(this.state.type !== 'paused' ? 1.0 : 0.5)
        .animation({ curve: curves.springMotion(0.2) })
    }
  }

  aboutToAppear(): void {
    if (this.autoStart) {
      this.state = {
        type: 'running',
        elapsedTimeMS: 0, totalTimeMS: this.pomodoroCount * this.pomodoroSeconds * 1000
      }
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
          .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion() }))
      } else if (this.state.type === 'stopped') {
        Image($r('app.media.play'))
          .width('30%')
          .height('30%')
          .fillColor(Color.White)
          .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion() }))
      }

      if (this.isCircleBouncing) {
        this.buildCycleBorder(true)
      } else {
        this.buildCycleBorder(false)
      }
    }
    .aspectRatio(1) // 强制宽高比1:1
  }

  @Builder
  buildCycleBorder(bouncing: boolean) {
    Stack() {
      Canvas(this.tickContext)
        .width('100%')
        .height('100%')
        .onReady(() => {
          drawTicks(this.tickContext, this.pomodoroCount, 8, Color.White);
        });

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
    .gesture(
      LongPressGesture()
        .onAction((event) => {
          if (this.state.type !== 'transition') {
            if (this.state.type === 'running' || this.state.type === 'paused') {
              this.state = { type: 'transition', from: this.state, to: { type: 'stopped' } };
            }
          }
        })
    )
    .transition(bouncing ? TransitionEffect.asymmetric(TransitionEffect.scale({ x: 1.05, y: 1.05 })
      .animation({ duration: 200, delay: 200 }), TransitionEffect.IDENTITY) :
      TransitionEffect.IDENTITY)
    .gesture(TapGesture()
      .onAction((event) => {
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