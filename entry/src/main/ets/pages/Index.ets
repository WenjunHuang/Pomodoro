import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { worker } from '@kit.ArkTS';
import { Setting } from '../model/Setting';
import { setWindowKeep } from '../utils/WindowUtils';
import { DAILY_GOAL_PAGE, HOW_TO_PAGE, POMODORO_CLOCK_PAGE } from './Pages';


@Entry
@ComponentV2
export default struct Index {
  @Provider('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  // @Provider('timerWorker') timerWorker: worker.ThreadWorker =
  //   new worker.ThreadWorker("entry/ets/workers/TimerWorker.ets")
  @Local settings: Setting = PersistenceV2.connect(Setting, () => new Setting())!
  private firstPage: string = POMODORO_CLOCK_PAGE

  aboutToAppear(): void {
    setWindowKeep(this.settings.keepPhoneAwake, this.getUIContext().getHostContext()!!)
    AppStorageV2.connect(NavPathStack, () => this.pageInfos);
    // AppStorageV2.connect(worker.ThreadWorker, () => this.timerWorker)

    if (this.settings.firstStartApp) {
      this.firstPage = HOW_TO_PAGE
      this.settings.firstStartApp = false
      PersistenceV2.save(Setting)
    } else {
      this.firstPage = POMODORO_CLOCK_PAGE
    }

  }

  build() {
    Navigation(this.pageInfos, { name: this.firstPage })
      .titleMode(NavigationTitleMode.Free)
      .width('100%')
      .height('100%')
  }
}