export class LabelTextStyle implements AttributeModifier<TextAttribute> {
  applyNormalAttribute(instance: TextAttribute): void {
    instance.fontColor(Color.White)
      .fontSize(14)
  }
}