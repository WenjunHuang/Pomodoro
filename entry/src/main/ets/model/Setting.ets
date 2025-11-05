import { ThemeColors } from "./ThemeColors"
import { Type } from "@kit.ArkUI"

export enum SoundTheme {
  NOTIFICATION,
  ALARM
}

@ObservedV2
export class Setting {
  @Trace pomodoro: number = 8
  @Trace break: number = 1
  @Trace longBreak: number = 1
  @Trace colorTheme: string = ThemeColors.Coral
  @Trace soundThemes: SoundTheme = SoundTheme.NOTIFICATION
  @Trace pomodorosUntilLongBreak: number = 4
  @Trace dailyGoal: number = 6
  @Trace vibrate: boolean = true
  @Trace autostartBreaks: boolean = true
  @Trace autostartPomodoros: boolean = true
  @Trace showNotification: boolean = true
  @Trace keepPhoneAwake: boolean = true
}