import { todayString } from '../utils/DateTimeUtils'
import { ThemeColors } from './ThemeColors'
import { PersistenceV2 } from '@kit.ArkUI'

export enum SoundTheme {
  NOTIFICATION,
  ALARM
}

@ObservedV2
export class Setting {
  @Trace pomodoroSeconds: number = 10
  @Trace pomodoro: number = 1
  @Trace break: number = 1
  @Trace longBreak: number = 3
  @Trace colorTheme: string = ThemeColors.Coral
  @Trace soundThemes: SoundTheme = SoundTheme.NOTIFICATION
  @Trace pomodorosUntilLongBreak: number = 4
  @Trace dailyGoal: number = 6
  @Trace vibrate: boolean = true
  @Trace autostartBreaks: boolean = true
  @Trace autostartPomodoros: boolean = true
  @Trace showLiveView: boolean = true
  @Trace keepPhoneAwake: boolean = true
  @Trace firstStartApp: boolean = true
  @Trace dailyFinished: Map<string, number> = new Map()

  todayFinishedPomodoroCount(): number {
    let count = this.dailyFinished.get(todayString())
    return count || 0
  }

  increaseTodayFinishedPomodoroCount():number {
    let count = this.dailyFinished.get(todayString()) || 0
    count = count + 1
    this.dailyFinished.set(todayString(),count)
    PersistenceV2.save(Setting)
    return count
  }
}