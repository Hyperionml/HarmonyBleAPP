import { IEventReceiver,Event } from 'common';
import { AppEvent } from '../common/event/AppEvent';
import { AppEventType } from '../common/event/AppEventType';
import { EventTestPage }  from '../pages/TestPage/EventTestPage'
export class EventTestPageReceiver implements IEventReceiver {
  private context: EventTestPage;

  constructor(context: EventTestPage) {
    this.context = context;
  }

  onEvent(sender: Object|null, event: Event, isAsync: boolean): void {
    if (event instanceof AppEvent) {
      const appEvent = event as AppEvent;

      switch (appEvent.getAppType()) {
        case AppEventType.WaitingMask:
        case AppEventType.StartScan:
        case AppEventType.StopScan:
          this.handleEvent(sender, appEvent, isAsync);
          break;
      }
    }
  }

  private handleEvent(sender: Object|null, event: Event, isAsync: boolean) {
    if (event instanceof AppEvent) {
      const appEvent = event as AppEvent;
      // 模拟一些处理时间
      let processingTime = Date.now();
      while (Date.now() - processingTime < 50) {
        // 模拟50ms的处理时间
      }
      console.log(`接收到事件: ${appEvent.getAppType()}, 异步: ${isAsync}`);
    }
  }
}