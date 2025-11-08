import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppStorageV2, window } from '@kit.ArkUI';
import { ContextUtil } from '../utils/ContextUtil';
import { Logger } from '../utils/LogUtil';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      ContextUtil.applicationContext = this.context.getApplicationContext();
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      if (want.parameters?.page) {
        ContextUtil.wantUrl = want.parameters.page as string
      }
    } catch (error) {
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // let pageInfo = AppStorageV2.connect(NavPathStack, () => new NavPathStack())!
    // Logger.info("Ability onNewWant")
    // if (want.parameters?.page) {
    //   let result = pageInfo.moveToTop(want.parameters?.page as string)
    //   if (result === -1) {
    //     pageInfo.replacePathByName(want.parameters?.page as string, null)
    //   }
    // }
  }

  onDestroy(): void {
    Logger.info('Ability destroyed')
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    Logger.info('Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        Logger.error('Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      Logger.info('Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}