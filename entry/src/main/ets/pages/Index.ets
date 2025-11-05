import { AppStorageV2, PersistenceV2, uiObserver } from '@kit.ArkUI'
import { Setting } from '../model/Setting';
import { PomodoroTimer } from '../components/PomodoroTimer';

@Entry
@ComponentV2
export default struct Index {
  @Provider('pageInfos')
  pageInfos: NavPathStack = new NavPathStack()
  @Local
  settings: Setting = PersistenceV2.globalConnect({ type: Setting, defaultCreator: () => new Setting() })!

  private firstPage:string = "PomodoroClock"

  aboutToAppear(): void {
    if (this.settings.firstStartApp){
      this.firstPage = "HowTo"
      this.settings.firstStartApp = false
      PersistenceV2.save(Setting)
    } else {
      this.firstPage = "PomodoroClock"
    }
  }
  build() {
    Navigation(this.pageInfos, { name: this.firstPage})
      .titleMode(NavigationTitleMode.Free)
      .width('100%')
      .height('100%')
  }
}