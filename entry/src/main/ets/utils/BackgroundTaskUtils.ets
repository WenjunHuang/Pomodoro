import { common, UIAbility, wantAgent } from "@kit.AbilityKit";

export class BackgroundTaskController {
  public static applicationContext:common.ApplicationContext

  public static async startTask(){
    // let wantAgentInfo: wantAgent.WantAgentInfo = {
    //   wants:[
    //     {
    //       bundleName: BackgroundTaskController.applicationContext.applicationInfo.name,
    //       abilityName: "EntryAbility"
    //     }
    //   ],
    //   actionType: wantAgent.OperationType.START_ABILITY,
    // }
  }
}