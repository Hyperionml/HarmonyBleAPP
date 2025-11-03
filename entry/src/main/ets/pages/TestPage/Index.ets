import { camera } from '@kit.CameraKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

class MyXComponentController extends XComponentController {
  onSurfaceCreated(surfaceId: string): void {
    console.log(`onSurfaceCreated surfaceId: ${surfaceId}`)
  }

  onSurfaceChanged(surfaceId: string, rect: SurfaceRect): void {
    console.log(`onSurfaceChanged surfaceId: ${surfaceId}, rect: ${JSON.stringify(rect)}}`)
  }

  onSurfaceDestroyed(surfaceId: string): void {
    console.log(`onSurfaceDestroyed surfaceId: ${surfaceId}`)
  }
}

@Entry
@Component
struct Index {
  @State message: string = '';

  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private mCameraDevice : camera.CameraDevice | null = null;
  private mCameraManager : camera.CameraManager | null = null;

  @State currentStatus: string = "index";
  xComponentController: XComponentController = new XComponentController();

  aboutToAppear(){
    this.mCameraManager = camera.getCameraManager(this.context);
    let cameraArray: Array<camera.CameraDevice> = this.mCameraManager.getSupportedCameras();
    if (cameraArray != undefined && cameraArray.length > 0) {
      for (let index = 0; index < cameraArray.length; index++) {
        let iCamera = cameraArray[index];
        console.info('相机ID : ' + iCamera.cameraId);  // 获取相机ID。
        switch (iCamera.cameraPosition){
          case camera.CameraPosition.CAMERA_POSITION_BACK:
            console.info('相机位置 : 后置相机');
            break;
          case camera.CameraPosition.CAMERA_POSITION_FRONT:
            console.info('相机位置 : 前置相机');
            break;
        }
        switch (iCamera.cameraType){
          case camera.CameraType.CAMERA_TYPE_DEFAULT:
            console.info('相机类型 : 相机类型未指定');
            break;
          case camera.CameraType.CAMERA_TYPE_WIDE_ANGLE:
            console.info('相机类型 : 广角相机');
            break;
          case camera.CameraType.CAMERA_TYPE_ULTRA_WIDE:
            console.info('相机类型 : 超广角相机');
            break;
          case camera.CameraType.CAMERA_TYPE_TELEPHOTO:
            console.info('相机类型 : 长焦相机');
            break;
          case camera.CameraType.CAMERA_TYPE_TRUE_DEPTH:
            console.info('相机类型 : 带景深信息的相机');
            break;

        }
        console.info('相机连接类型 : ' + iCamera.connectionType);  // 获取相机连接类型。
        console.info('相机安装角度 : ' + iCamera.cameraOrientation); // 获取相机安装角度。(通常后置似乎90，前置是270)
        console.info('-------------------------');
      }
    }

    this.mCameraManager.on('cameraStatus', (err: BusinessError, cameraStatusInfo: camera.CameraStatusInfo) => {
      if (err !== undefined && err.code !== 0) {
        console.error(`Callback Error, errorCode: ${err.code}`);
        return;
      }
      // 如果当通过USB连接相机设备时，回调函数会返回新的相机出现状态。
      if (cameraStatusInfo.status == camera.CameraStatus.CAMERA_STATUS_APPEAR) {
        console.info(`相机状态监听 ：New Camera device appear.`);
      }
      // 如果当断开相机设备USB连接时，回调函数会返回相机被移除状态。
      if (cameraStatusInfo.status == camera.CameraStatus.CAMERA_STATUS_DISAPPEAR) {
        console.info(`相机状态监听 ：Camera device has been removed.`);
      }
      // 相机被关闭时，回调函数会返回相机可用状态。
      if (cameraStatusInfo.status == camera.CameraStatus.CAMERA_STATUS_AVAILABLE) {
        console.info(`相机状态监听 ：Current Camera is available.`);
      }
      // 相机被打开/占用时，回调函数会返回相机不可用状态。
      if (cameraStatusInfo.status == camera.CameraStatus.CAMERA_STATUS_UNAVAILABLE) {
        console.info(`相机状态监听 ：Current Camera has been occupied.`);
      }
      console.info(`相机状态监听 ：camera: ${cameraStatusInfo.camera.cameraId}`);
      console.info(`相机状态监听 ：status: ${cameraStatusInfo.status}`);
    });

    this.mCameraDevice = cameraArray.filter(fCamera => {
      return fCamera.cameraPosition == camera.CameraPosition.CAMERA_POSITION_BACK
        && (fCamera.cameraType == camera.CameraType.CAMERA_TYPE_WIDE_ANGLE ||  fCamera.cameraType == camera.CameraType.CAMERA_TYPE_DEFAULT)})[0];
    //this.openCamera(cameraArray[1],cameraManager)
    // 获取相机设备支持的模式列表。
    let sceneModeArray: Array<camera.SceneMode> = this.mCameraManager.getSupportedSceneModes(this.mCameraDevice);
  }

  async openCamera(cameraDevice: camera.CameraDevice, cameraManager: camera.CameraManager){
    // 创建相机输入流。
    let cameraInput: camera.CameraInput | undefined = undefined;
    try {
      cameraInput = cameraManager.createCameraInput(cameraDevice);
    } catch (error) {
      let err = error as BusinessError;
      console.error('Failed to createCameraInput errorCode = ' + err.code);
    }
    if (cameraInput === undefined) return;
    // 监听cameraInput错误信息。
    cameraInput.on('error', cameraDevice, (error: BusinessError) => {
      console.error(`Camera input error code: ${error.code}`);
    });
    // 打开相机。
    console.info(`即将打开相机`);
    await cameraInput.open();

    // 获取相机设备支持的输出流能力。
    let cameraOutputCapability: camera.CameraOutputCapability = cameraManager.getSupportedOutputCapability(cameraDevice, camera.SceneMode.NORMAL_VIDEO);//普通录像模式
    // previewProfiles属性为获取当前设备支持的预览输出流。
    let previewProfilesArray: Array<camera.Profile> = cameraOutputCapability.previewProfiles;
    // videoProfiles属性为获取当前设备支持的录像输出流。
    let videoProfilesArray: Array<camera.Profile> = cameraOutputCapability.videoProfiles;
    let surfaceId = this.xComponentController.getXComponentSurfaceId()
    let previewOutput: camera.PreviewOutput = cameraManager.createPreviewOutput(previewProfilesArray[0], surfaceId);
    // 输出监听
    previewOutput.on('frameStart', (err: BusinessError) => {
      if (err !== undefined && err.code !== 0) {
        return;
      }
      console.info('Preview frame started');
    });
    previewOutput.on('frameEnd', (err: BusinessError) => {
      if (err !== undefined && err.code !== 0) {
        return;
      }
      console.info('Preview frame ended');
    });
    previewOutput.on('error', (previewOutputError: BusinessError) => {
      console.error(`Preview output error code: ${previewOutputError.code}`);
    });

    // 会话
    let session: camera.PhotoSession = cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO) as camera.PhotoSession;
    session.beginConfig();
    session.addInput(cameraInput);
    session.addOutput(previewOutput);
    await session.commitConfig();
    await session.start();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      XComponent({
        type: XComponentType.SURFACE,
        controller: this.xComponentController
      })
        .width('100%')
        .height('100%')
        .onLoad(async () => {
          console.info('XComponent onLoad is called');
          if(!this.mCameraDevice || !this.mCameraManager) return
          this.openCamera(this.mCameraDevice,this.mCameraManager)
        })
        .onClick(() => {
          console.log('点击了XComponent');
        })
      Button('拍照')
        .width(100)
        .height(40)
        .position({ x: '50%', y: '70%' })
        .translate({ x: -50, y: -20 })
        .onClick(() => {
          console.log('点击了拍照');
        })
      Button('设置')
        .position({ x: '80%', y: '90%' })
        .onClick(() => {
          console.log('点击了设置');
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}