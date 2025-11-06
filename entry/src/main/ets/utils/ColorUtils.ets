// 调整颜色亮度
// 输入格式：支持 #AARRGGBB 或 #RRGGBB
// 输出格式：与输入格式保持一致
export function adjustHexColor(hex: string, factor: number): string {
  const hexWithoutHash = hex.replace(/^#/, '')
  const hasAlpha = hexWithoutHash.length === 8
  
  let alpha: string
  let red: string
  let green: string
  let blue: string
  
  if (hasAlpha) {
    // 8位格式 #AARRGGBB
    alpha = hexWithoutHash.substring(0, 2)
    red = hexWithoutHash.substring(2, 4)
    green = hexWithoutHash.substring(4, 6)
    blue = hexWithoutHash.substring(6, 8)
  } else {
    // 6位格式 #RRGGBB
    red = hexWithoutHash.substring(0, 2)
    green = hexWithoutHash.substring(2, 4)
    blue = hexWithoutHash.substring(4, 6)
    alpha = "FF"
  }
  
  // 调整 RGB 值
  let redValue = parseInt(red, 16)
  let greenValue = parseInt(green, 16)
  let blueValue = parseInt(blue, 16)
  
  if (factor > 1) {
    // 增亮
    redValue = Math.min(0xFF, Math.round(redValue * factor))
    greenValue = Math.min(0xFF, Math.round(greenValue * factor))
    blueValue = Math.min(0xFF, Math.round(blueValue * factor))
  } else {
    // 变暗
    redValue = Math.max(0x00, Math.round(redValue * factor))
    greenValue = Math.max(0x00, Math.round(greenValue * factor))
    blueValue = Math.max(0x00, Math.round(blueValue * factor))
  }
  
  // 组合结果
  const adjustedRed = redValue.toString(16).padStart(2, '0').toUpperCase()
  const adjustedGreen = greenValue.toString(16).padStart(2, '0').toUpperCase()
  const adjustedBlue = blueValue.toString(16).padStart(2, '0').toUpperCase()
  
  if (hasAlpha) {
    return `#${alpha}${adjustedRed}${adjustedGreen}${adjustedBlue}`
  } else {
    return `#${adjustedRed}${adjustedGreen}${adjustedBlue}`
  }
}

// 计算 disabled 颜色（通过透明度处理）
// 输入格式：支持 #AARRGGBB 或 #RRGGBB
// 输出格式：始终返回 #AARRGGBB（因为 disabled 状态需要透明度）
// 默认透明度为 0x66 (约 40% 不透明度)，可通过 alpha 参数自定义
export function getDisabledColor(hex: string, alpha: number = 0x66): string {
  const hexWithoutHash = hex.replace(/^#/, '')
  
  // 提取 RGB 值
  let red: string
  let green: string
  let blue: string
  
  if (hexWithoutHash.length === 8) {
    // 8位格式 #AARRGGBB，提取 RGB 部分（去掉 alpha）
    red = hexWithoutHash.substring(2, 4)
    green = hexWithoutHash.substring(4, 6)
    blue = hexWithoutHash.substring(6, 8)
  } else if (hexWithoutHash.length === 6) {
    // 6位格式 #RRGGBB
    red = hexWithoutHash.substring(0, 2)
    green = hexWithoutHash.substring(2, 4)
    blue = hexWithoutHash.substring(4, 6)
  } else {
    throw new Error(`Invalid hex color format: ${hex}. Expected #AARRGGBB or #RRGGBB`)
  }
  
  // 确保 alpha 值在有效范围内 (0x00 - 0xFF)
  const alphaValue = Math.max(0x00, Math.min(0xFF, Math.round(alpha)))
  const alphaHex = alphaValue.toString(16).padStart(2, '0').toUpperCase()
  
  // 组合 alpha 和 RGB 值，返回 8 位格式 #AARRGGBB
  return `#${alphaHex}${red}${green}${blue}`
}