import { drawTicks } from '../utils/DrawingUtils'
import { AnimatorResult } from '@kit.ArkUI'

@ComponentV2
export struct PomodoroTicker {
  @Param @Require tickLength: number
  @Param @Require ticksCount: number
  // @Param tickAnim: boolean = false
  static readonly MAX_TICK_LENGTH: number = 8
  private tickContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true))
  private animator: AnimatorResult | undefined = undefined

  /**
   * 绘制刻度线
   * @param progress - 绘制进度
   */
  private drawTicker(progress: number) {
    drawTicks(this.tickContext, this.ticksCount, this.tickLength, progress, Color.White)
  }

  @Monitor("tickLength","ticksCount")
  onTickChanged() {
    this.animator?.finish()
    let animator =
      this.getUIContext()
        .createAnimator({
          duration: 300,
          easing: "ease",
          delay: 0,
          fill: "forwards",
          direction: "normal",
          iterations: 1,
          begin: 0,
          end: this.tickLength
        })
    animator.onFrame = (progress: number) => {
      this.drawTicker(progress)
    }
    animator.play()
    this.animator = animator
  }

  build() {
    Canvas(this.tickContext)
      .width('100%')
      .height('100%')
      .onReady(() => {
        this.drawTicker(this.tickLength)
      })
  }
}
