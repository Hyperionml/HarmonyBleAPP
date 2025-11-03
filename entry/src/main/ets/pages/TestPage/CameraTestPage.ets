import { camera } from '@kit.CameraKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';

//双路预览
@Entry
@Component
struct CameraTestPage {
  private imageReceiver: image.ImageReceiver | undefined = undefined;
  private imageReceiverSurfaceId: string = '';
  private xComponentCtl: XComponentController = new XComponentController();
  private xComponentSurfaceId: string = '';
  @State imageWidth: number = 1920;
  @State imageHeight: number = 1080;
  private cameraManager: camera.CameraManager | undefined = undefined;
  private cameras: Array<camera.CameraDevice> | Array<camera.CameraDevice> = [];
  private cameraInput: camera.CameraInput | undefined = undefined;
  private previewOutput1: camera.PreviewOutput | undefined = undefined;
  private previewOutput2: camera.PreviewOutput | undefined = undefined;
  private session: camera.VideoSession | undefined = undefined;
  private uiContext: UIContext = this.getUIContext();
  private context: Context | undefined = this.uiContext.getHostContext();
  private cameraPermission: Permissions = 'ohos.permission.CAMERA'; // 申请权限相关问题可参考本篇开头的申请相关权限文档
  @State isShow: boolean = false;


  async requestPermissionsFn(): Promise<void> {
    let atManager = abilityAccessCtrl.createAtManager();
    if (this.context) {
      let res = await atManager.requestPermissionsFromUser(this.context, [this.cameraPermission]);
      for (let i =0; i < res.permissions.length; i++) {
        if (this.cameraPermission.toString() === res.permissions[i] && res.authResults[i] === 0) {
          this.isShow = true;
        }
      }
    }
  }


  aboutToAppear(): void {
    this.requestPermissionsFn();
  }


  onPageShow(): void {
    console.info('onPageShow');
    this.initImageReceiver();
    if (this.xComponentSurfaceId !== '') {
      this.initCamera();
    }
  }


  onPageHide(): void {
    console.info('onPageHide');
    this.releaseCamera();
  }


  /**
   * 获取ImageReceiver的SurfaceId
   * @param receiver
   * @returns
   */
  async initImageReceiver(): Promise<void> {
    if (!this.imageReceiver) {
      // 创建ImageReceiver。
      let size: image.Size = { width: this.imageWidth, height: this.imageHeight };
      this.imageReceiver = image.createImageReceiver(size, image.ImageFormat.JPEG, 8);
      // 获取取第一路流SurfaceId。
      this.imageReceiverSurfaceId = await this.imageReceiver.getReceivingSurfaceId();
      console.info(`initImageReceiver imageReceiverSurfaceId:${this.imageReceiverSurfaceId}`);
      // 注册监听处理预览流每帧图像数据。
      this.onImageArrival(this.imageReceiver);
    }
  }


  // Image格式与PixelMap格式映射关系。
  private formatToPixelMapFormatMap = new Map<number, image.PixelMapFormat>([
    [12, image.PixelMapFormat.RGBA_8888],
    [25, image.PixelMapFormat.NV21],
    [35, image.PixelMapFormat.YCBCR_P010],
    [36, image.PixelMapFormat.YCRCB_P010]
  ]);
  // PixelMapFormat格式的单个像素点大小映射关系。
  private pixelMapFormatToSizeMap = new Map<image.PixelMapFormat, number>([
    [image.PixelMapFormat.RGBA_8888, 4],
    [image.PixelMapFormat.NV21, 1.5],
    [image.PixelMapFormat.YCBCR_P010, 3],
    [image.PixelMapFormat.YCRCB_P010, 3]
  ]);


  /**
   * 注册ImageReceiver图像监听
   * @param receiver
   */
  onImageArrival(receiver: image.ImageReceiver): void {
    // 注册imageArrival监听。
    receiver.on('imageArrival', () => {
      console.info('image arrival');
      // 获取图像。
      receiver.readNextImage((err: BusinessError, nextImage: image.Image) => {
        if (err || nextImage === undefined) {
          console.error('readNextImage failed');
          return;
        }
        // 解析图像内容。
        nextImage.getComponent(image.ComponentType.JPEG, async (err: BusinessError, imgComponent: image.Component) => {
          if (err || imgComponent === undefined) {
            console.error('getComponent failed');
          }
          if (imgComponent.byteBuffer) {
            // 请参考步骤7解析buffer数据，本示例以方式一为例。
            let width = nextImage.size.width; // 获取图片的宽。
            let height = nextImage.size.height; // 获取图片的高。
            let stride = imgComponent.rowStride; // 获取图片的stride。
            let imageFormat = nextImage.format; // 获取图片的format。
            let pixelMapFormat = this.formatToPixelMapFormatMap.get(imageFormat) ?? image.PixelMapFormat.NV21;
            let mSize =  this.pixelMapFormatToSizeMap.get(pixelMapFormat) ?? 1.5;
            console.debug(`getComponent with width:${width} height:${height} stride:${stride}`);
            // pixelMap创建时使用的size、srcPixelFormat需要与相机预览输出流previewProfile中的size、format保持一致。此处format以NV21格式为例。
            // stride与width一致。
            if (stride == width) {
              let pixelMap = await image.createPixelMap(imgComponent.byteBuffer, {
                size: { height: height, width: width },
                srcPixelFormat: pixelMapFormat,
              })
            } else {
              // stride与width不一致。
              const dstBufferSize = width * height * mSize // 以NV21为例（YUV_420_SP格式的图片）YUV_420_SP内存计算公式：长x宽+(长x宽)/2。
              const dstArr = new Uint8Array(dstBufferSize)
              for (let j = 0; j < height * mSize; j++) {
                const srcBuf = new Uint8Array(imgComponent.byteBuffer, j * stride, width)
                dstArr.set(srcBuf, j * width)
              }
              let pixelMap = await image.createPixelMap(dstArr.buffer, {
                size: { height: height, width: width },
                srcPixelFormat: pixelMapFormat,
              })
            }
          } else {
            console.error('byteBuffer is null');
          }
          // 确保当前buffer没有在使用的情况下，可进行资源释放。
          // 如果对buffer进行异步操作，需要在异步操作结束后再释放该资源（nextImage.release()）。
          nextImage.release();
          console.info('image process done');
        })
      })
    })
  }


  build() {
    Column() {
      if (this.isShow) {
        Text(this.imageWidth.toString())
        Text(this.imageHeight.toString())
        XComponent({
          id: 'componentId',
          type: XComponentType.SURFACE,
          controller: this.xComponentCtl
        })
          .onLoad(async () => {
            console.info('onLoad is called');
            this.xComponentSurfaceId = this.xComponentCtl.getXComponentSurfaceId(); // 获取组件surfaceId。
            // 初始化相机，组件实时渲染每帧预览流数据。
            this.initCamera()
          })
          .width(this.uiContext.px2vp(this.imageHeight))
          .height(this.uiContext.px2vp(this.imageWidth))
      }
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }


  // 初始化相机。
  async initCamera(): Promise<void> {
    console.info(`initCamera imageReceiverSurfaceId:${this.imageReceiverSurfaceId} xComponentSurfaceId:${this.xComponentSurfaceId}`);
    try {
      // 获取相机管理器实例。
      this.cameraManager = camera.getCameraManager(this.context);
      if (!this.cameraManager) {
        console.error('initCamera getCameraManager');
      }
      // 获取当前设备支持的相机device列表。
      this.cameras = this.cameraManager.getSupportedCameras();
      if (!this.cameras) {
        console.error('initCamera getSupportedCameras');
      }
      // 选择一个相机device，创建cameraInput输出对象。
      this.cameraInput = this.cameraManager.createCameraInput(this.cameras[0]);
      if (!this.cameraInput) {
        console.error('initCamera createCameraInput');
      }
      // 打开相机。
      await this.cameraInput.open().catch((err: BusinessError) => {
        console.error(`initCamera open fail: ${err}`);
      })
      // 获取相机device支持的profile。
      let capability: camera.CameraOutputCapability =
        this.cameraManager.getSupportedOutputCapability(this.cameras[0], camera.SceneMode.NORMAL_VIDEO);
      if (!capability) {
        console.error('initCamera getSupportedOutputCapability');
      }
      let minRatioDiff : number = 0.1;
      let surfaceRatio : number = this.imageWidth / this.imageHeight; // 最接近16:9宽高比。
      let previewProfile: camera.Profile = capability.previewProfiles[0];
      // 应用开发者根据实际业务需求选择一个支持的预览流previewProfile。
      // 此处以选择CAMERA_FORMAT_YUV_420_SP（NV21）格式、满足限定条件条件分辨率的预览流previewProfile为例。
      for (let index = 0; index < capability.previewProfiles.length; index++) {
        const tempProfile = capability.previewProfiles[index];
        let tempRatio = tempProfile.size.width >= tempProfile.size.height ?
          tempProfile.size.width / tempProfile.size.height : tempProfile.size.height / tempProfile.size.width;
        //寻找比例相近的
        let currentRatio = Math.abs(tempRatio - surfaceRatio);
        //模拟器只有一个format CAMERA_FORMAT_RGBA_8888
        if (currentRatio <= minRatioDiff && tempProfile.format == camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP) {
          previewProfile = tempProfile;
          break;
        }
      }
      this.imageWidth = previewProfile.size.width; // 更新xComponent组件的宽。
      this.imageHeight = previewProfile.size.height; // 更新xComponent组件的高。
      console.info(`initCamera imageWidth:${this.imageWidth} imageHeight:${this.imageHeight}`);
      // 使用imageReceiverSurfaceId创建第一路预览。
      this.previewOutput1 = this.cameraManager.createPreviewOutput(previewProfile, this.imageReceiverSurfaceId);
      if (!this.previewOutput1) {
        console.error('initCamera createPreviewOutput1');
      }
      // 使用xComponentSurfaceId创建第二路预览。
      this.previewOutput2 = this.cameraManager.createPreviewOutput(previewProfile, this.xComponentSurfaceId);
      if (!this.previewOutput2) {
        console.error('initCamera createPreviewOutput2');
      }
      // 创建录像模式相机会话。
      this.session = this.cameraManager.createSession(camera.SceneMode.NORMAL_VIDEO) as camera.VideoSession;
      if (!this.session) {
        console.error('initCamera createSession');
      }
      // 开始配置会话。
      this.session.beginConfig();
      // 添加相机设备输入。
      this.session.addInput(this.cameraInput);
      // 添加第一路预览流输出。
      this.session.addOutput(this.previewOutput1);
      // 添加第二路预览流输出。
      this.session.addOutput(this.previewOutput2);
      // 提交会话配置。
      await this.session.commitConfig();
      // 开始启动已配置的输入输出流。
      await this.session.start();
    } catch (error) {
      console.error(`initCamera fail: ${error}`);
    }
  }


  // 释放相机。
  async releaseCamera(): Promise<void> {
    console.info('releaseCamera E');
    try {
      // 停止当前会话。
      await this.session?.stop();
      // 释放相机输入流。
      await this.cameraInput?.close();
      // 释放预览输出流。
      await this.previewOutput1?.release();
      // 释放拍照输出流。
      await this.previewOutput2?.release();
      // 释放会话。
      await this.session?.release();
    } catch (error) {
      console.error(`initCamera fail: ${error}`);
    }
  }
}