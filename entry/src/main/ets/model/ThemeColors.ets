import { adjustHexColor } from "../utils/ColorUtils"

export class ThemeColors {
  static Coral = "#FFFF5452"
  static LightGreen = "#FFBAD8A2"
  static Turquoise = "#FF7EBDC2"
  static Lavender = "#FF7D8CC5"
  static DarkPurple = "#FF4F3960"
  static Mint = "#FF7DCD84"
  static GrayBlue = "#FF8FA4A7"
  static Sage = "#FF9EC4B5"
  static SeaGreen = "#FF6DC2A3"
  static NavyBlue = "#FF385C76"
  static Teal = "#FF18BEBC"
  static SageGreen = "#FF68A691"
  static Salmon = "#FFF87666"
  static OrangeRed = "#FFFF6F5A"
  static Gold = "#FFD7A954"
  static Crimson = "#FFF03A47"
  static Brown = "#FF8D714C"
  static LightBlue = "#FF9ED0D9"
  static Charcoal = "#FF4A4B4F"
  static Emerald = "#FF35CE8D"
}

export function themeColor(color: string): string {
  return adjustHexColor(color, 1.0032)
}