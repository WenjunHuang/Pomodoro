

/**
 * 将整数转换为指定长度的字符串，不足的前面补充0
 * @param num - 要转换的整数
 * @param length - 目标字符串长度
 * @returns 指定长度的字符串
 */
export function padNumber(num: number, length: number): string {
  return num.toString().padStart(length, '0')
}

/**
 * 计算剩余的分钟数
 * @param elapsedMS - 已经过的时间（毫秒）
 * @param totalMS - 总时间（毫秒）
 * @returns 剩余的分钟数
 */
export function remainingMinutes(elapsedMS:number,totalMS:number):number {
  const remainingMS = totalMS - elapsedMS
  return Math.floor(remainingMS / 60000)
}

/**
 * 计算除去分钟后的剩余秒数
 * @param elapsedMS - 已经过的时间（毫秒）
 * @param totalMS - 总时间（毫秒）
 * @returns 除去分钟后的剩余秒数
 */
export function remainingSecondsWithoutMinutes(elapsedMS:number,totalMS:number):number {
  const remainingMS = totalMS - elapsedMS
  const seconds = Math.ceil(remainingMS / 1000)
  return seconds % 60
}

export function toMinuteSecondString(time:number):string {
  let minutes = Math.floor(time / 60000)
  let seconds = Math.ceil(time / 1000) % 60

  return `${minutes.toString().padStart(2,"0")}:${seconds.toString().padStart(2,"0")}`
}

export function todayString(): string {
  let d = new Date()
  return `${d.getFullYear()}/${d.getMonth()}/${d.getDay()}`
}
