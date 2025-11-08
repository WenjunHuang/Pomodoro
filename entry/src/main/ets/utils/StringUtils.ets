/**
 * 将带有HTML标签的字符串分解为文本和样式信息的数组
 * @param text - 包含HTML标签的字符串
 * @returns 包含文本和样式信息的对象数组
 */
export interface BoldText {
  content: string;
  isBold: boolean;
}

export function parseHtmlText(text: string): Array<BoldText> {
  // 如果没有HTML标签，直接返回纯文本
  if (!text.includes('<') && !text.includes('>')) {
    return [{ content: text, isBold: false }];
  }

  const result: Array<BoldText> = [];
  let currentIndex = 0;
  let inBoldTag = false;

  while (currentIndex < text.length) {
    // 查找下一个标签的位置
    const openTagIndex = text.indexOf('<b>', currentIndex);
    const closeTagIndex = text.indexOf('</b>', currentIndex);

    // 如果没有更多标签，添加剩余文本
    if (openTagIndex === -1 && closeTagIndex === -1) {
      const remainingText = text.substring(currentIndex);
      if (remainingText) {
        result.push({ content: remainingText, isBold: inBoldTag });
      }
      break;
    }

    // 处理开始标签<b>
    if (openTagIndex !== -1 && (openTagIndex < closeTagIndex || closeTagIndex === -1)) {
      // 添加标签前的文本
      const textBeforeTag = text.substring(currentIndex, openTagIndex);
      if (textBeforeTag) {
        result.push({ content: textBeforeTag, isBold: inBoldTag });
      }
      // 更新状态和索引
      inBoldTag = true;
      currentIndex = openTagIndex + 3; // 跳过<b>标签
    }
    // 处理结束标签</b>
    else if (closeTagIndex !== -1) {
      // 添加标签前的文本
      const textBeforeTag = text.substring(currentIndex, closeTagIndex);
      if (textBeforeTag) {
        result.push({ content: textBeforeTag, isBold: inBoldTag });
      }
      // 更新状态和索引
      inBoldTag = false;
      currentIndex = closeTagIndex + 4; // 跳过</b>标签
    }
  }

  return result;
}