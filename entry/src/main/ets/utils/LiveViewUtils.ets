import { liveViewManager } from '@kit.LiveViewKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from './LogUtil';
import { ContextUtil } from './ContextUtil';
import { POMODORO_CLOCK_PAGE } from '../pages/Pages';
import { common } from '@kit.AbilityKit';

export class LiveViewController {
  private static defaultView: liveViewManager.LiveView | undefined = undefined;
  private static capsuleColor: string = '#FFFFFFFF';
  private static pickUpColor: string = '#FF0A59F7';
  private static starting: boolean = false;
  private context: common.UIAbilityContext

  constructor(context: common.UIAbilityContext) {
    this.context = context
  }

  public async startLiveView(title: ResourceStr, time: number, themeColor: string, paused: boolean): Promise<void> {
    if (LiveViewController.defaultView || LiveViewController.starting) {
      return;
    }

    LiveViewController.starting = true;

    if (!await LiveViewController.isLiveViewEnabled()) {
      Logger.warn('startLiveView, live view is disabled.')
      LiveViewController.starting = false;
      return;
    }

    //update liveView parameters
    LiveViewController.pickUpColor = themeColor
    LiveViewController.defaultView = await this.buildDefaultView(title, time, paused);
    if (!LiveViewController.defaultView) {
      Logger.warn('buildDefaultView Failed.')
      return;
    }
    //start liveView
    try {
      const result = await liveViewManager.startLiveView(LiveViewController.defaultView);
      Logger.info('Request startLiveView result: %{public}s', JSON.stringify(result));
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      Logger.error('Request startLiveView error: %{public}d %{public}s', err.code, err.message);
    } finally {
      LiveViewController.starting = false;
    }
  }

  public async updateTimer(title: ResourceStr, time: number, paused: boolean): Promise<void> {
    try {
      if (!LiveViewController.defaultView) {
        return
      }
      LiveViewController.defaultView.timer = {
        time: time,
        isPaused: paused
      }
      LiveViewController.defaultView.liveViewData.capsule = {
        type: liveViewManager.CapsuleType.CAPSULE_TYPE_TIMER,
        status: 1,
        time: time,
        isPaused: paused,
      }
      LiveViewController.defaultView.liveViewData.primary.layoutData = {
        //auxiliary area
        title: await this.getString(title),
        layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PICKUP,
        content: '${placeholder.timer}',
        descPic: "timer.png"
      }

      await this.getString(title)

      if (LiveViewController.defaultView.sequence) {
        LiveViewController.defaultView.sequence += 1;
      }
      await liveViewManager.updateLiveView(LiveViewController.defaultView);
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      Logger.error('Request updateLiveView error: %{public}d %{public}s', err.code, err.message);
    }
  }

  public async pauseTimer(): Promise<void> {
    Logger.info('pauseTimer');
    try {
      //is liveView parameters initialized
      if (!LiveViewController.defaultView) {
        return;
      }
      //update liveView parameters
      // LiveViewController.defaultView.timer = {
      //   isPaused: true
      // }
      LiveViewController.defaultView.liveViewData.primary.content =
        [{ text: await this.getString($r("app.string.paused")) }]
      // LiveViewController.defaultView.liveViewData.capsule = {
      //   type: liveViewManager.CapsuleType.CAPSULE_TYPE_TIMER,
      //   status: 1,
      //   isPaused: true,
      // }
      if (LiveViewController.defaultView.sequence) {
        LiveViewController.defaultView.sequence += 1;
      }
      //update liveView
      await liveViewManager.updateLiveView(LiveViewController.defaultView);
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      Logger.error('Request updateLiveView error: %{public}d %{public}s', err.code, err.message);
    }
  }

  public async continueTimer(): Promise<void> {
    Logger.info('continueTimer');
    try {
      //is liveView parameters initialized
      if (!LiveViewController.defaultView) {
        return;
      }
      //update liveView parameters
      // LiveViewController.defaultView.timer = {
      //   isPaused: false
      // }
      LiveViewController.defaultView.liveViewData.primary.content =
        [{ text: await this.getString($r("app.string.running")) }]
      // LiveViewController.defaultView.liveViewData.capsule = {
      //   type: liveViewManager.CapsuleType.CAPSULE_TYPE_TIMER,
      //   status: 1,
      //   isPaused: false,
      // }
      if (LiveViewController.defaultView.sequence) {
        LiveViewController.defaultView.sequence += 1;
      }
      //update liveView
      await liveViewManager.updateLiveView(LiveViewController.defaultView);
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      Logger.error('Request updateLiveView error: %{public}d %{public}s', err.code, err.message);
    }
  }

  public async stopLiveView(): Promise<void> {
    try {
      //live view is disabled
      if (!await LiveViewController.isLiveViewEnabled() || !LiveViewController.defaultView) {
        Logger.warn('stopLiveView, live view is disabled.')
        return;
      }
      Logger.info('stopLiveView, get active live view succeed.');
      //update liveView parameters
      if (LiveViewController.defaultView.sequence) {
        LiveViewController.defaultView.sequence += 1;
      }
      // LiveViewController.defaultView.liveViewData.primary.title = '已结束'
      // LiveViewController.defaultView.liveViewData.primary.layoutData = {
      //   layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PICKUP,
      //   underlineColor: LiveViewController.pickUpColor,
      // };
      // LiveViewController.defaultView.timer = {
      //   isPaused: true
      // };
      // LiveViewController.defaultView.liveViewData.capsule = {
      //   type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT,
      //   status: 1
      // }
      //destroy the liveView
      Logger.info('Request stopLiveView req: %{public}s', JSON.stringify(LiveViewController.defaultView));
      const result = await liveViewManager.stopLiveView(LiveViewController.defaultView);
      Logger.info('Request stopLiveView result: %{public}s', JSON.stringify(result));
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      Logger.error('Request stopLiveView error: %{public}d %{public}s', err.code, err.message);
    } finally {
      LiveViewController.defaultView = undefined
    }
  }

  private static async isLiveViewEnabled(): Promise<boolean> {
    //live view is disabled
    let result: boolean = false;
    try {
      result = await liveViewManager.isLiveViewEnabled();
    } catch (e) {
      Logger.error('Request isLiveViewEnabled error: %{public}s', e);
    }
    Logger.info('Request isLiveViewEnabled result: %{public}s', result);
    return result;
  }

  private async buildDefaultView(title: ResourceStr,
    time: number,
    paused: boolean): Promise<liveViewManager.LiveView | undefined> {
    try {
      return {
        id: 1, // liveView ID, generated by the developer
        event: "TIMER", // application scenarios of liveView:TIMER。
        sequence: 1, //serial number
        isMute: true, //is ringing reminder
        timer: {
          time: time,
          isPaused: paused,
          isCountdown: true
        },
        liveViewData: {
          primary: {
            title: await this.getString($r("app.string.app_name")),
            keepTime: 15,
            clickAction: await ContextUtil.buildWantAgent(POMODORO_CLOCK_PAGE),
            layoutData: {
              //auxiliary area
              title: await this.getString(title),
              layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PICKUP,
              content: '${placeholder.timer}',
              descPic: "timer.png"
            },
            content: [{ text: await this.getString($r("app.string.running")) }],
            extensionData: {
              //expansion Zone
              type: liveViewManager.ExtensionType.EXTENSION_TYPE_DEFAULT,
            }
          },
          capsule: {
            //capsule
            type: liveViewManager.CapsuleType.CAPSULE_TYPE_TIMER,
            status: 1,
            icon: 'foreground.png',
            backgroundColor: LiveViewController.capsuleColor,
            time: time,
            isCountdown: true,
            isPaused: paused,
          }
        }
      }
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      Logger.error('BuildDefaultView Failed: %{public}d %{public}s', err.code, err.message);
      return undefined;
    }
  }

  private async getString(value: ResourceStr): Promise<string> {
    if ((value as Resource).id !== undefined) {
      return await this.context.resourceManager.getStringValue(value as Resource)
    } else {
      return value as string
    }
  }
}


