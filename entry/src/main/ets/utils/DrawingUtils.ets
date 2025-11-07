/**
 * 绘制刻度线
 * @param context Canvas上下文
 * @param ticksCount 刻度数量
 * @param tickLength 刻度长度
 * @param color 颜色
 */

/**
 * 绘制圆形扇形
 * @param context Canvas上下文
 * @param startAngle 起始角度
 * @param endAngle 结束角度
 * @param color 颜色
 */
export function drawCircleSector(context: CanvasRenderingContext2D, startAngle: number, endAngle: number,
  color: Color) {
  // 获取Canvas实际绘制尺寸
  const width = context.width
  const height = context.height
  const centerX = width / 2
  const centerY = height / 2
  const radius = Math.min(width, height) / 2 // 取短边为最大半径
  context.clearRect(0, 0, context.width, context.height)

  if (startAngle == endAngle) {
    return
  } else {
    // 扇形参数设置（示例绘制120度扇形）
    const startRad = startAngle * Math.PI / 180 - Math.PI / 2
    const endRad = endAngle * Math.PI / 180 - Math.PI / 2

    // 绘制路径
    context.beginPath()
    context.moveTo(centerX, centerY)
    context.arc(centerX, centerY, radius, startRad, endRad)
    context.closePath()

    // 填充样式设置
    context.fillStyle = color.toString() // 设置填充颜色
    context.fill()
  }
}

export function drawTicks(context: CanvasRenderingContext2D, ticksCount: number, tickLength: number, drawLength: number,
  color: Color) {
  // 获取Canvas实际绘制尺寸
  const width = context.width
  const height = context.height
  const centerX = width / 2
  const centerY = height / 2
  const radius = Math.min(width, height) / 2 // 取短边为最大半径
  if (ticksCount <= 0) {
    return
  }

  context.clearRect(0, 0, width, height)

  context.beginPath()
  for (let index = 0; index < ticksCount; index++) {
    const theta = index * (2 * Math.PI / ticksCount)
    const fromX = centerX - (radius - tickLength) * Math.sin(theta)
    const fromY = centerY - (radius - tickLength) * Math.cos(theta)
    const toX = centerX - (radius - tickLength + drawLength) * Math.sin(theta)
    const toY = centerY - (radius - tickLength + drawLength) * Math.cos(theta)
    context.moveTo(fromX, fromY)
    context.lineTo(toX, toY)
  }
  context.closePath()

  // 填充样式设置
  context.lineWidth = 2
  context.strokeStyle = color.toString() // 设置填充颜色
  context.stroke()
}
