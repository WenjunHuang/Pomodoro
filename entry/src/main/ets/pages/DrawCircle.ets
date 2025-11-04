import { AppStorageV2, uiObserver } from '@kit.ArkUI'
import { curves } from '@kit.ArkUI';

class ClockStopped {
  type: "stopped" = "stopped"
}

class ClockRunning {
  type: "running" = "running"
  elapsedTime: number;
  totalTime: number;

  constructor(elapsedTime: number, totalTime: number) {
    this.elapsedTime = elapsedTime;
    this.totalTime = totalTime
  }
}

class ClockPaused {
  type: "paused" = "paused"
  elapsedTime: number;
  totalTime: number;

  constructor(elapsedTime: number, totalTime: number) {
    this.elapsedTime = elapsedTime;
    this.totalTime = totalTime
  }
}

type StatusType = ClockStopped | ClockRunning | ClockPaused;

// @ObservedV2
// class ClockStatus {
//   @Trace status:StatusType
//   constructor(status:StatusType) {
//     this.status = status
//   }
// }


@ComponentV2
struct ClockOutline {
  build() {
    Column() {
      this.customBuilderParam()
    }
    .width('80%')
    .aspectRatio(1) // 强制宽高比1:1
    .padding(8)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .borderColor(Color.Black)
    .borderWidth(8)
    .borderRadius('50%')
  }

  @Builder
  doNothing() {
  }

  @BuilderParam customBuilderParam: () => void = this.doNothing;
}

@ComponentV2
struct Clock {
  @Local scaleAnimation: boolean = false
  @Local status: StatusType = new ClockStopped()
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  @Monitor('status')
  onStatusChanged(monitor: IMonitor) {
    let before = monitor.value<StatusType>('status')!.before
    let after = monitor.value<StatusType>('status')!.now

    if (after.type === 'running') {
      let fn = () => {
        if (this.status.type === 'running') {
          let s = this.status as ClockRunning
          if (s.elapsedTime >= s.totalTime) {
            this.status = new ClockStopped()
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
    }
  }

  @Builder
  buildRunning(status: ClockRunning | ClockPaused) {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .opacity(this.status.type !== 'paused' ? 1.0 : 0.5)
      .animation({ curve: curves.springMotion(0.2) })
      .onReady(() => drawCircle(this.context,
        0, (status.elapsedTime / status.totalTime) * 360, Color.White))
  }

  build() {
    Stack() {
      Column() {
        if (this.status.type === "running" || this.status.type === 'paused') {
          this.buildRunning(this.status)
        }
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding(8)
      .borderWidth(8)
      .borderRadius('50%')
      .borderColor(Color.Transparent)
      .width('100%')
      .height('100%')

      if (this.status.type === 'paused') {
        Image($r('app.media.pause'))
          .width('30%')
          .height('30%')
          .fillColor(Color.White)
          .transition(TransitionEffect.OPACITY.animation({curve: curves.springMotion()}))
      }

      Column()
        .width('100%')
        .height('100%')
        .borderColor(Color.White)
        .borderWidth(8)
        .borderRadius('50%')
        .scale({ x: this.scaleAnimation ? 1.09 : 1, y: this.scaleAnimation ? 1.09 : 1 })
        .animation({
          curve: curves.springMotion(0.1), onFinish: () => {
            if (this.scaleAnimation) {
              this.scaleAnimation = false
            }
          }
        })
        .onClick(() => {
          if (this.status.type === "stopped") {
            this.status = new ClockRunning(0, 60 * 1000)
          } else if (this.status.type === 'running') {
            let paused = new ClockPaused(this.status.elapsedTime, this.status.totalTime)
            this.status = paused;
          } else if (this.status.type === 'paused') {
            let running = new ClockRunning(this.status.elapsedTime, this.status.totalTime)
            this.status = running
          }
        })
    }
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


@Entry
@ComponentV2
export default struct Index {
  build() {
    Column() {
      Clock()
    }
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.Pink)
    .width('100%')
    .height('100%')
  }
}