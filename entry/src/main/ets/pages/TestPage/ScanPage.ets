import { EventManager,Level,IEventReceiver,Event } from 'common';
import { AppEvent } from '../../common/event/AppEvent';
import { AppEventType } from '../../common/event/AppEventType';
import { DecodeBusiness } from '../../decoder/DecodeBusiness';
import { BasePage } from '../../component/Page/BasePage';
import { common } from '@kit.AbilityKit';
import display from '@ohos.display';
import { ScanStateMachine } from '../../common/state/ScanStateMachine';
import { ScanState } from '../../common/state/ScanState';
import { MessageEvents, worker } from '@kit.ArkTS';

@Entry
@Component
export struct ScanPage {
  @State message: string = 'Hello World';

  @State imageWidth: number = 1920;
  @State imageHeight: number = 1080;

  private mXComponentController: XComponentController = new XComponentController();
  private mXComponentSurfaceId : string = '';
  public getMXComponentSurfaceId(){ return this.mXComponentSurfaceId }
  private surfaceId: string = '';
  private mDecodeBusiness : DecodeBusiness | null = null;
  public getDecodeBusiness(){ return this.mDecodeBusiness }
  private uiContext: UIContext = this.getUIContext();
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  //状态机
  private scanStateMachine : ScanStateMachine | null = null;

  private mReceiver: IEventReceiver = {
    onEvent: (sender: Object|null, event: Event, isAsync: boolean): void => {
      if (event instanceof AppEvent) {
        const appEvent = event as AppEvent;
        switch (appEvent.getAppType()) {
          case AppEventType.WaitingMask:
          case AppEventType.StartScan:
          case AppEventType.StopScan:
          case AppEventType.CameraStateEvents:
            this.handleEvent(sender, appEvent, isAsync);
            break;
          case AppEventType.Permission:
            if(this.mDecodeBusiness && this.mXComponentSurfaceId && event.getData() == true){
              if(this.mDecodeBusiness.startCamera(2.2) && this.scanStateMachine){
                  this.scanStateMachine.transitionTo(ScanState.SCANNING);
              }
            }
            break;
        }
      }
    }
  };

  public handleEvent(sender: Object|null, event: Event, isAsync: boolean) {
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

  StateMachineTest(){
    console.log('状态机调用页面方法');
  }

  aboutToAppear() {
    // 获取屏幕宽高（px）
    let displayInfo = display.getDefaultDisplaySync();
    // 根据屏幕方向调整宽高
    if (displayInfo.orientation === display.Orientation.PORTRAIT) {
      // 竖屏：宽小高大
      this.imageWidth = Math.min(displayInfo.width, displayInfo.height);
      this.imageHeight = Math.max(displayInfo.width, displayInfo.height);
    } else {
      // 横屏：宽大高小
      this.imageWidth = Math.max(displayInfo.width, displayInfo.height);
      this.imageHeight = Math.min(displayInfo.width, displayInfo.height);
    }

    this.mDecodeBusiness = new DecodeBusiness(this.context, this.mXComponentSurfaceId);

    // 初始化EventManager
    EventManager.init();
    // 注册事件接收器
    // EventManager.attach(this.mReceiver, Level.High);
    // 状态机
    this.scanStateMachine = new ScanStateMachine(this);
    EventManager.attach(this.scanStateMachine, Level.High);


    // 授权
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    // BasePage.reqPermissionsFromUser(['ohos.permission.CAMERA'], context,()=>{
    //   EventManager.sync(this,new AppEvent(AppEventType.Permission,Level.High,true))
    // });

    console.log('EventTestPage aboutToAppear');
  }

  onPageShow() {
    //缩放
    const forceZoom = 2.2;
    //启动相机
    // if(this.mDecodeBusiness){
    //   if(this.mDecodeBusiness.startCamera(forceZoom) && this.scanStateMachine){
    //     this.scanStateMachine.transitionTo(ScanState.CAMERA_RUNNING);
    //   }
    // }
    console.log('EventTestPage onPageShow');
  }

  onPageHide() {
    console.log('EventTestPage onPageHide');
  }

  aboutToDisappear() {
    EventManager.destroy();
    console.log('EventTestPage aboutToDisappear');
  }

  build() {
    Column() {
      XComponent({
        id: 'componentId',
        type: XComponentType.SURFACE,
        controller: this.mXComponentController
      })
        .onLoad(async () => {
          console.info('onLoad is called');
          this.mXComponentSurfaceId = this.mXComponentController.getXComponentSurfaceId(); // 获取组件surfaceId。

          let surfaceRect: SurfaceRect = {
            surfaceWidth: this.imageWidth,
            surfaceHeight: this.imageHeight
          };
          this.mXComponentController.setXComponentSurfaceRect(surfaceRect);

          // 初始化相机，组件实时渲染每帧预览流数据。
          // if(this.mDecodeBusiness)
          //   this.mDecodeBusiness.startCamera(this.mXComponentSurfaceId);
        })
        .width(this.uiContext.px2vp(this.imageWidth))
        .height(this.uiContext.px2vp(this.imageHeight))
        .backgroundColor(Color.Black)
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Color.Gray)
  }

  onBackPress() {
    this.message = 'Color.Red';
    console.info('IndexComponent onBackPress');
    return false
  }
}