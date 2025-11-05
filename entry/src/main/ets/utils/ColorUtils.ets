// 颜色增亮函数（系数范围1.0-2.0）
function brightenColor(color: number, factor: number): number {
  const alpha = (color >> 24) & 0xFF
  let red = (color >> 16) & 0xFF
  let green = (color >> 8) & 0xFF
  let blue = color & 0xFF

  red = Math.min(0xFF, Math.round(red * factor))
  green = Math.min(0xFF, Math.round(green * factor))
  blue = Math.min(0xFF, Math.round(blue * factor))

  return alpha << 24 | red << 16 | green << 8 | blue
}

// 颜色变暗函数（系数范围0.0-1.0）
function darkenColor(color: number, factor: number): number {
  const alpha = (color >> 24) & 0xFF
  let red = (color >> 16) & 0xFF
  let green = (color >> 8) & 0xFF
  let blue = color & 0xFF

  red = Math.max(0x00, Math.round(red * factor))
  green = Math.max(0x00, Math.round(green * factor))
  blue = Math.max(0x00, Math.round(blue * factor))

  return alpha << 24 | red << 16 | green << 8 | blue
}

export function adjustHexColor(hex: string, factor: number): string {
  const hexWithoutHash = hex.replace(/^#/, '')
  const hasAlpha = hexWithoutHash.length === 8
  
  let value: number
  if (hasAlpha) {
    // 8位格式 #RRGGBBAA
    value = parseInt(hexWithoutHash, 16)
  } else {
    // 6位格式 #RRGGBB，需要添加 alpha = 0xFF (完全不透明)
    value = parseInt(hexWithoutHash, 16) | 0xFF000000
  }
  
  const adjusted = factor > 1 ? brightenColor(value, factor) : darkenColor(value, factor)
  
  // 根据原始格式决定输出长度
  if (hasAlpha) {
    return `#${adjusted.toString(16).padStart(8, '0')}`
  } else {
    // 输出时去掉 alpha 部分
    return `#${(adjusted & 0xFFFFFF).toString(16).padStart(6, '0')}`
  }
}