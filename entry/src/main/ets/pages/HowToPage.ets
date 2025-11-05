
@Builder
export function HowToPageBuilder(){
  HowToPage()
}
@ComponentV2
export struct HowToPage {
  @Consumer('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  build() {
    NavDestination() {
      Column() {
        Text("How To")
      }
    }.onBackPressed(()=>{
      this.pageInfos.replacePath({name:"PomodoroClock"})
      return true
    })
  }
}