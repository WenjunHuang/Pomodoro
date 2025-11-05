import { PersistenceV2 } from '@kit.ArkUI'
import { Setting } from '../model/Setting'

@Builder
export function SettingPageBuilder() {
  SettingPage()
}

@ComponentV2
export struct SettingPage {
  @Local settings: Setting = PersistenceV2.globalConnect({ type: Setting, defaultCreator: () => new Setting() })!
  @Consumer('pageInfos') pageInfos: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {

    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      this.pageInfos.pop()
      return true
    })
  }
}