import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { worker } from '@kit.ArkTS';
import { Setting } from '../model/Setting';
import { setWindowKeep } from '../utils/WindowUtils';
import { DAILY_GOAL_PAGE, HOW_TO_PAGE, POMODORO_CLOCK_PAGE } from './Pages';
import { HowToPageBuilder } from './HowToPage';
import { PomodoroClockPage, PomodoroClockPageBuilder } from './PomodoroClockPage';


@Entry
@ComponentV2
export default struct Index {
  @Provider('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @Local settings: Setting = PersistenceV2.connect(Setting, () => new Setting())!
  private firstPage: string = POMODORO_CLOCK_PAGE

  aboutToAppear(): void {
    setWindowKeep(this.settings.keepPhoneAwake, this.getUIContext().getHostContext()!!)
    AppStorageV2.connect(NavPathStack, () => this.pageInfos);

    if (this.settings.firstStartApp) {
      this.firstPage = HOW_TO_PAGE
      this.settings.firstStartApp = false
      PersistenceV2.save(Setting)
    } else {
      this.firstPage = POMODORO_CLOCK_PAGE
    }
    this.pageInfos.pushPathByName(this.firstPage,false)
  }

  build() {
    Navigation(this.pageInfos)
    .titleMode(NavigationTitleMode.Free)
    .hideNavBar(true)
  }
}