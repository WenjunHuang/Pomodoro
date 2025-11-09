import { todayString } from '../utils/DateTimeUtils'
import { ThemeColors } from './ThemeColors'
import { PersistenceV2 } from '@kit.ArkUI'
import { Phrase } from './Pomodoro'

export enum SoundTheme {
  NOTIFICATION,
  ALARM
}

export function todayFinishedPomodoroCount(setting: Setting): number {
  let count = setting.dailyFinished.get(todayString())
  return count || 0
}

export function increaseTodayFinishedPomodoroCount(setting: Setting): number {
  let count = setting.dailyFinished.get(todayString()) || 0
  count = count + 1
  setting.dailyFinished.set(todayString(), count)
  PersistenceV2.save(Setting)
  return count
}

export function makePlainSettingFrom(setting: Setting): Setting {
  return {
    pomodoroSeconds: setting.pomodoroSeconds,
    colorTheme: setting.colorTheme,
    soundThemes: setting.soundThemes,
    pomodorosUntilLongBreak: setting.pomodorosUntilLongBreak,
    pomodoro: setting.pomodoro,
    break: setting.break,
    longBreak: setting.longBreak,
    dailyGoal: setting.dailyGoal,
    vibrate: setting.vibrate,
    autostartBreaks: setting.autostartBreaks,
    autostartPomodoros: setting.autostartPomodoros,
    showLiveView: setting.showLiveView,
    keepPhoneAwake: setting.keepPhoneAwake,
    firstStartApp: setting.firstStartApp,
    dailyFinished: new Map(setting.dailyFinished)
  }
}

export function getPhraseTotalMS(setting: Setting, phrase: Phrase): number {
  switch (phrase) {
    case Phrase.POMODORO:
      return setting.pomodoroSeconds * setting.pomodoro * 1000
    case Phrase.SHORT_BREAK:
      return setting.pomodoroSeconds * setting.break * 1000
    case Phrase.LONG_BREAK:
      return setting.pomodoroSeconds * setting.longBreak * 1000
  }
}

@ObservedV2
export class Setting {
  @Trace pomodoroSeconds: number = 10
  @Trace colorTheme: string = ThemeColors.Coral
  @Trace soundThemes: SoundTheme = SoundTheme.NOTIFICATION
  @Trace pomodorosUntilLongBreak: number = 4
  @Trace pomodoro: number = 1
  @Trace break: number = 1
  @Trace longBreak: number = 3
  @Trace dailyGoal: number = 6
  @Trace vibrate: boolean = true
  @Trace autostartBreaks: boolean = true
  @Trace autostartPomodoros: boolean = true
  @Trace showLiveView: boolean = true
  @Trace keepPhoneAwake: boolean = true
  @Trace firstStartApp: boolean = true
  @Trace dailyFinished: Map<string, number> = new Map()
}