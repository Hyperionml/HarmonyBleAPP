//camera-worker demo
import { worker } from '@kit.ArkTS';
import { DecodeBusiness } from '../../decoder/DecodeBusiness';
@Entry
@Component
struct CameraWorkerTestPage {
  private mXComponentController: XComponentController = new XComponentController();
  private surfaceId: string = '';
  @State imageWidth: number = 1920;
  @State imageHeight: number = 1080;
  // 创建ThreadWorker对象获取worker实例。
  private workerInstance: worker.ThreadWorker = new worker.ThreadWorker('entry/ets/workers/CameraWorker.ets');
  private uiContext: UIContext = this.getUIContext();
  private context: Context | undefined = this.uiContext.getHostContext();


  onPageShow(): void {
    if ('' !== this.surfaceId) {
      // 通过worker实例向worker线程发送消息初始化相机。
      this.workerInstance.postMessage({
        type: 'initCamera',
        context: this.context,
        surfaceId: this.surfaceId,
      })
    }
  }


  onPageHide(): void {
    // 通过worker实例向worker线程发送消息销毁相机。
    this.workerInstance.postMessage({
      type: 'releaseCamera',
    })
  }


  build() {
    Column() {
      Column() {
        XComponent({
          id: 'componentId',
          type: XComponentType.SURFACE,
          controller: this.mXComponentController
        })
          .onLoad(async () => {
            console.info('onLoad is called');
            // 初始化XComponent获取预览流surfaceId。
            this.surfaceId = this.mXComponentController.getXComponentSurfaceId();
            let surfaceRect: SurfaceRect = {
              surfaceWidth: this.imageHeight,
              surfaceHeight: this.imageWidth
            };
            this.mXComponentController.setXComponentSurfaceRect(surfaceRect);
            console.info(`onLoad surfaceId: ${this.surfaceId}`);
            if (!this.workerInstance) {
              console.error('create stage worker failed');
              return;
            }
            // 宿主线程向worker线程发送初始化相机消息。
            this.workerInstance.postMessage({
              type: 'initCamera',
              context: this.context, // 将宿主线程的context传给worker线程使用。
              surfaceId: this.surfaceId, // 将surfaceId传给worker线程使用。
            })
          })// The width and height of the surface are opposite to those of the XComponent.
          .width(this.uiContext.px2vp(this.imageHeight))
          .height(this.uiContext.px2vp(this.imageWidth))


      }.justifyContent(FlexAlign.Center)
      .height('90%')


      Text('WorkerDemo')
        .fontSize(36)
    }
    .justifyContent(FlexAlign.End)
    .height('100%')
    .width('100%')
  }
}