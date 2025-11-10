import { liveViewManager } from '@kit.LiveViewKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from './LogUtil';
import { ContextUtil } from './ContextUtil';
import { POMODORO_CLOCK_PAGE } from '../pages/Pages';
import { common } from '@kit.AbilityKit';
import { toMinuteSecondString } from './DateTimeUtils';

const UPDATE_INTERVAL = 1 * 1000;

export enum LiveViewState {
  RUNNING,
  PAUSED,
  WAITING_TO_START
}

/**
 * LiveView控制器，用于管理应用的LiveView功能
 */
export class LiveViewController {
  private static defaultView: liveViewManager.LiveView | undefined = undefined;
  private static capsuleColor: string = '#FFFFFFFF';
  private static starting: boolean = false;
  public static context: common.UIAbilityContext;
  private static lastUpdatedTime: number | undefined = undefined;

  /**
   * 启动或更新LiveView
   * @param title 标题
   * @param time 时间（秒）
   * @param desPic 描述图片
   * @param paused 是否暂停
   */
  public static async startOrUpdateLiveView(
    title: ResourceStr,
    time: number,
    desPic: string,
    state: LiveViewState = LiveViewState.RUNNING
  ): Promise<void> {
    // 防止重复启动
    if (LiveViewController.starting) {
      return;
    }

    // 如果已经存在默认视图，则更新它
    if (LiveViewController.defaultView) {
      return LiveViewController.updateLiveView(title, time, desPic, state);
    }

    await LiveViewController.startLiveView(title, time, desPic);
  }

  /**
   * 更新LiveView
   * @param title 标题
   * @param time 时间（秒）
   * @param desPic 描述图片
   * @param paused 是否暂停
   */
  public static async updateLiveView(
    title: ResourceStr,
    time: number,
    desPic: string,
    state: LiveViewState
  ): Promise<void> {
    try {
      // 检查是否可以更新
      if (!LiveViewController.canUpdateView(time)) {
        return;
      }

      // 更新最后更新时间
      LiveViewController.lastUpdatedTime = time;

      // 更新视图数据
      await LiveViewController.updateViewData(title, time, desPic, state);

      // 增加序列号
      LiveViewController.incrementSequence();

      Logger.info('Request updateLiveView: %{public}s', JSON.stringify(LiveViewController.defaultView));
      await liveViewManager.updateLiveView(LiveViewController.defaultView!);
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      Logger.error('Request updateLiveView error: %{public}d %{public}s', err.code, err.message);
    }
  }

  /**
   * 暂停计时器
   */
  public static async pauseTimer(): Promise<void> {
    Logger.info('pauseTimer');
    try {
      if (!LiveViewController.defaultView) {
        return;
      }

      // 更新主内容为暂停状态
      LiveViewController.defaultView.liveViewData.primary.content = [
        { text: await LiveViewController.getString($r("app.string.paused")) }
      ];

      // 增加序列号
      LiveViewController.incrementSequence();

      // 更新LiveView
      await liveViewManager.updateLiveView(LiveViewController.defaultView);
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      Logger.error('Request updateLiveView error: %{public}d %{public}s', err.code, err.message);
    }
  }

  /**
   * 继续计时器
   */
  public static async continueTimer(): Promise<void> {
    Logger.info('continueTimer');
    try {
      if (!LiveViewController.defaultView) {
        return;
      }

      // 更新计时器状态
      LiveViewController.defaultView.timer = {
        isPaused: false
      };

      // 更新主内容为运行状态
      LiveViewController.defaultView.liveViewData.primary.content = [
        { text: await LiveViewController.getString($r("app.string.running")) }
      ];

      // 更新胶囊数据
      LiveViewController.defaultView.liveViewData.capsule = {
        type: liveViewManager.CapsuleType.CAPSULE_TYPE_TIMER,
        status: 1,
        isPaused: false,
      };

      // 增加序列号
      LiveViewController.incrementSequence();

      // 更新LiveView
      await liveViewManager.updateLiveView(LiveViewController.defaultView);
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      Logger.error('Request updateLiveView error: %{public}d %{public}s', err.code, err.message);
    }
  }

  /**
   * 停止LiveView
   */
  public static async stopLiveView(): Promise<void> {
    try {
      // 检查LiveView是否启用且存在默认视图
      if (!await LiveViewController.isLiveViewEnabled() || !LiveViewController.defaultView) {
        Logger.warn('stopLiveView, live view is disabled.');
        return;
      }

      Logger.info('stopLiveView, get active live view succeed.');

      // 增加序列号
      LiveViewController.incrementSequence();

      // 销毁LiveView
      Logger.info('Request stopLiveView req: %{public}s', JSON.stringify(LiveViewController.defaultView));
      const result = await liveViewManager.stopLiveView(LiveViewController.defaultView);
      Logger.info('Request stopLiveView result: %{public}s', JSON.stringify(result));
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      Logger.error('Request stopLiveView error: %{public}d %{public}s', err.code, err.message);
    } finally {
      // 清理资源
      LiveViewController.cleanup();
    }
  }

  /**
   * 重置最后更新时间
   */
  public static resetLastUpdatedTime(): void {
    LiveViewController.lastUpdatedTime = undefined;
  }

  /**
   * 获取字符串值
   * @param value 资源字符串
   * @returns 字符串值
   */
  static async getString(value: ResourceStr): Promise<string> {
    if ((value as Resource).id !== undefined) {
      return await LiveViewController.context.resourceManager.getStringValue(value as Resource);
    } else {
      return value as string;
    }
  }

  /**
   * 启动LiveView
   * @param title 标题
   * @param time 时间（秒）
   * @param desPic 描述图片
   * @param paused 是否暂停
   */
  private static async startLiveView(
    title: ResourceStr,
    time: number,
    desPic: string,
    state: LiveViewState = LiveViewState.RUNNING
  ): Promise<void> {
    LiveViewController.starting = true;

    try {
      if (!await LiveViewController.isLiveViewEnabled()) {
        Logger.warn('startLiveView, live view is disabled.');
        return;
      }

      // 更新最后更新时间
      LiveViewController.lastUpdatedTime = time;

      // 构建默认视图
      LiveViewController.defaultView = await LiveViewController.buildDefaultView(title, time, desPic, state);
      if (!LiveViewController.defaultView) {
        Logger.warn('buildDefaultView Failed.');
        return;
      }

      // 启动LiveView
      const result = await liveViewManager.startLiveView(LiveViewController.defaultView);
      Logger.info('Request startLiveView result: %{public}s', JSON.stringify(result));
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      Logger.error('Request startLiveView error: %{public}d %{public}s', err.code, err.message);
    } finally {
      LiveViewController.starting = false;
    }
  }

  /**
   * 检查是否可以更新视图
   * @param time 当前时间
   * @returns 是否可以更新
   */
  private static canUpdateView(time: number): boolean {
    if (!LiveViewController.defaultView) {
      return false;
    }

    if (LiveViewController.lastUpdatedTime) {
      if (Math.abs(time - LiveViewController.lastUpdatedTime) < UPDATE_INTERVAL) {
        return false;
      }
    }

    return true;
  }

  /**
   * 更新视图数据
   * @param title 标题
   * @param time 时间（秒）
   * @param desPic 描述图片
   * @param paused 是否暂停
   */
  private static async updateViewData(
    title: ResourceStr,
    time: number,
    desPic: string,
    state: LiveViewState
  ): Promise<void> {
    if (!LiveViewController.defaultView) {
      return;
    }

    // 更新胶囊数据
    LiveViewController.defaultView.liveViewData.capsule = {
      title: await LiveViewController.getString(title),
      content: toMinuteSecondString(time),
      type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT,
      status: 1,
    };

    LiveViewController.defaultView.liveViewData.primary.title = await LiveViewController.getString(title)
    // 更新主布局数据
    LiveViewController.defaultView.liveViewData.primary.layoutData = {
      layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PICKUP,
      content: toMinuteSecondString(time),
      descPic: desPic
    };

    let text = ""
    if (state === LiveViewState.RUNNING) {
      text = await LiveViewController.getString($r("app.string.running"));
    } else if (state === LiveViewState.PAUSED) {
      text = await LiveViewController.getString($r("app.string.paused"))
    } else if (state ===
    LiveViewState.WAITING_TO_START) {
      text = await LiveViewController.getString($r("app.string.waiting_to_start"))
    }
    // 更新主内容
    LiveViewController.defaultView.liveViewData.primary.content = [{ text: text }];
  }

  /**
   * 增加序列号
   */
  private static incrementSequence(): void {
    if (LiveViewController.defaultView && LiveViewController.defaultView.sequence) {
      LiveViewController.defaultView.sequence += 1;
    }
  }

  /**
   * 清理资源
   */
  private static cleanup(): void {
    LiveViewController.defaultView = undefined;
    LiveViewController.lastUpdatedTime = undefined;
  }

  /**
   * 检查LiveView是否启用
   * @returns 是否启用
   */
  private static async isLiveViewEnabled(): Promise<boolean> {
    let result: boolean = false;
    try {
      result = await liveViewManager.isLiveViewEnabled();
    } catch (e) {
      Logger.error('Request isLiveViewEnabled error: %{public}s', e);
    }
    Logger.info('Request isLiveViewEnabled result: %{public}s', result);
    return result;
  }

  /**
   * 构建默认视图
   * @param title 标题
   * @param time 时间（秒）
   * @param desPic 描述图片
   * @returns LiveView对象或undefined
   */
  private static async buildDefaultView(
    title: ResourceStr,
    time: number,
    desPic: string,
    state: LiveViewState
  ): Promise<liveViewManager.LiveView | undefined> {
    try {

      let text = ""
      if (state === LiveViewState.RUNNING) {
        text = await LiveViewController.getString($r("app.string.running"));
      } else if (state === LiveViewState.PAUSED) {
        text = await LiveViewController.getString($r("app.string.paused"))
      } else if (state ===
      LiveViewState.WAITING_TO_START) {
        text = await LiveViewController.getString($r("app.string.waiting_to_start"))
      }
      return {
        id: 1,
        event: "PICK_UP",
        sequence: 1,
        isMute: true,
        liveViewData: {
          primary: {
            title: await LiveViewController.getString(title),
            keepTime: 0,
            clickAction: await ContextUtil.buildWantAgent(POMODORO_CLOCK_PAGE),
            layoutData: {
              title: await LiveViewController.getString($r("app.string.time_remaining")),
              layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PICKUP,
              content: toMinuteSecondString(time),
              descPic: desPic
            },
            content: [{ text: text }],
            extensionData: {
              type: liveViewManager.ExtensionType.EXTENSION_TYPE_DEFAULT,
            }
          },
          capsule: {
            type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT,
            status: 1,
            icon: 'foreground.png',
            title: await LiveViewController.getString(title),
            backgroundColor: LiveViewController.capsuleColor,
            content: toMinuteSecondString(time)
          }
        }
      };
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      Logger.error('BuildDefaultView Failed: %{public}d %{public}s', err.code, err.message);
      return undefined;
    }
  }
}


