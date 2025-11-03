import { IEventReceiver,Event, Logger } from 'common';
import { DeviceEvent } from 'devices';
import { ScanPage } from '../../pages/TestPage/ScanPage';
import { AppEvent } from '../event/AppEvent';
import { AppEventType } from '../event/AppEventType';
import { ScanState } from './ScanState';
import { tag } from '@kit.ConnectivityKit';

// todo 先按照安卓的逻辑迁移，后续改成状态机
const TAG = 'ScanStateMachine';
export class ScanStateMachine implements IEventReceiver {
  //当前状态
  currentState: ScanState = ScanState.IDLE;
  //是否获得权限
  isPremission = false;
  //是否初始化
  initted = false;

  private context: ScanPage;

  constructor(context: ScanPage) {
    this.context = context;
  }

  onEvent(sender: Object|null, event: Event, isAsync: boolean): void {
    const oldState = this.currentState;
    switch (this.currentState) {
      case ScanState.IDLE:
        this.handleIdleState(event);
        break;
      case ScanState.PERMISSION_REQUESTING:
        this.handlePermissionRequestingState(event);
        break;
      case ScanState.INITTING:
        //this.handleCameraInittingState(event);
        break;
      case ScanState.SCANNING:
        //this.handleScanningState(event);
        break;
      case ScanState.WEB_DECODE:
        //this.handleWebDecodeState(event);
        break;
      case ScanState.FLOAT_PANELS_SHOW:
        //有窗口弹出时，专注窗口业务，不处理解码等事件
        break;
      case ScanState.ERROR:
        //this.handleErrorState(event);
        break;
    }
    // 记录状态转换
    if (oldState !== this.currentState) {
      Logger.info(TAG,`状态转换: ${oldState} -> ${this.currentState} (事件: ${(event as AppEvent).getAppType()})`);
    }
  }

  // 状态转换方法
  public transitionTo(newState: ScanState): void {
    this.currentState = newState;
  }

  // 每个状态的处理方法
  private handleIdleState(event: Event): void {
    if(event instanceof AppEvent) {
      const appEvent = event as AppEvent;
      switch (appEvent.getAppType()) {
        case AppEventType.Ready:
          break;
        default:
          break;
      }
    }
    else if(event instanceof DeviceEvent) {

    }
  }

  private handlePermissionRequestingState(event: Event) :void{
    if(event instanceof AppEvent) {
      const appEvent = event as AppEvent;
      switch (appEvent.getAppType()) {
        default:
          break;
      }
    }
  }
}