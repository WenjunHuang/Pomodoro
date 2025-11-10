import { window } from "@kit.ArkUI";
import { Context } from "@ohos.arkui.UIContext";


export function setWindowKeep(keep: boolean, context: Context) {
  let windowClass: window.Window | undefined = undefined;
  window.getLastWindow(context)
    .then((data) => {
      windowClass = data;
      windowClass.setWindowKeepScreenOn(keep).catch((err: BusinessError<Object>) => {
        const errCode: number = err.code;
        if (errCode) {
          console.error(`Failed to set the screen to be always on. Cause code: ${err.code}, message: ${err.message}`);
          return;
        }
        console.info('Succeeded in setting the screen to be always on.');
      });
    })
    .catch((error: BusinessError<Object>) => {
      console.error(`Failed to set the screen to be always on. Cause code: ${error.code}, message: ${error.message}`);
    })
}