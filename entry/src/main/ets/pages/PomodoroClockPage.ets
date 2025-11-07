import { PomodoroTimer } from '../components/PomodoroTimer'
import { Setting } from '../model/Setting'
import { PersistenceV2 } from '@kit.ArkUI'
import { getDisabledColor } from '../utils/ColorUtils'

@Builder
export function PomodoroClockPageBuilder() {
  PomodoroClockPage()
}

@ComponentV2
export struct PomodoroClockPage {
  @Local settings: Setting = PersistenceV2.globalConnect({ type: Setting, defaultCreator: () => new Setting() })!
  @Consumer('pageInfos') pageInfos: NavPathStack = new NavPathStack()

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
        }
        .width('100%')
        .onClick(() => {
          this.pageInfos.pushDestination({ name: "Setting" })
        })
        .margin({ bottom: 24 })

        // 番茄钟计时器
        PomodoroTimer({
          pomodoroCount: this.settings.pomodoro,
          pomodoroSeconds: 60,
          onRunning: (elapsed, total) => {
            // 空回调，可根据需要添加处理逻辑
          },
        }).width('80%')
          .margin({ bottom: 64 })

        // 进度显示区域
        Row() {
          ForEach(Array.from({ length: Math.ceil(this.settings.dailyGoal / 3) }), (_: number, slot) => {
            this.buildProgressRow(slot)
          })
        }
        .width("50%")
        .justifyContent(FlexAlign.Center)

        Blank()
      }
      .padding(16)
      .width('100%')
      .height('100%')
    }
    .backgroundColor(this.settings.colorTheme)
    .hideTitleBar(true)
  }
}