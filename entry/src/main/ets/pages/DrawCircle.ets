import { AppStorageV2, PersistenceV2, uiObserver } from '@kit.ArkUI'
import { curves } from '@kit.ArkUI';
import { Setting } from '../model/Setting';

class NotStartedState {
  type: "stopped" = "stopped"
}

class RunningState {
  type: "running" = "running"
  elapsedTime: number;
  totalTime: number;

  constructor(elapsedTime: number, totalTime: number) {
    this.elapsedTime = elapsedTime;
    this.totalTime = totalTime
  }
}

class PausedState {
  type: "paused" = "paused"
  elapsedTime: number;
  totalTime: number;

  constructor(elapsedTime: number, totalTime: number) {
    this.elapsedTime = elapsedTime;
    this.totalTime = totalTime
  }
}

type NormalState = NotStartedState | RunningState | PausedState;

class TransitionState {
  type: "transition" = "transition"
  from: PomodoroState
  to: PomodoroState

  constructor(from: PomodoroState, to: PomodoroState) {
    this.from = from
    this.to = to
  }
}

type PomodoroState = TransitionState | NormalState

@ComponentV2
struct Pomodoro {
  @Local isShowScaleBorder: boolean = false
  @Local state: PomodoroState = new RunningState(30 * 1000, 60 * 1000)
  @Local settings: Setting = PersistenceV2.globalConnect({ type: Setting, defaultCreator: () => new Setting() })!
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true))

  @Monitor('state')
  onStatusChanged(monitor: IMonitor) {
    let after = monitor.value<PomodoroState>('state')!.now

    if (after.type === 'running') {
      this.isShowScaleBorder = false
      let fn = () => {
        if (this.state.type === 'running') {
          let s = this.state as RunningState
          if (s.elapsedTime >= s.totalTime) {
            this.state = new NotStartedState()
          } else {
            s.elapsedTime += 33;
            drawCircle(this.context,
              0, (s.elapsedTime / s.totalTime) * 360, Color.White)
            setTimeout(fn, 33);
          }
        }
      }
      setTimeout(fn, 33)
    } else if (after.type === 'paused') {
    } else if (after.type === 'transition') {
      let from = after.from
      let to = after.to
      if (from.type === 'running' || from.type === 'paused') {
        let elapsedTime = from.elapsedTime
        let totalTime = from.totalTime
        let delta = totalTime / 30
        let fn = () => {
          if (elapsedTime > 0) {
            elapsedTime = Math.max(0, elapsedTime - delta)
            drawCircle(this.context,
              0, (elapsedTime / totalTime) * 360, Color.White)
            setTimeout(fn, 33);
          } else {
            this.state = to
          }
        }
        setTimeout(fn, 33)
      }
    }
  }

  @Builder
  buildRunning() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .opacity(this.state.type !== 'paused' ? 1.0 : 0.5)
      .animation({ curve: curves.springMotion(0.2) })
      .onReady(() => {
        if (this.state.type === 'paused' || this.state.type === "running") {
          drawCircle(this.context,
            0, (this.state.elapsedTime / this.state.totalTime) * 360, Color.White)
        }
      })
  }

  build() {
    Stack() {
      Column() {
        this.buildRunning()
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding(8)
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

      if (this.isShowScaleBorder) {
        Column()
          .width('100%')
          .height('100%')
          .borderColor(Color.White)
          .borderWidth(8)
          .borderRadius('50%')
          .transition(TransitionEffect.scale({ x: 0, y: 0 }).animation({ curve: curves.springMotion(0.6, 1.2) }))
      } else {
        Column()
          .width('100%')
          .height('100%')
          .borderColor(Color.White)
          .borderWidth(8)
          .borderRadius('50%')
      }
    }
    .gesture(
      LongPressGesture()
        .onAction((event) => {
          if (this.state.type !== 'transition') {
            if (this.state.type === "running" || this.state.type === "paused") {
              let transition = new TransitionState(this.state, new NotStartedState())
              this.state = transition
            }
          }
        })
    ).gesture(TapGesture()
      .onAction((event) => {
        if (this.state.type === "stopped") {
          this.state = new RunningState(0, 60 * 1000)
        } else if (this.state.type === 'running') {
          let paused = new PausedState(this.state.elapsedTime, this.state.totalTime)
          this.state = paused;
        } else if (this.state.type === 'paused') {
          let running = new RunningState(this.state.elapsedTime, this.state.totalTime)
          this.state = running
        }
      })
    )
    .width('60%')
    .aspectRatio(1) // 强制宽高比1:1
  }
}

function drawCircle(context: CanvasRenderingContext2D, startAngle: number, endAngle: number, color: Color) {
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
      Pomodoro()
    }
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.Pink)
    .width('100%')
    .height('100%')
  }
}