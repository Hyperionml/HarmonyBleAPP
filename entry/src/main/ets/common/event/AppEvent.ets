import { Event,Level } from 'common';
import { AppEventType } from './AppEventType';

export class AppEvent extends Event {
  protected appType: AppEventType;

  constructor(type: AppEventType, level: Level = Level.Common, data?: Object) {
    super(type, level, data);
    this.appType = type;
  }

  getAppType(): AppEventType {
    return this.appType;
  }

  setAppType(type: AppEventType): void {
    this.appType = type;
    this.type = type;
  }

  // 重写父类方法，返回更具体的类型
  getType(): AppEventType {
    return this.appType;
  }
}