import { EventManager,Level,IEventReceiver,Event, Logger, FileUtils } from 'common';
import { camera } from '@kit.CameraKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { AbsCamera, CameraApi, CameraState, ICameraListener, ImageData,CameraParameters,
  AbsCameraReader } from 'cameralib';
import { AppEvent } from '../common/event/AppEvent';
import { AppEventType } from '../common/event/AppEventType';
import { Decoder, OnDecodeResult } from './Decoder';
import { DecodeResultBean } from '../bean/DecodeResultBean';
import { getCurrentProductType, ProductType } from '../common/ProductType';
import PreviewViewModel from '../viewmodels/PreviewViewModel';
import { ErrorEvent } from '@kit.ArkTS';
import { DecoderCameraParameters } from './DecoderCameraParameters';
import { tag } from '@kit.ConnectivityKit';
import { CameraUtils } from 'cameralib/src/main/ets/CameraUtils';
import { display, promptAction } from '@kit.ArkUI';
import WindowUtil from '../utils/WindowUtil';
import { ImageSaver } from '../common/FileStorageManager';
import RefreshableTimer from '../utils/RefreshableTimer';
import { calCameraPoint } from '../utils/CommonUtil';
import { DeviceEvent, DeviceEventType } from 'devices';
import BuildProfile from 'BuildProfile';
const TAG:string= 'DecodeBusiness';

/**
 * 一、
 * 1、在onCreate中初始化 mDecodeBusiness = new DecodeBusiness(this, preview);
 * 2、在onResume中打开相机 mDecodeBusiness.startCamera(forceZoom);
 * 3、在onPause中关闭相机 mDecodeBusiness.stopCamera();
 * 4、在onPause中关闭相机 mDecodeBusiness.stopCamera();
 * 5、在onDestroy中释放相机 mDecodeBusiness.releaseCamera();
 * 二、
 * 1、相机状态是CameraState.Running时（或者当确认权限已经完整setCheck()），执行 startDecode()初始化 Decoder的对象
 * 2、当有一帧数据通过回调函数onPreviewFrame(),执行开始mDecoder.decode(reader);（将帧数据通过reader传给mDecoder对象，开启线程解码）
 *  -
 │  - 管理相机生命周期 (startCamera/stopCamera/releaseCamera)
 │  - 管理解码器生命周期 (startDecode/stopDecode)
 │  - 处理相机状态变化和参数变化
 │  - 通过EventManager发送事件
 *  -
 */
export class DecodeBusiness{
  static mDecodeBusiness : DecodeBusiness|null = null;
  public set(m:DecodeBusiness){
    DecodeBusiness.mDecodeBusiness = m;
  }
  private mPreviewViewModel: PreviewViewModel|undefined;

  private mCameraIsStart: boolean = false;
  public getCameraIsStart(){ return this.mCameraIsStart }
  private mCamera: AbsCamera | null = null;
  private mParameter :CameraParameters|null = null;
  private mDecoder: Decoder | null = null;
  private mContext: common.BaseContext;
  private mImageReceiver: image.ImageReceiver | undefined = undefined;
  private mImageReceiverSurfaceId: string = '';
  private mXComponentSurfaceId: string = '';
  private mIsEnabledDecode: boolean = false;
  private mDecoderCameraParameters:DecoderCameraParameters|null = null;

  private mIsScreenshot :boolean = false

  // 检查列表
  private mCheckList: boolean[] = [false, false, false, false];
  private static readonly CHECK_PERMISSION = 0;
  private static readonly CHECK_UI_LAYOUT = 1;
  private static readonly CHECK_ACTIVITY_STATE = 2;
  private static readonly CHECK_CAMERA_INIT = 3;

  private mImageSaver: ImageSaver;

  //聚焦点
  private screenWidth: number = 0;
  private screenHeight: number = 0;
  private previewWidth: number = 0;
  private previewHeight: number = 0;
  public isManualFocusing: boolean = false;

  //test
  private static Status:string = 'NONE';
  public setStatus(value:string){
    let processingTime = Date.now();
    while (Date.now() - processingTime < 1000) {
    }
    DecodeBusiness.Status = value
  }
  public getStatus(){ return DecodeBusiness.Status }

  // 相机监听器
  private mCameraListener: ICameraListener = {
    onPreviewFrame: (reader:AbsCameraReader,imageData?:image.PixelMap) => {
      this.onPreviewFrame(reader,imageData);
    },
    onStateChanged: (camera: AbsCamera, oldState: CameraState, newState: CameraState) => {
      console.info('DecodeBusiness onStateChanged');
      if (newState === CameraState.Init) {
        this.setCheck(DecodeBusiness.CHECK_CAMERA_INIT, true);
      } else if (newState === CameraState.Running) {
        this.startDecode();
        console.info('DecodeBusiness startDecode');
        this.triggerAutoFocus();   // 相机运行状态时触发一次自动对焦
      }
      // 发送相机状态事件
      EventManager.async(this, new AppEvent(AppEventType.CameraStateEvents, Level.Common, newState));
    },
    onParameterChanged: (camera: AbsCamera, key: string, value: string | number | boolean) => {
      // 发送相机参数事件
      EventManager.async(this, new AppEvent(AppEventType.CameraParamsEvents, Level.Common));
      // todo 保存下参数起来
    },
    onError: (camera: AbsCamera, error) => {
      // 发送相机错误事件
      EventManager.async(this, new AppEvent(AppEventType.CameraDeviceError, Level.High));
    }
  };

  //处理解码结果
  private mDecodeResultListener: OnDecodeResult = {
    onDecoded: (result: DecodeResultBean, ok: boolean) => {
      switch (getCurrentProductType()) {
        case ProductType.Secrecy:
          Logger.info(TAG, `处理解码结果-ProductType.Secrecy: ${result.IsSuccess()}`);
          EventManager.async(this, new AppEvent(AppEventType.QCService, Level.Common, result));
          break;
        default:
          Logger.info(TAG, `ZXing 处理解码结果: ${result.IsSuccess()}`);
          EventManager.async(this, new AppEvent(AppEventType.DecodeService, Level.Common, result));
          break;
      }
    },
    onWorkerError: (error: ErrorEvent): void => {
      Logger.error(TAG, `worker异常: ${error.message}`);
    },
    onWorkerInitted: (): void => {
      Logger.error(TAG, `worker初始化完成`);
    },
    onHandleFrame: (frame: Uint8Array): void => {
      Logger.info(TAG, `onHandleFrame:${frame.length}}`);
      this.handleFrame(frame)
    }
  };

  constructor(context: Context,previewVM: PreviewViewModel | string) {
    this.mContext = context;
    this.mImageSaver = new ImageSaver(context);// 创建ImageSaver实例
    if(typeof previewVM == 'string'){
      this.mXComponentSurfaceId = previewVM;//xComponentSurfaceId
    } else{
      this.mPreviewViewModel = previewVM
      this.mXComponentSurfaceId = previewVM.xComponentController.getXComponentSurfaceId();
    }
  }

  // 设置检查状态
  private setCheck(index: number, value: boolean): void {
    this.mCheckList[index] = value;
  }

  // 重置检查状态
  private resetChecked(): void {
    for (let i = 0; i < this.mCheckList.length; i++) {
      this.mCheckList[i] = false;
    }
  }

  public startCamera(zoom:number):boolean {
    if (this.mCamera == null) {
      this.createCamera(zoom);
      return true;
    }
    this.mCameraIsStart = true
    return true
  }


  async createCamera(zoom: number): Promise<AbsCamera | null> {
    try {
      // 1. 选择相机设备
      // 选择后置主摄
      // 2. 创建相机实例

      let cameraDevice = this.selectCamera();
      if(cameraDevice==null) {
        Logger.error(TAG,'createCamera selectCamera fail');
        return null;
      }

      this.mCamera = new CameraApi(cameraDevice, false, this.mContext);
      Logger.info(TAG,'createCamera Camera selected');

      // 3. 初始化相机
      if(!this.mCamera){
        //todo 无法使用相机，增加一个弹框，确认后，自动重启App
        return null;
      }
      const initSuccess = await this.mCamera.init(this.mXComponentSurfaceId, this.mCameraListener);
      if (!initSuccess) {
        Logger.error(TAG,'createCamera Camera init failed');
        EventManager.async(this, new AppEvent(AppEventType.CameraDeviceError, Level.High));
        return null;
      }

      // todo 4. 获取相机参数，以及通过最短对焦距离计算最佳最佳参数（预览尺寸，缩放率，对焦距离，对焦模式等等）
      this.mParameter = this.mCamera.getParameters();//后续代码为配置此参数

      // todo 鸿蒙无法获取最短对焦距离，计算部分无法实现 https://developer.huawei.com/consumer/cn/forum/topic/0202191259934862318?fid=0109140870620153026&pid=0303191687238538627
      // mParameter.getSupportedValue(ParameterKey.LensInfoMinimumFocusDistance);

      // todo 获取AbsCamera的必要参数，鸿蒙能设置的参数只有7个，且有两个是高版本（17+，19+）可才可用（5.0是12）
      // ParameterChooser chooser = new ParameterChooser();

      // todo 获取支持的预览分辨率getSupportedList(ParameterKey.PreviewSize);，根据屏幕计算最佳预览分辨率（鸿蒙有官方做法是否采用）
      //previewSize = CameraUtils.getPreviewSize
      //parameterMap.put(ParameterKey.PreviewSize, previewSize);

      // region 获取相机能力（使用预配置可以跳过）,即相机支持的输出分辨率，需要根据屏幕大小选择
      // 对应安卓 getSupportedList getPreviewSize parameterMap.put(ParameterKey.PreviewSize, previewSize);
      let capability: camera.CameraOutputCapability = this.mCamera.getCapability(cameraDevice, camera.SceneMode.NORMAL_VIDEO);
      if (!capability) {
        Logger.error(TAG,'createCamera getSupportedOutputCapability is null');
        return null;
      }
      if(!this.mPreviewViewModel) return null;
      //这是xComponent的大小，根据屏幕大小计算出来的大小
      let profile = this.mPreviewViewModel.getProfile(cameraDevice.cameraOrientation);
      //获取最适合的输出流
      const previewProfile = CameraUtils.getBestCapability(profile,capability);
      // ljj 此处为迁移安卓的逻辑,需要改变XCompetent的大小使其超出屏幕，才能使画面不变形， todo 但是鸿蒙现在会有黑边
      // const previewProfile = CameraUtils.getPreviewSize(profile,capability,profile.size.width,1,false);
      // this.mPreviewViewModel.setPreviewSizeByCamera({width:previewProfile.size.height,height:previewProfile.size.width});
      // todo 此处安卓在parameterMap.put()中设置，现未实现
      this.mCamera.setPreviewProfile(previewProfile);
      // endregion

      //设置裁剪框，此处安卓逻辑在DecodeParams的 
      const scanBoxInfo = this.mPreviewViewModel.getScanBoxInfo();
      if (!scanBoxInfo) {
        Logger.error(TAG,'createCamera Camera ScanBox failed');
        //可在这里发消息，再次启动
        return null;
      }
      // 预览帧信息是previewProfile
      this.previewWidth = previewProfile.size.width;
      this.previewHeight = previewProfile.size.height;
      // 屏幕信息，即xComponent的信息
      const displaySize: Size = WindowUtil.getMaxDisplaySize();
      this.screenWidth = displaySize.width;
      this.screenHeight = displaySize.height;
      const imageCrop = CameraUtils.crop(previewProfile.size,displaySize,
        this.mCamera.getCameraOrientation(),display.getDefaultDisplaySync().rotation,scanBoxInfo,false);
      this.mCamera.setImageCrop(imageCrop);

      // todo 设置相机缩放率
      if (zoom >= 100) {
        // parameterMap.put(ParameterKey.Zoom, zoom);
      }

      // todo 设置相机 对焦距离（鸿蒙无法做） 和 对焦模式
      // if (setting.getIsFixedFocusDistance()) {
      //   parameterMap.put(ParameterKey.FocusDistance, Utils.millimeterToDiopters(mFocusDistanceMM));
      //   parameterMap.put(ParameterKey.AutoFocusMode, AutoFocusMode.AF_MODE_OFF);//注意：关闭自动对焦后，会无法扫描屏幕（中远距离）
      // }

      // todo 设置相机 焦距（鸿蒙无法获取也无法设置）
      // mParameter.getSupportedList(ParameterKey.FocalLength);
      // parameterMap.put(ParameterKey.FocalLength, manualFocalLens);

      // todo 保存设置
      // mParameter.put(parameterMap);

      // 6. 打开相机
      const openSuccess = await this.mCamera.open();
      this.setZoomRatio(zoom)
      if (!openSuccess) {
        Logger.error(TAG,'createCamera Camera open failed');
        EventManager.async(this, new AppEvent(AppEventType.CameraDeviceError, Level.High));
        return null;
      }

      // todo 相机是否能自动聚焦(反之，需要用Timer实现连续聚焦，手动针对屏幕点击对焦，鸿蒙有官方示例是否采用)
      // boolean mIsAutoFocus = parameterMap.containsKey(ParameterKey.AutoFocusMode);
      // if (!mIsAutoFocus) {｝

      return this.mCamera;
    } catch (error) {
      Logger.info(TAG,'createCamera Create camera failed:', error);
      EventManager.async(this, new AppEvent(AppEventType.CameraDeviceError, Level.High));
      return null;
    }
  }

  //todo 鸿蒙目前无法实现选择摄像头
  /**
   * 经过真机测试，只会返回两个摄像头，一个前置一个后置，且cameraType均为0，无法区分摄像头类型类型
   * @returns
   * */
  private selectCamera(): camera.CameraDevice | null {
    // todo 实现CameraUtils.getAppropriateCameraId 获取最佳摄像头
    if(false){
      // todo 可能工程模式或者专业切换了摄像头
    }
    const cameraManager = camera.getCameraManager(this.mContext);
    const cameras = cameraManager.getSupportedCameras();
    let resultCamera :camera.CameraDevice | null = null;
    if (!cameras || cameras.length === 0) {
      return null;
    }
    //先取后置广角
    const cameraByProperties = cameras.find(device => {
      const positionMatch =  device.cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK;
      //ljj 经过真机测试，只会返回两个摄像头，一个前置一个后置，且cameraType均为0，无法区分摄像头类型类型
      const typeMatch =  device.cameraType === camera.CameraType.CAMERA_TYPE_WIDE_ANGLE;
      return positionMatch && typeMatch;
    });
    resultCamera = cameraByProperties || cameras[0];
    return resultCamera;
  }

  // 停止相机
  public async stopCamera(): Promise<void> {
    if (this.mCamera) {
      await this.mCamera.close();
      this.mCamera = null;
    }
    this.stopDecode();
    this.resetChecked();
    //todo CacheManager.clear(); mDisplayCrop = null;
    this.mCameraIsStart = false;
  }

  // 释放相机
  public async releaseCamera(): Promise<void> {
    await this.stopCamera();
  }

  // todo initDecoderParameters
  public initDecoderParameters(){
    //在这里计算裁剪区域（保存在mDecoderCameraParameters.mImageCrop）
    //这是图像里的区域（根据预览孔在图像里的位置，做完变换后的结果）
    //ljj 在这里计算裁剪区域，考虑了是否前置需要翻转，屏幕角度是否需要旋转，得到Rect裁剪区域供CameraImage.getRgba对buffer进行裁剪

  }

  // 聚焦
  public async focusCamera(position: camera.Point): Promise<boolean> {
    if (!this.mCamera || !position) {
      return false;
    }
    try {
      // 可利用预览帧尺寸与点击坐标换算
      // let x = position.x*(this.previewHeight/this.screenWidth)
      // let y = position.y*(this.previewWidth/this.screenHeight)
      // let setX = x/this.previewHeight
      // let setY = y/this.previewWidth

      const cameraApi = this.mCamera as CameraApi;
      // 设置对焦模式为自动对焦
      const modeSet = cameraApi.setFocusMode(camera.FocusMode.FOCUS_MODE_AUTO);
      if (!modeSet) {
        Logger.warn('aaa',`对焦模式设置失败`);
        return false;
      }
      const result = await this.mCamera.focus(position);
      Logger.info('aaa', `聚焦成功`);
      return result;
    } catch (e) {
      Logger.error('aaa',`聚焦失败: ${JSON.stringify(e)}`);
      return false;
    }
  }

  // 恢复自动对焦模式
  private triggerAutoFocus(): void {
    if (!this.mCamera) {
      return;
    }
    try {
      const cameraApi = this.mCamera as CameraApi;
      if (cameraApi.isFocusModeSupported(camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO)) {
        //自动连续对焦效果不好，原因未知，暂时取消
        // cameraApi.setFocusMode(camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO);
        console.info('aaa', "相机初始化完成后设置连续自动对焦");
      } else {
        cameraApi.setFocusMode(camera.FocusMode.FOCUS_MODE_AUTO);
        // 设置对焦点为中心点
        cameraApi.focus({x: 0.5, y: 0.5});
        Logger.info('aaa', "相机初始化完成后设置一次中心点对焦");
      }
    } catch (e) {
      Logger.error('aaa','恢复自动对焦模式失败: ' + JSON.stringify(e));
    }
  }

  // 开始解码
  public startDecode(): void {
    this.mIsEnabledDecode = true;
    if (!this.mDecoder || !this.mDecoder.getIsStart()) {
      this.mDecoder = Decoder.getInstance();
      if (this.mParameter != null && this.mDecoderCameraParameters != null) {
        this.mDecoder.setDecoderCameraParameters(this.mDecoderCameraParameters);
      }
      else{
        console.warn('startDecode(),DecoderCameraParameters为空')
      }

      // 在启动解码前清空AbsCameraReader中的旧数据
      AbsCameraReader.instance()?.clearAllSlots();
      Logger.warn(TAG, `startDecode() 已清空AbsCameraReader中的旧数据 clearAllSlots()`);

      this.mDecoder.start(this.mDecodeResultListener);
    }
  }

  // 停止解码
  public stopDecode(): void {
    this.mIsEnabledDecode = false;
    if (this.mDecoder) {
      this.mDecoder.stop();
    }
  }
  public releaseDecode(): void {
    this.mIsEnabledDecode = false;
    if (this.mDecoder) {
      this.mDecoder.releaseWorker()
    }
  }

  // isBluetooth为true，截取蓝牙设备截图
  public screenshot(isBluetooth?:boolean):void  {
    if(!isBluetooth)
      this.mIsScreenshot = true;
    else{
      //蓝牙设备截图
      EventManager.sync(this, new DeviceEvent(DeviceEventType.TakePhoto, Level.Common, true));
    }
  }

  // 保存蓝牙设备截图
  public async saveDeviceScreenshot(): Promise<void>{
    let filePath = '/data/storage/el2/base/haps/entry/files/screenshot.DAT';
    let pixelMap = await FileUtils.readFileToPixelMap(filePath);
    if(BuildProfile.DEBUG && pixelMap)
      EventManager.sync('ScreenShot',new AppEvent(AppEventType.ScreenShot2,Level.High,pixelMap))
    const success = await this.mImageSaver.savePixelMap(pixelMap);
    if (success) {
      promptAction.showToast({
        message: '截图已保存至相册',
        duration: 3000,
        alignment: Alignment.Top,
        offset: { dx: 0, dy: 300 },
      });
    } else {
      promptAction.showToast({
        message: '保存失败，请重试',
        duration: 3000,
        alignment: Alignment.Top,
        offset: { dx: 0, dy: 300 },
      });
    }
  }

  // 预览帧回调
  private async onPreviewFrame(reader: AbsCameraReader,imagePixelMap?:image.PixelMap): Promise<void> {
    if (this.mIsEnabledDecode && this.mDecoder) {
      try {
        // 截图，reader读取图片，裁剪后保存
        // ljj 测试截图时注释掉this.mDecoder.decode(reader);才能看到AbsCameraReader读取的视频帧
        // 因为Worker在循环中不断尝试读取，而主线程只在mIsScreenshot=true时才读取，所以Worker几乎总是抢先获取数据。
        if(this.mIsScreenshot){
          //此处为视频帧的原始PixelMap
          if(BuildProfile.DEBUG && imagePixelMap)
            EventManager.sync('ScreenShot',new AppEvent(AppEventType.ScreenShot2,Level.High,imagePixelMap))

          //此处为AbsCameraReader读取的视频帧还原成PixelMap
          let frameHandler = reader.acquireImageForRead();
          if(frameHandler){
            let width = reader.getWidth()
            let height = reader.getHeight()
            let format = reader.getImageFormat();

            const frame = frameHandler.buffer;
            //ljj 由于frame.buffer是SharedArrayBuffer,createPixelMapSync无法使用SharedArrayBuffer创建,需要强制拷贝到新的ArrayBuffer
            const copy = new Uint8Array(frame.byteLength);
            copy.set(frame);

            let pixelMap = image.createPixelMapSync({
              size: { width, height },
              srcPixelFormat: format
            })
            await pixelMap.writeBufferToPixels(copy.buffer)

            if(BuildProfile.DEBUG){
              EventManager.sync('ScreenShot',new AppEvent(AppEventType.ScreenShot,Level.High,pixelMap));
            }

            frameHandler.commit()
            const success = await this.mImageSaver.savePixelMap(pixelMap);
            if (success) {
              promptAction.showToast({
                message: '截图已保存至相册',
                duration: 3000,
                alignment: Alignment.Top,
                offset: { dx: 0, dy: 300 },
              });
            } else {
              promptAction.showToast({
                message: '保存失败，请重试',
                duration: 3000,
                alignment: Alignment.Top,
                offset: { dx: 0, dy: 300 },
              });
            }
          }
          this.mIsScreenshot = false;
        }else{
          //开始解码
          // ljj !!!!!正式解码需要解开注释!!!!!
          this.mDecoder.decode(reader);
        }
      } catch(err) {
        this.mIsScreenshot = false;
        const error = err as BusinessError;
        console.error('onPreviewFrame decode error:', error);
      }
    }
  }
  // 测试代码，把Worker返回的视频帧显示在界面上
  private async handleFrame(frame:Uint8Array){
    const copy = new Uint8Array(frame.byteLength);
    copy.set(frame);
    let pixelMap = image.createPixelMapSync({
      size: { width:1080, height:1920 },
      srcPixelFormat: image.PixelMapFormat.RGBA_8888
    })
    await pixelMap.writeBufferToPixels(copy.buffer)
    EventManager.sync('ScreenShot',new AppEvent(AppEventType.ScreenShot3,Level.High,pixelMap))
  }

  // 获取相机状态
  public getCameraState(): CameraState {
    return this.mCamera ? this.mCamera.getState() : CameraState.None;
  }


  public isCameraInit():boolean {
    return this.mCamera != null &&
      this.mCamera.getState() < CameraState.Close &&
      this.mCamera.getState() > CameraState.None;
  }


  // 获取相机参数
  public getCameraParameters(): CameraParameters | null {
    return this.mCamera ? this.mCamera.getParameters() : null;
  }

  // 瞬间滑动缩放条设置相机缩放比例
  public setZoomRatio(zoom: number): void {
    if (this.mCamera) {
      (this.mCamera as CameraApi).setZoomRatio(zoom);
    }
  }

  //平滑缩放
  public setSmoothZoom(zoom: number): void {
    if (this.mCamera) {
      (this.mCamera as CameraApi).setSmoothZoom(zoom);
    }
  }

  // 闪光灯模式
  public getCameraFlash(isFlashOn: boolean): void {
    if (this.mCamera) {
      // 3表示常亮，0表示关闭
      this.mCamera.setFlashMode(isFlashOn ? 3 : 0);
    }
  }

  // 获取当前曝光模式
  public getCurrentExposureMode(): camera.ExposureMode | null {
    if (this.mCamera) {
      try {
        const cameraApi = this.mCamera as CameraApi;
        const mode = cameraApi.getCurrentExposureMode();
        Logger.info('aaa', `DecodeBusiness 获取到的当前曝光模式: ${mode}`);
        return mode;
      } catch (error) {
        Logger.error('aaa', '获取当前曝光模式时出错: ' + (error as Error).message);
        return null;
      }
    }
    Logger.warn('aaa', '相机实例为空');
    return null;
  }

  // 设置曝光模式
  public setExposureMode(exposureMode: camera.ExposureMode): boolean {
    if (this.mCamera) {
      try {
        const cameraApi = this.mCamera as CameraApi;
        const result = cameraApi.setExposureMode(exposureMode);
        Logger.info('aaa', `设置曝光模式结果: ${result}`);
        return result;
      } catch (error) {
        Logger.error('aaa', '设置曝光模式时出错: ' + (error as Error).message);
        return false;
      }
    }
    Logger.warn('aaa', '相机实例为空');
    return false;
  }

  // 曝光模式切换方法
  public toggleExposureMode(): boolean {
    if (this.mCamera) {
      try {
        const cameraApi = this.mCamera as CameraApi;
        const currentMode = this.getCurrentExposureMode();
        if (currentMode !== camera.ExposureMode.EXPOSURE_MODE_AUTO) {
          const result = cameraApi.setExposureMode(camera.ExposureMode.EXPOSURE_MODE_AUTO);
          Logger.info('aaa', "已开启曝光模式");
          return result;
        } else {
          const result = cameraApi.setExposureMode(0 as camera.ExposureMode);
          Logger.info('aaa', "已关闭曝光模式");
          return result;
        }
      } catch (error) {
        Logger.error('aaa', '切换曝光模式时出错: ' + (error as Error).message);
        return false;
      }
    }
    Logger.warn('aaa', '相机实例为空');
    return false;
  }

  // 检查是否支持微距模式
  public isMacroSupported(): boolean {
    if (this.mCamera) {
      try {
        const cameraApi = this.mCamera as CameraApi;
        return cameraApi.isMacroSupported();
      } catch (error) {
        Logger.error('aaa', '检查微距模式支持情况时出错: ' + (error as Error).message);
        return false;
      }
    }
    return false;
  }

  // 启用微距模式
  public enableMacro(): boolean {
    if (this.mCamera) {
      try {
        const cameraApi = this.mCamera as CameraApi;
        return cameraApi.enableMacro();
      } catch (error) {
        Logger.error('aaa', '启用微距模式时出错: ' + (error as Error).message);
        return false;
      }
    }
    return false;
  }

  // 微距模式切换方法
  public toggleMacroMode(): boolean {
    if (this.mCamera) {
      const isSupported = this.isMacroSupported();
      if (isSupported) {
        const success = this.enableMacro();
        if (success) {
          Logger.info('aaa', "微距模式启用成功");
        } else {
          Logger.warn('aaa', "微距模式启用失败");
        }
        return success;
      } else {
        Logger.warn('aaa', "当前设备不支持微距模式");
        return false;
      }
    }
    return false;
  }

}