import { liveViewManager } from '@kit.LiveViewKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from './LogUtil';
import { ContextUtil } from './ContextUtil';
import { POMODORO_CLOCK_PAGE } from '../pages/Pages';
import { common } from '@kit.AbilityKit';
import { toMinuteSecondString } from './DateTimeUtils';

const UPDATE_INTERVAL = 2 * 1000

export class LiveViewController {
  private static defaultView: liveViewManager.LiveView | undefined = undefined;
  private static capsuleColor: string = '#FFFFFFFF';
  private static starting: boolean = false;
  public static context: common.UIAbilityContext
  private static lastUpdatedTime: number | undefined = undefined

  public static async startOrUpdateLiveView(title: ResourceStr, time: number, desPic: string,
    paused: boolean): Promise<void> {
    if (LiveViewController.starting) {
      return;
    }
    if (LiveViewController.defaultView) {
      return LiveViewController.updateLiveView(title, time, desPic, paused)
    }

    LiveViewController.starting = true;

    if (!await LiveViewController.isLiveViewEnabled()) {
      Logger.warn('startLiveView, live view is disabled.')
      LiveViewController.starting = false;
      return;
    }

    //update liveView parameters
    LiveViewController.lastUpdatedTime = time
    LiveViewController.defaultView = await LiveViewController.buildDefaultView(title, time, desPic, paused);
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

  public static async updateLiveView(title: ResourceStr, time: number, desPic: string, paused: boolean): Promise<void> {
    try {
      if (!LiveViewController.defaultView) {
        return
      }
      if (LiveViewController.lastUpdatedTime) {
        if (Math.abs(time - LiveViewController.lastUpdatedTime) < UPDATE_INTERVAL) {
          return
        }
      }
      LiveViewController.lastUpdatedTime = time

      // LiveViewController.defaultView.timer = {
      //   time: time,
      //   isPaused: paused,
      // }

      LiveViewController.defaultView.liveViewData.capsule = {
        content: toMinuteSecondString(time),
        // type: liveViewManager.CapsuleType.CAPSULE_TYPE_TIMER,
        type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT,
        status: 1,
        // time: time,
        // isPaused: paused,
      }
      LiveViewController.defaultView.liveViewData.primary.layoutData = {
        //auxiliary area
        // title: await LiveViewController.getString(title),
        layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PICKUP,
        // content: '${placeholder.timer}',
        content: toMinuteSecondString(time),
        // descPic: desPic
      }
      // LiveViewController.defaultView.liveViewData.primary.title =
      //   await LiveViewController.getString($r("app.string.running"))

      if (LiveViewController.defaultView.sequence) {
        LiveViewController.defaultView.sequence += 1;
      }
      Logger.info('Request updateLiveView: %{public}s',JSON.stringify(LiveViewController.defaultView))
      await liveViewManager.updateLiveView(LiveViewController.defaultView);
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      Logger.error('Request updateLiveView error: %{public}d %{public}s', err.code, err.message);
    }
  }

  public static async pauseTimer(): Promise<void> {
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
        [{ text: await LiveViewController.getString($r("app.string.paused")) }]
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

  public static async continueTimer(): Promise<void> {
    Logger.info('continueTimer');
    try {
      //is liveView parameters initialized
      if (!LiveViewController.defaultView) {
        return;
      }
      //update liveView parameters
      LiveViewController.defaultView.timer = {
        isPaused: false
      }
      LiveViewController.defaultView.liveViewData.primary.content =
        [{ text: await LiveViewController.getString($r("app.string.running")) }]
      LiveViewController.defaultView.liveViewData.capsule = {
        type: liveViewManager.CapsuleType.CAPSULE_TYPE_TIMER,
        status: 1,
        isPaused: false,
      }
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

  public static async stopLiveView(): Promise<void> {
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
      //destroy the liveView
      Logger.info('Request stopLiveView req: %{public}s', JSON.stringify(LiveViewController.defaultView));
      const result = await liveViewManager.stopLiveView(LiveViewController.defaultView);
      Logger.info('Request stopLiveView result: %{public}s', JSON.stringify(result));
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      Logger.error('Request stopLiveView error: %{public}d %{public}s', err.code, err.message);
    } finally {
      LiveViewController.defaultView = undefined
      LiveViewController.lastUpdatedTime = undefined
    }
  }

  public static resetLastUpdatedTime() {
    LiveViewController.lastUpdatedTime = undefined
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

  private static async buildDefaultView(title: ResourceStr,
    time: number,
    desPic: string,
    paused: boolean): Promise<liveViewManager.LiveView | undefined> {
    try {
      return {
        id: 1, // liveView ID, generated by the developer
        event: "PICK_UP", // application scenarios of liveView:TIMER。
        sequence: 1, //serial number
        isMute: true, //is ringing reminder
        // timer: {
        //   time: time,
        //   isPaused: paused,
        //   isCountdown: true
        // },
        liveViewData: {
          primary: {
            title: await LiveViewController.getString($r("app.string.app_name")),
            keepTime: 0,
            clickAction: await ContextUtil.buildWantAgent(POMODORO_CLOCK_PAGE),
            layoutData: {
              //auxiliary area
              title: "def",//await LiveViewController.getString(title),
              layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PICKUP,
              content: toMinuteSecondString(time),//'${placeholder.timer}',
              descPic: desPic
            },
            content: [{ text: "abc"}],//await LiveViewController.getString($r("app.string.running")) }],
            extensionData: {
              //expansion Zone
              type: liveViewManager.ExtensionType.EXTENSION_TYPE_DEFAULT,
            }
          },
          capsule: {
            //capsule
            type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT,//liveViewManager.CapsuleType.CAPSULE_TYPE_TIMER,
            status: 1,
            icon: 'foreground.png',
            title: await LiveViewController.getString(title),
            backgroundColor: LiveViewController.capsuleColor,
            content: toMinuteSecondString(time)
            // time: time,
            // isCountdown: true,
            // isPaused: paused,
          }
        }
      }
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      Logger.error('BuildDefaultView Failed: %{public}d %{public}s', err.code, err.message);
      return undefined;
    }
  }

  static async getString(value: ResourceStr): Promise<string> {
    if ((value as Resource).id !== undefined) {
      return await LiveViewController.context.resourceManager.getStringValue(value as Resource)
    } else {
      return value as string
    }
  }
}


