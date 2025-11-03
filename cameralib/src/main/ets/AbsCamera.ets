import { camera } from '@kit.CameraKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { IRelease } from './IRelease'
import { AbsCameraReader } from './AbsCameraReader';

// 相机状态枚举
export enum CameraState {
  None = -1,
  Init = 0,
  WaitingOpen = 1,
  Open = 2,
  Running = 3,
  Close = 4,
  Release = 100
}

// 相机错误枚举
export enum CameraError {
  CameraDeviceError = 0,
  CameraServiceError = 1,
  CameraPermissionError = 2
}

// 相机参数接口
export interface CameraParameters {
  imageWidth: number;
  imageHeight: number;
  cameraOrientation: number;
  isFront: boolean;
}

// 图像数据接口
export interface ImageData {
  width: number;
  height: number;
  format: number;
  buffer: ArrayBuffer;
  timestamp: number;
}

//export interface Position { x: number, y: number };

// 相机监听器接口
export interface ICameraListener {
  onPreviewFrame: (reader:AbsCameraReader,imageData?:image.PixelMap) => void;
  onStateChanged: (camera: AbsCamera, oldState: CameraState, newState: CameraState) => void;
  onParameterChanged: (camera: AbsCamera, key: string, value: string | number | boolean) => void;
  onError: (camera: AbsCamera, error: CameraError) => void;
}

/**
 *  -
 │  - 定义相机操作的标准接口
 │  - 管理相机状态 (None/Init/WaitingOpen/Open/Running/Close/Release)
 │  - 提供聚焦、参数获取等抽象方法
 │  - 通过ICameraListener回调通知状态变化
 *  -
 */
export abstract class AbsCamera implements IRelease {
  //constructor
  protected mCameraId: string;
  protected mIsFront: boolean;
  protected mContext: common.BaseContext;

  protected mState: CameraState = CameraState.None;//这个字段保持私有
  protected mListener: ICameraListener | null = null;

  protected mCameraManager: camera.CameraManager;
  protected mCameraDevices: Array<camera.CameraDevice> | null = null;
  protected mCameraDevice: camera.CameraDevice | null = null;
  protected mCameraInput: camera.CameraInput | null = null;
  protected mSession: camera.VideoSession | null = null;
  protected mPreviewOutput: camera.PreviewOutput | null = null;   //预览流输出
  protected mXComponentOutput: camera.PreviewOutput | null = null;//预览流到XComponent输出
  protected mImageReceiver: image.ImageReceiver | null = null;    //处理视频帧
  protected mImageReceiverSurfaceId: string = '';
  protected mXComponentSurfaceId: string = '';

  protected mPreviewProfile:camera.Profile|null = null;//预览输出size
  protected mImageCrop:image.Region|null = null;//裁剪区域
  protected mCapability:camera.CameraOutputCapability|null = null;//相机的输出能力

  //鸿蒙目前无法选择相机
  //ljj 鸿蒙不需要cameraId启动，这里传camera.CameraDevice
  constructor(cameraDevice:camera.CameraDevice ,isFront :boolean, context: common.BaseContext) {
    this.mContext = context;
    this.mIsFront = isFront;
    this.mCameraDevice = cameraDevice;
    this.mCameraId = cameraDevice.cameraId;
    // 相机管理器
    this.mCameraManager = camera.getCameraManager(context);
  }

  getCameraManager(): camera.CameraManager {
    return this.mCameraManager;
  }

  getCameraDevices(cameraManager: camera.CameraManager): Array<camera.CameraDevice> {
    let cameraArray: Array<camera.CameraDevice> = cameraManager.getSupportedCameras();
    if (cameraArray != undefined && cameraArray.length > 0) {
      for (let index = 0; index < cameraArray.length; index++) {
        console.info('cameraId : ' + cameraArray[index].cameraId);  // 获取相机ID。
        console.info('cameraPosition : ' + cameraArray[index].cameraPosition);  // 获取相机位置。
        console.info('cameraType : ' + cameraArray[index].cameraType);  // 获取相机类型。
        console.info('connectionType : ' + cameraArray[index].connectionType);  // 获取相机连接类型。
      }
      return cameraArray;
    } else {
      console.error("cameraManager.getSupportedCameras error");
      return [];
    }
  }

  // 初始化相机
  abstract init(xComponentSurfaceId: string, listener: ICameraListener): Promise<boolean>;

  // 打开相机
  abstract open(): Promise<boolean>;

  // 关闭相机
  abstract close(): Promise<boolean>;

  // 瞬间变焦
  abstract setZoomRatio(zoom: number): void;

  //平滑变焦
  abstract setSmoothZoom (zoom: number): void;

  // 聚焦
  abstract focus(position: Position): Promise<boolean>;

  // 获取相机参数
  abstract getParameters(): CameraParameters;

  // 获取相机状态
  getState(): CameraState {
    return this.mState;
  }

  // 设置相机状态
  protected setState(state: CameraState): void {
    const oldState = this.mState;
    this.mState = state;
    if (this.mListener?.onStateChanged) {
      this.mListener.onStateChanged(this, oldState, state);
    }
  }

  getCapability(cameraDevice:camera.CameraDevice,sceneMode:camera.SceneMode):camera.CameraOutputCapability {
    let capability = this.mCameraManager.getSupportedOutputCapability(cameraDevice, sceneMode);//camera.SceneMode.NORMAL_VIDEO;
    this.mCapability = capability;
    return capability;
  }
  setPreviewProfile(profile:camera.Profile){
    this.mPreviewProfile = profile;
  }
  getPreviewProfile(){ return this.mPreviewProfile }
  setImageCrop(imageCrop:image.Region){
    this.mImageCrop = imageCrop;
  }

  // 释放资源
  abstract release(): void;

  // 获取相机方向
  abstract getCameraOrientation(): number;

  // 是否为前置相机
  abstract isFront(): boolean;

  abstract isFocusModeSupported(mode: camera.FocusMode): boolean;

  abstract setFocusMode(mode: camera.FocusMode): boolean;
  // 获取当前对焦模式
  abstract getCurrentFocusMode(): camera.FocusMode | null;

  // 设置闪光灯模式
  abstract setFlashMode(flashMode: camera.FlashMode): void;


  /**
   * 设置预览控件mTextureView的宽高比 和 预览尺寸的宽高比 相同
   */
  protected setUpCameraOutputs():void {

  }
}