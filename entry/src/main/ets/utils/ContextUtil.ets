import { common, Want, WantAgent, wantAgent } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from './LogUtil';

export class ContextUtil {
  public static wantUrl: string | undefined;
  public static applicationContext: common.ApplicationContext;

  public static async buildWantAgent(page: string): Promise<Want> {
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: ContextUtil.applicationContext.applicationInfo.name,
          abilityName: 'EntryAbility',
          parameters: {
            page: page,
          },
        } as Want
      ],
      actionType: wantAgent.OperationType.START_ABILITIES,
      requestCode: 0,
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    try {
      const agent: WantAgent = await wantAgent.getWantAgent(wantAgentInfo);
      Logger.info('getWantAgent success! wantAgent: %{public}s', JSON.stringify(agent));
      return agent;
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      Logger.error('getWantAgent failed! err: %{public}d %{public}s', err.code, err.message);
      throw e as Error;
    }
  }
}