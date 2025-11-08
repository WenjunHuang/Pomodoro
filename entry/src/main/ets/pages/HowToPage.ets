import { BoldText, parseHtmlText } from '../utils/StringUtils'

@Builder
export function HowToPageBuilder() {
  HowToPage()
}

@ComponentV2
export struct HowToPage {
  @Consumer('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  private controller: SwiperController = new SwiperController()

  build() {
    NavDestination() {
      Swiper() {
        // 使用解析函数处理带HTML标签的字符串
        Column() {
          Image($r("app.media.pomodoro"))
            .width("30%")
            .aspectRatio(1)
            .margin({ bottom: 32 })
          Text() {
            ForEach(parseHtmlText(this.getUIContext()
              .getHostContext()!.resourceManager.getStringSync($r("app.string.onboarding_title_1").id))
              , (item: BoldText, index) => {
                Span(`${item.content}`)
                  .fontWeight(item.isBold ? FontWeight.Bold : FontWeight.Normal)
              })
          }
          .fontSize(16)
          .margin({ bottom: 32 })

          Text($r("app.string.onboarding_description_1"))
            .wordBreak(WordBreak.NORMAL)
            .lineHeight(14 * 2)
            .fontSize(14)
        }
        .padding(16)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Start)
        .width("100%")
        .height("100%")

        Column() {
          Text() {
            ForEach(parseHtmlText(this.getUIContext()
              .getHostContext()!.resourceManager.getStringSync($r("app.string.onboarding_title_2").id))
              , (item: BoldText, index) => {
                Span(`${item.content}`)
                  .fontWeight(item.isBold ? FontWeight.Bold : FontWeight.Normal)
              })
          }
          .fontSize(16)
          .margin({ bottom: 32 })

          Text($r("app.string.onboarding_description_2"))
            .wordBreak(WordBreak.NORMAL)
            .lineHeight(14 * 2)
            .fontSize(14)

          Blank()
          Image($r("app.media.avatar"))
            .width("40%")
          Blank()
        }
        .padding(16)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Start)
        .width("100%")
        .height("100%")

        Column() {
          Text() {
            ForEach(parseHtmlText(this.getUIContext()
              .getHostContext()!.resourceManager.getStringSync($r("app.string.onboarding_title_3").id))
              , (item: BoldText, index) => {
                Span(`${item.content}`)
                  .fontWeight(item.isBold ? FontWeight.Bold : FontWeight.Normal)
              })
          }
          .fontSize(16)
          .margin({ bottom: 32 })

          Text($r("app.string.onboarding_description_3"))
            .wordBreak(WordBreak.NORMAL)
            .lineHeight(14 * 2)
            .fontSize(14)

          Image($r("app.media.desktop"))
            .width("40%")
            .margin({ top: 64 })
        }
        .padding(16)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Start)
        .width("100%")
        .height("100%")

        Column() {
          Text() {
            ForEach(parseHtmlText(this.getUIContext()
              .getHostContext()!.resourceManager.getStringSync($r("app.string.onboarding_title_4").id))
              , (item: BoldText, index) => {
                Span(`${item.content}`)
                  .fontWeight(item.isBold ? FontWeight.Bold : FontWeight.Normal)
              })
          }
          .fontSize(16)
          .margin({ bottom: 32 })

          Text($r("app.string.onboarding_description_4"))
            .wordBreak(WordBreak.NORMAL)
            .lineHeight(14 * 2)
            .fontSize(14)

          Blank()
          Image($r("app.media.park"))
            .width("100%")
        }
        .padding(16)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Start)
        .width("100%")
        .height("100%")

        Column() {
          Text() {
            ForEach(parseHtmlText(this.getUIContext()
              .getHostContext()!.resourceManager.getStringSync($r("app.string.onboarding_title_5").id))
              , (item: BoldText, index) => {
                Span(`${item.content}`)
                  .fontWeight(item.isBold ? FontWeight.Bold : FontWeight.Normal)
              })
          }
          .fontSize(16)
          .margin({ bottom: 32 })

          Text($r("app.string.onboarding_description_5"))
            .wordBreak(WordBreak.NORMAL)
            .lineHeight(14 * 2)
            .fontSize(14)

          Blank()
          Image($r("app.media.gear"))
            .width("40%")
          Blank()
        }
        .padding(16)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Start)
        .width("100%")
        .height("100%")

        Column() {
          Text() {
            ForEach(parseHtmlText(this.getUIContext()
              .getHostContext()!.resourceManager.getStringSync($r("app.string.onboarding_title_6").id))
              , (item: BoldText, index) => {
                Span(`${item.content}`)
                  .fontWeight(item.isBold ? FontWeight.Bold : FontWeight.Normal)
              })
          }
          .fontSize(16)
          .margin({ bottom: 32 })

          Text($r("app.string.onboarding_description_6"))
            .wordBreak(WordBreak.NORMAL)
            .lineHeight(14 * 2)
            .fontSize(14)

          Column() {
            Image($r("app.media.dart"))
              .width("40%")
            Button($r("app.string.onboarding_start_button_label"))
              .onClick(()=>{
                this.pageInfos.replacePath({ name: "PomodoroClock" })
              })
          }.justifyContent(FlexAlign.SpaceEvenly)
          .layoutWeight(1)
          .width("100%")
        }
        .padding(16)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Start)
        .width("100%")
        .height("100%")
      }
      .loop(false)
      .width("100%")
      .height("100%")
    }
    .backgroundColor(Color.White)
    .hideTitleBar(true)
    .onBackPressed(() => {
      if (this.pageInfos.size() > 1) {
        this.pageInfos.pop()
      }
      return true
    })
  }
}