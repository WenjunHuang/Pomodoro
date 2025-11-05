import { AppStorageV2, PersistenceV2, uiObserver } from '@kit.ArkUI'
import { curves } from '@kit.ArkUI';
import { Setting } from '../model/Setting';

interface Running {
  type: 'running';
  elapsedTime: number;
  totalTime: number;
}

interface Paused {
  type: 'paused';
  elapsedTime: number;
  totalTime: number;
}

interface Stopped {
  type: 'stopped';
}

interface Transition {
  type: 'transition';
  from: PomodoroState;
  to: PomodoroState;
}

type PomodoroState = Running | Paused | Stopped | Transition

@ObservedV2
class CircleBorderBouncingModifier implements AttributeModifier<CommonAttribute> {
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
struct Pomodoro {
  @Local isCircleBouncing: boolean = false
  @Local state: PomodoroState = { type: 'stopped' }
  @Local settings: Setting = PersistenceV2.globalConnect({ type: Setting, defaultCreator: () => new Setting() })!
  private pomodoroContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true))
  private tickContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true))
  private tickTimer?: number
  private static readonly DURATION_MS: number = 15 * 1000 //60 * 1000
  private static readonly TICK_MS: number = 33
  private static readonly REVERSE_STEPS: number = 30

  private clearTimer() {
    if (this.tickTimer !== undefined) {
      this.tickTimer = undefined
    }
  }

  private schedule(fn: () => void) {
    this.tickTimer = setTimeout(fn, Pomodoro.TICK_MS)
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
      if (this.state.elapsedTime >= this.state.totalTime) {
        this.state = { type: 'stopped' }
        this.clearTimer()
        return
      }
      this.state.elapsedTime += Pomodoro.TICK_MS
      this.drawProgress(this.state.elapsedTime, this.state.totalTime)
      this.schedule(tick)
    }
    this.schedule(tick)
  }

  private scheduleAnimation(from: number, to: number, total: number, callback?: () => void) {
    let current = from;
    let isReverse = from > to;
    const delta = total / Pomodoro.REVERSE_STEPS
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
    if (before.type === 'transition' && (after.type === 'running' || after.type === 'stopped')) {
      this.isCircleBouncing = true
    } else {
      this.isCircleBouncing = false
    }

    if (after.type === 'running') {
      this.startTicking()
    } else if (after.type === 'transition') {
      const from = after.from
      const to = after.to
      if (from.type === 'running' || from.type === 'paused') {
        this.scheduleAnimation(from.elapsedTime, from.totalTime, from.totalTime, () => {
          this.state = to
        })
      } else if (from.type === 'stopped' && to.type === 'running') {
        this.scheduleAnimation(to.totalTime, 0, to.totalTime, () => {
          this.state = to
        })
      }
    } else if (after.type === 'paused') {
      // no ticking while paused
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

  build() {
    Stack() {
      Column() {
        this.buildRunning()
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding(16)
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
    .width('60%')
    .aspectRatio(1) // 强制宽高比1:1
  }

  @Builder
  buildCycleBorder(bouncing: boolean) {
    Stack() {
      Canvas(this.tickContext)
        .width('100%')
        .height('100%')
        .onReady(() => {
          drawTicks(this.tickContext, this.settings.pomodoro, 8, Color.White);
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
      .animation({ curve: curves.springMotion(0.6, 1.2), delay: 100 }), TransitionEffect.IDENTITY) :
      TransitionEffect.IDENTITY)
    .gesture(TapGesture()
      .onAction((event) => {
        if (this.state.type === 'stopped') {
          this.state = {
            type: 'transition',
            from: this.state,
            to: {
              type: 'running',
              elapsedTime: 0, totalTime: this.settings.pomodoro * Pomodoro.DURATION_MS
            }
          };
        } else if (this.state.type === 'running') {
          this.state = { type: 'paused', elapsedTime: this.state.elapsedTime, totalTime: this.state.totalTime };
        } else if (this.state.type === 'paused') {
          this.state = { type: 'running', elapsedTime: this.state.elapsedTime, totalTime: this.state.totalTime };
        }
      })
    )
  }
}

function drawTicks(context: CanvasRenderingContext2D, ticksCount: number, tickLength: number, color: Color) {
  // 获取Canvas实际绘制尺寸
  const width = context.width
  const height = context.height
  const centerX = width / 2
  const centerY = height / 2
  const radius = Math.min(width, height) / 2 // 取短边为最大半径
  if (ticksCount <= 0) {
    return
  }

  context.beginPath()
  for (let index = 0; index < ticksCount; index++) {
    const theta = index * (2 * Math.PI / ticksCount)
    const fromX = centerX - (radius - tickLength) * Math.sin(theta)
    const fromY = centerY - (radius - tickLength) * Math.cos(theta)
    const toX = centerX - radius * Math.sin(theta)
    const toY = centerY - radius * Math.cos(theta)
    context.moveTo(fromX, fromY)
    context.lineTo(toX, toY)
  }
  context.closePath()

  // 填充样式设置
  context.lineWidth = 2
  context.strokeStyle = color.toString() // 设置填充颜色
  context.stroke()
}

function drawCircleSector(context: CanvasRenderingContext2D, startAngle: number, endAngle: number, color: Color) {
  // 获取Canvas实际绘制尺寸
  const width = context.width
  const height = context.height
  const centerX = width / 2
  const centerY = height / 2
  const radius = Math.min(width, height) / 2 // 取短边为最大半径
  context.clearRect(0, 0, context.width, context.height)

  if (startAngle == endAngle) {
    return
  } else {

    // 扇形参数设置（示例绘制120度扇形）
    const startRad = startAngle * Math.PI / 180 - Math.PI / 2
    const endRad = endAngle * Math.PI / 180 - Math.PI / 2

    // 绘制路径
    context.beginPath()
    context.moveTo(centerX, centerY)
    context.arc(centerX, centerY, radius, startRad, endRad)
    context.closePath()

    // 填充样式设置
    context.fillStyle = color.toString() // 设置填充颜色
    context.fill()
  }
}


@Entry
@ComponentV2
export default struct Index {
  build() {
    Column() {
      Blank()
      Pomodoro()
      Blank()
    }
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.Pink)
    .width('100%')
    .height('100%')
  }
}