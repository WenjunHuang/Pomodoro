import { hilog } from '@kit.PerformanceAnalysisKit';

export class Logger {
  private static LOG_DOMAIN = 0xfc99;
  private static LOG_TAG = 'Pomodoro';

  public static info(format: string, ...para: (string | number | boolean | object)[]): void {
    hilog.info(Logger.LOG_DOMAIN, Logger.LOG_TAG, format, ...para);
  }

  public static debug(format: string, ...para: (string | number | boolean | object)[]): void {
    hilog.debug(Logger.LOG_DOMAIN, Logger.LOG_TAG, format, ...para);
  }

  public static warn(format: string, ...para: (string | number | boolean | object)[]): void {
    hilog.warn(Logger.LOG_DOMAIN, Logger.LOG_TAG, format, ...para);
  }

  public static error(format: string, ...para: (string | number | boolean | object)[]): void {
    hilog.error(Logger.LOG_DOMAIN, Logger.LOG_TAG, format, ...para);
  }
}