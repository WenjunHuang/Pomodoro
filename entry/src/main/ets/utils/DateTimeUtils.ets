

export function todayString(): string {
  let d = new Date()
  return `${d.getFullYear()}/${d.getMonth()}/${d.getDay()}`
}