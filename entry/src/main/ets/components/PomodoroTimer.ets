import { AnimatorResult } from '@kit.ArkUI';
import { CIRCLE_STEPS, Phrase, TICK_MS, TimerState } from '../model/Pomodoro';
import { drawCircleSector } from '../utils/DrawingUtils';
import { PomodoroTicker } from './PomodoroTicker';


@ComponentV2
export struct PomodoroTimer {
  @Require @Param phrase: Phrase
  @Require @Param pomodoroCount: number
  @Require @Param pomodoroSeconds: number
  // Timer当前的状态
  @Require @Param state: TimerState
  // Timer已经准备好进入下一个状态（例如已经完成对应的动画了）
  @Param onReadyToRun?: () => void = undefined
  @Param onReadyToStop?: () => void = undefined
  @Param onLongTap?: () => void = undefined
  @Param onTap?: () => void = undefined
  @Local isCircleBouncing: boolean = false
  @Local circleScale: number = 1
  @Local isAnimating: boolean = false
  private tickTimer?: number
  private pomodoroContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true))
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

  private clearTimer() {
    if (this.tickTimer !== undefined) {
      this.tickTimer = undefined
    }
  }

  private schedule(fn: () => void) {
    this.tickTimer = setTimeout(fn, TICK_MS)
  }

  private drawProgress(elapsed: number, total: number) {
    let remaining = total - elapsed
    drawCircleSector(this.pomodoroContext, 0, (remaining / total) * 360, Color.White)
  }

  private scheduleCycleAnimation(from: number, to: number, total: number, callback?: () => void) {
    let current = from;
    let isReverse = from > to;
    const delta = total / CIRCLE_STEPS
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

  @Monitor("isCircleBouncing")
  onCircleBouncing() {
    if (this.isCircleBouncing) {
      this.bouncingAnim.cancel()
      this.bouncingAnim.onFrame = (value) => this.circleScale = value
      this.bouncingAnim.onFinish = () => {
        this.isCircleBouncing = false
        this.isAnimating = false

        if (this.state.type == "prerun") {
          this.onReadyToRun && this.onReadyToRun()
        } else if (this.state.type === "prestop") {
          this.onReadyToStop && this.onReadyToStop()
        }
      }
      this.bouncingAnim.onCancel = () => {
        this.isCircleBouncing = false
        this.isAnimating = false

        if (this.state.type == "prerun") {
          this.onReadyToRun && this.onReadyToRun()
        } else if (this.state.type === "prestop") {
          this.onReadyToStop && this.onReadyToStop()
        }
      }
      this.bouncingAnim.play()
    }
  }

  @Monitor('state')
  onStateChanged(monitor: IMonitor) {
    let before = monitor.value<TimerState>('state')!.before
    let after = monitor.value<TimerState>('state')!.now

    this.clearTimer()

    // 启动bouncing动画
    // if ((before.type === 'stopped' && after.type === 'running') || after.type === 'stopped') {
    //   this.isCircleBouncing = true
    // } else {
    //   this.isCircleBouncing = false
    // }
    this.isCircleBouncing = false

    if ((before.type === 'running' || before.type === 'paused') && after.type === 'prestop') {
      // 从运行或暂停状态到停止状态，先运行扇形动画
      this.isAnimating = true
      this.scheduleCycleAnimation(before.elapsedTimeMS, before.totalTimeMS, before.totalTimeMS, () => {
        // 然后再进行边框弹跳动画
        this.isCircleBouncing = true
      })
    } else if (before.type === 'stopped' && after.type === 'prerun') {
      // 启动时钟前，先显示扇形动画
      this.isAnimating = true
      this.scheduleCycleAnimation(after.totalTimeMS, 0, after.totalTimeMS, () => {
        // 然后再进行边框弹跳动画
        this.isCircleBouncing = true
      })
    }

    if (!this.isAnimating && after.type === "running") {
      this.drawProgress(after.elapsedTimeMS, after.totalTimeMS)
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

  build() {
    Stack() {
      Column() {
        this.buildRunning()
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding(28)
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
    .gesture(
      LongPressGesture()
        .onAction(() => {
          if (!this.isAnimating) {
            this.onLongTap && this.onLongTap()
          }
        })
    )
    .gesture(TapGesture()
      .onAction(() => {
        if (!this.isAnimating) {
          this.onTap && this.onTap()
        }
      })
    )
  }

  @Builder
  buildCycleBorder() {
    Stack() {
      PomodoroTicker({
        tickLength: PomodoroTicker.MAX_TICK_LENGTH,
        ticksCount: this.pomodoroCount,
        // tickAnim: !this.isCircleBouncing && (this.state.type === 'stopped' || this.state.type === 'finished')
      })

      Column() {
        Column()
          .width('100%')
          .height('100%')
          .borderColor(Color.White)
          .borderWidth(8)
          .borderRadius('50%');
      }
      .padding(20)
      .width('100%')
      .height('100%');
    }
    .width('100%')
    .height('100%')
    .scale({ x: this.circleScale, y: this.circleScale })

  }
}