import { BusinessError } from '@kit.BasicServicesKit';
import { Event } from './Event';
import { IEventReceiver } from './IEventReceiver';
import { Level } from './Level';
/**
 *  -
 │  - 管理事件接收器的注册和注销
 │  - 按优先级分发事件 (High/Common/Low)
 │  - 支持同步和异步事件发送
 │  - 提供事件中断机制
 *  -
 */
export class EventManager {
  private static instance: EventManager | null = null;
  private mutex = Promise.resolve();

  private highReceiverList: IEventReceiver[] = [];
  private commonReceiverList: IEventReceiver[] = [];
  private lowReceiverList: IEventReceiver[] = [];

  private constructor() {}

  static init(): void {
    if (EventManager.instance === null) {
      EventManager.instance = new EventManager();
    }
  }

  static attach(receiver: IEventReceiver, level: Level): void {
    if (EventManager.instance === null) {
      EventManager.init();
    }
    EventManager.instance!.attachPrivate(receiver, level);
  }

  static detach(receiver: IEventReceiver): void {
    if (EventManager.instance !== null) {
      EventManager.instance.detachPrivate(receiver);
    }
  }

  static async(sender: Object | null, event: Event): void {
    if (EventManager.instance !== null) {
      EventManager.instance.asyncPrivate(sender, event);
    }
  }

  static sync(sender: Object, event: Event): void {
    if (EventManager.instance !== null) {
      EventManager.instance.syncPrivate(sender, event);
    }
  }

  static destroy(): void {
    if (EventManager.instance !== null) {
      EventManager.instance.destroyPrivate();
      EventManager.instance = null;
    }
  }

  private async executeWithLock<T>(operation: () => T): Promise<T> {
    await this.mutex;
    this.mutex = new Promise<void>((resolve) => {
      try {
        const result = operation();
        resolve();
        return result;
      } catch (error) {
        resolve();
        throw error as Error;
      }
    });
    return this.mutex as Promise<T>;
  }

  private async attachPrivate(receiver: IEventReceiver, level: Level): Promise<void> {
    await this.executeWithLock(() => {
      const list = this.getList(level);

      // 高级接收器数量限制
      if (level === Level.High && list.length >= 3) {
        throw new Error('高级接收器数量不能超过3个');
      }

      if (!list.includes(receiver)) {
        list.push(receiver);
      }
    });
  }

  private async detachPrivate(receiver: IEventReceiver): Promise<void> {
    await this.executeWithLock(() => {
      [this.highReceiverList, this.commonReceiverList, this.lowReceiverList]
        .forEach(list => {
          const index = list.indexOf(receiver);
          if (index > -1) {
            list.splice(index, 1);
          }
        });
    });
  }

  private asyncPrivate(sender: object | null, event: Event): void {
    try {
      Promise.resolve().then(async () => {
        await this.send(sender, event, true);
      }).catch((error:BusinessError) => {
        console.error('异步消息处理失败:', error);
      });
    } catch (error) {
      console.error('异步消息处理失败:', error);
    }
  }

  private async syncPrivate(sender: Object, event: Event): Promise<void> {
    await this.send(sender, event, false);
  }

  private async send(sender: object | null, event: Event, isAsync: boolean): Promise<void> {
    await this.executeWithLock(() => {
      switch (event.getLevel()) {
        case Level.High:
          this.sendToList(sender, event, isAsync, this.highReceiverList);
          break;
        case Level.Common:
          if (this.sendToList(sender, event, isAsync, this.highReceiverList)) {
            this.sendToList(sender, event, isAsync, this.commonReceiverList);
          }
          break;
        case Level.Low:
          if (this.sendToList(sender, event, isAsync, this.highReceiverList)) {
            if (this.sendToList(sender, event, isAsync, this.commonReceiverList)) {
              this.sendToList(sender, event, isAsync, this.lowReceiverList);
            }
          }
          break;
      }
    });
  }

  private sendToList(sender: object | null, event: Event, isAsync: boolean, list: IEventReceiver[]): boolean {
    if (list.length === 0) return true;

    for (const receiver of list) {
      try {
        receiver.onEvent(sender, event, isAsync);
        if (event.isStoped()) {
          return false;
        }
      } catch (error) {
        console.error('事件处理器执行失败:', error);
      }
    }
    return true;
  }

  private getList(level: Level): IEventReceiver[] {
    switch (level) {
      case Level.High:
        return this.highReceiverList;
      case Level.Common:
        return this.commonReceiverList;
      case Level.Low:
        return this.lowReceiverList;
      default:
        throw new Error('不支持的事件级别');
    }
  }

  private async destroyPrivate(): Promise<void> {
    await this.executeWithLock(() => {
      this.highReceiverList.length = 0;
      this.commonReceiverList.length = 0;
      this.lowReceiverList.length = 0;
    });
  }
}