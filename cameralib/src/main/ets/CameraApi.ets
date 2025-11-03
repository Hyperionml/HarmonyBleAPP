import { camera } from '@kit.CameraKit';
import { image, sendableImage } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { AbsCamera, CameraState, CameraError, ICameraListener, CameraParameters } from './AbsCamera';
import { display } from '@kit.ArkUI';
import { AbsCameraReader } from './AbsCameraReader';
import { PixelMapFrameProducer } from './PixelMapFrameProducer';
import { Logger } from 'common';
import CameraConstant from './constants/CameraConstants';
import { CameraUtils } from './CameraUtils';
import { colorSpaceManager } from '@kit.ArkGraphics2D';

const TAG = 'CameraApi'
/**
 *  -
 │  - 实现具体的相机初始化、打开、关闭、聚焦等操作
 │  - 通过AbsCameraReader提供图像数据
 *  -
 */
export class CameraApi extends AbsCamera {
  private imageWidth: number = 1920;
  private imageHeight: number = 1080;
  private screenWidth: number = 0;
  private screenHeight: number = 0;
  private previewWidth: number = 0;
  private previewHeight: number = 0;

  private mReader: AbsCameraReader| null = null;
  private mFrameProducer: PixelMapFrameProducer| null = null;

  private mPhotoSession: camera.PhotoSession | null = null;
  constructor(cameraDevice:camera.CameraDevice ,isFront :boolean, context: common.BaseContext) {
    super(cameraDevice,isFront ,context);
  }

  async init(xComponentSurfaceId: string, listener: ICameraListener): Promise<boolean> {
    try {
      this.setState(CameraState.Init);
      this.mListener = listener;
      this.mXComponentSurfaceId = xComponentSurfaceId;
      // 相机管理器
      if (!this.mCameraManager) {
        Logger.error(TAG,'initCamera getCameraManager');
        return false;
      }
      // 是否有相机可用
      this.mCameraDevices = this.getCameraDevices(this.mCameraManager);
      if (!this.mCameraDevices || this.mCameraDevices.length === 0) {
        Logger.error(TAG,'initCamera getSupportedCameras');
        return false;
      }
      // todo 实例化 mParameters
      // this.mParameters = new CameraParameterApi2(mActivity, this);
      // todo 初始化相机配置
      // boolean isOk = mParameters.init(mParameterSync);
      // ljj 安卓裁剪在decoder进行，现在鸿蒙在拿到视频帧就进行裁剪，需要在这里计算裁剪区域
      return true;
    } catch (error) {
      Logger.error(TAG,`initCamera fail: ${error}`);
      return false;
    }
  }

  /**
   * 获取ImageReceiver的SurfaceId
   * @param receiver
   * @returns
   */
  async initImageReceiver(): Promise<void> {
    if (!this.mImageReceiver) {
      // 创建ImageReceiver。
      let size: image.Size = { width: this.imageWidth, height: this.imageHeight };
      this.mImageReceiver = image.createImageReceiver(size, image.ImageFormat.JPEG, 8);
      // 获取取第一路流SurfaceId。
      this.mImageReceiverSurfaceId = await this.mImageReceiver.getReceivingSurfaceId();
      Logger.info(TAG,`initImageReceiver imageReceiverSurfaceId:${this.mImageReceiverSurfaceId}`);
      // 注册监听处理预览流每帧图像数据。
      this.onImageArrival(this.mImageReceiver);
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


  loopCount = 0
  logCount = 0
  /**
   * 注册ImageReceiver图像监听
   * @param receiver
   */
  onImageArrival(receiver: image.ImageReceiver): void {
    // 注册imageArrival监听。
    receiver.on('imageArrival', () => {
      // 获取图像。
      receiver.readNextImage((err: BusinessError, nextImage: image.Image) => {
        if (err || nextImage === undefined) {
          Logger.error(TAG,'readNextImage failed');
          return;
        }

        // region 测试代码,用于控制控制视频帧回调速度
        // this.loopCount++
        // if (this.loopCount % 40 !== 0) {
        //   nextImage.release();
        //   this.logCount++
        //   if(this.logCount % 100 === 0){
        //     Logger.error(TAG, `!!!!!控制视频帧回调速度，减少解码频率，防止手机过热，正式版请清除!!!!!`);
        //   }
        //   return;
        // }
        // endregion

        // 官方demo，解析图像内容。
        nextImage.getComponent(image.ComponentType.JPEG, async (err: BusinessError, imgComponent: image.Component) => {
          const time0 = Date.now()
          if (err || imgComponent === undefined) {
            Logger.error(TAG,'getComponent failed');
          }
          if (imgComponent.byteBuffer) {
            // 请参考步骤7解析buffer数据，本示例以方式一为例。
            let width = nextImage.size.width; // 获取图片的宽。
            let height = nextImage.size.height; // 获取图片的高。
            let stride = imgComponent.rowStride; // 获取图片的stride。

            Logger.warn(TAG,`原视频帧大小（未旋转，未裁剪）：${width}*${height} stride:${stride}`);

            // todo 现在主线程处理图像吧，处理不过来了，先把流程跑通，后续再考虑getPixelMap改成sendableImage，并启用ImageProcessWorker方案（开线程处理视频帧）

            // ljj 这里会把相机的图片转换成RGBA_8888的pixelMap
            // 现在相机格式为NV21
            const pixelMap = await this.getPixelMap(imgComponent, width, height, stride);
            // ljj 所以AbsCameraReader要用转换后的pixelMap的pixelFormat
            let pixelFormat = pixelMap.getImageInfoSync().pixelFormat;//值为RGBA_8888即:3

            // 屏幕旋转角度为顺时针旋转
            // 获取设备的屏幕旋转角度（竖屏为0）
            const displayRotation = display.getDefaultDisplaySync().rotation * camera.ImageRotation.ROTATION_90;
            // 这个方法是根据设备的屏幕旋转角度（竖屏为0），获取预览帧需要旋转角度
            const rotation = this.mPreviewOutput!.getPreviewRotation(displayRotation);
            // region 视频帧要做处理 1.旋转 2.裁剪
            /**
             * 1.旋转
             * 使用PreviewOutput.getPreviewRotation()获取图像旋转角度，使用PixelMap.rotate()方法对图像数据进行旋转。
             *
             * 在使用前置镜头时，存在水平镜像和垂直镜像的差异，
             * 为了统一翻转逻辑，在屏幕旋转角度为90度或270度时，需额外旋转180度将图像转正，
             * 使用PixelMap.flip()方法将图像数据进行水平翻转，以达到镜像效果。
             */
            const time1 = Date.now()
            if (this.isFront()) { //=== camera.CameraPosition.CAMERA_POSITION_FRONT
              if (displayRotation === 90 || displayRotation === 270) {
                await pixelMap.rotate((rotation + 180) % 360);
              } else {
                await pixelMap.rotate(rotation);
              }
              await pixelMap.flip(true, false);
            } else {
              //需要旋转
              await pixelMap.rotate(rotation);
            }
            const time2 = Date.now()
            // done 应该在这里根据扫描框裁剪
            // 2.裁剪
            if(this.mImageCrop != null) {
              await pixelMap.crop(this.mImageCrop)
            }
            const time3 = Date.now()
            Logger.warn(TAG,`图像处理前用时：${time1-time0}， 图像旋转用时：${time2-time1}，图像裁剪用时：${time3-time2}，裁剪后大小：${this.mImageCrop?.size.width}*${this.mImageCrop?.size.height}`)
            // endregion

            let newSize = (await pixelMap.getImageInfo()).size

            this.mReader = AbsCameraReader.getInstance(newSize.width, newSize.height, pixelFormat, 3, rotation, false, true);//reuse为true，表示不强制刷新 todo rotation为方向（当前图片为已经旋转处理，是否不再需要处理（现在是就是未处理））
            if(!this.mFrameProducer || this.mReader.consumeChanged()){
              Logger.warn(TAG,`AbsCameraReader刷新`)
              this.mFrameProducer = new PixelMapFrameProducer(this.mReader);
            }
            this.mFrameProducer?.onFrame(pixelMap)

            //调用listener.onPreviewFrame()，把pixelMap写入AbsCameraReader解码
            const listener = this.mListener;
            if (listener) {
              Logger.info(TAG,'ScreenShot-onImageArrival 调用 listener.onPreviewFrame');
              //done onPreviewFrame只需开启worker，出处为通知解码
              listener.onPreviewFrame(this.mReader,pixelMap);
            }
          } else {
            Logger.error(TAG,'byteBuffer is null');
          }
          // 确保当前buffer没有在使用的情况下，可进行资源释放。
          // 如果对buffer进行异步操作，需要在异步操作结束后再释放该资源（nextImage.release()）。
          nextImage.release();
          Logger.info(TAG,'image process done');
        })
      })
    })
  }

  /**
   * ljj 把imgComponent转换成RGBA_8888的PixelMap
   * createPixelMap的InitializationOptions参数的pixelFormat默认为RGBA_8888(pixelFormat:image.PixelMapFormat.RGBA_8888)
   * */
  async getPixelMap(imgComponent: image.Component, width: number, height: number, stride: number) {
    if (stride === width) {
      return await image.createPixelMap(imgComponent.byteBuffer, {
        size: { height: height, width: width },
        srcPixelFormat: image.PixelMapFormat.NV21,
        //pixelFormat默认为RGBA_8888
      });
    }
    const dstBufferSize = width * height * 1.5;
    const dstArr = new Uint8Array(dstBufferSize);
    for (let j = 0; j < height * 1.5; j++) {
      const srcBuf = new Uint8Array(imgComponent.byteBuffer, j * stride, width);
      dstArr.set(srcBuf, j * width);
    }
    let result = await image.createPixelMap(dstArr.buffer, {
      size: { height: height, width: width },
      srcPixelFormat: image.PixelMapFormat.NV21,
    });
    return result
    // const buffer: ArrayBuffer = dstArr.buffer as ArrayBuffer
    // let resultSendAble = sendableImage.createPixelMap(buffer,{ editable: true, size: { height: height, width: width },
    //   srcPixelFormat: image.PixelMapFormat.NV21 });
    // return resultSendAble;
  }

  async open(): Promise<boolean> {
    try {
      if (!this.mCameraManager || !this.mCameraDevices || this.mCameraDevices.length === 0) {
        return false;
      }

      this.setState(CameraState.WaitingOpen);

      // 选择相机设备
      const cameraDevice = this.mCameraDevice
      if (!cameraDevice) {
        Logger.error(TAG,'open camera cameraDevice is null');
        return false;
      }

      // ljj 此处开始需要权限
      // 创建相机输入
      this.mCameraInput = this.mCameraManager.createCameraInput(cameraDevice);
      if (!this.mCameraInput) {
        Logger.error(TAG,'open camera createCameraInput is null');
        return false;
      }

      // 打开相机
      await this.mCameraInput.open().catch((err: Error) => {
        Logger.error(TAG,`open camera open fail: ${err}`);
        throw err;
      });

      //相机输出能力，在DecodeBusiness中获取
      if (!this.mPreviewProfile) {
        Logger.error(TAG,'open camera mPreviewProfile is null');
        return false;
      }
      this.imageWidth = this.mPreviewProfile.size.width;
      this.imageHeight = this.mPreviewProfile.size.height;

      //图片接收
      await this.initImageReceiver();

      // 创建预览输出（使用预配置无需传入previewProfile）
      this.mPreviewOutput = this.mCameraManager.createPreviewOutput(this.mPreviewProfile, this.mImageReceiverSurfaceId);
      if (!this.mPreviewOutput) {
        Logger.error(TAG,'open camera createPreviewOutput is null');
        return false;
      }
      this.mXComponentOutput = this.mCameraManager.createPreviewOutput(this.mPreviewProfile, this.mXComponentSurfaceId);
      if (!this.mXComponentOutput) {
        Logger.error(TAG,'open camera createXComponentOutput is null');
        return false;
      }

      // 创建会话
      this.mSession = this.mCameraManager.createSession(camera.SceneMode.NORMAL_VIDEO) as camera.VideoSession;
      // 可以使用预配置，无需获取相机的输出能力
      if(this.mSession.canPreconfig(camera.PreconfigType.PRECONFIG_HIGH_QUALITY))
        this.mSession.preconfig(camera.PreconfigType.PRECONFIG_HIGH_QUALITY)

      if (!this.mSession) {
        Logger.error(TAG,'open camera createSession is null');
        return false;
      }

      // 配置会话
      this.mSession.beginConfig();
      this.mSession.addInput(this.mCameraInput);
      this.mSession.addOutput(this.mXComponentOutput);
      this.mSession.addOutput(this.mPreviewOutput);
      await this.mSession.commitConfig();

      // 开始预览
      await this.mSession.start();

      this.setState(CameraState.Running);
      return true;
    } catch (e) {
      let error = e as BusinessError
      Logger.error(TAG,`openCamera fail: ${error.message}`,error);
      this.setState(CameraState.Close);
      return false;
    }
  }

  async close(): Promise<boolean> {
    try {
      if (this.mSession) {
        await this.mSession.stop();
      }
      if (this.mCameraInput) {
        await this.mCameraInput.close();
      }
      if (this.mPreviewOutput) {
        await this.mPreviewOutput.release();
      }
      if (this.mXComponentOutput) {
        await this.mXComponentOutput.release();
      }
      if (this.mSession) {
        await this.mSession.release();
      }

      this.setState(CameraState.Close);
      return true;
    } catch (error) {
      Logger.error(TAG,`closeCamera fail: ${error}`);
      return false;
    }
  }

  async focus(point: camera.Point): Promise<boolean> {
    // 鸿蒙相机聚焦实现
    if (this.mState !== CameraState.Running) {
      Logger.warn(TAG,'focus failed: camera is not running');
      return false;
    }
    try {
      if (!this.mSession) {
        return false;
      }
      this.mSession.setFocusMode(camera.FocusMode.FOCUS_MODE_AUTO);
      this.mSession.setFocusPoint(point); // 设置聚焦点
      Logger.info('aaa', `聚焦点: x=${point.x.toFixed(2)}, y=${point.y.toFixed(2)}`);
      return true;
    } catch (e) {
      Logger.error('aaa', `聚焦失败: ${JSON.stringify(e)}`);
      return false;
    }
  }

  // 检查对焦模式是否支持
  isFocusModeSupported(mode: camera.FocusMode): boolean {
    return this.mSession?.isFocusModeSupported(mode) || false;
  }

  // 对焦模式设置方法
  setFocusMode(mode: camera.FocusMode): boolean {
    try {
      const isSupported = this.mSession?.isFocusModeSupported(mode);
      if (isSupported) {
        this.mSession?.setFocusMode(mode);
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('aaa', `聚焦失败: ${JSON.stringify(e)}`);
      return false;
    }
  }

  // todo 未实现安卓CameraParameters
  getParameters(): CameraParameters {
    // 返回相机参数
    return {
      imageWidth: this.imageWidth,
      imageHeight: this.imageHeight,
      cameraOrientation: this.getCameraOrientation(),
      isFront: this.isFront()
    };
  }

  getCameraOrientation(): number {
    if(!this.mCameraDevice)
      throw Error('getCameraOrientation : mCameraDevice not set');
    // 根据相机类型返回方向
    return this.mCameraDevice.cameraOrientation;
  }

  /**是否前置摄像头*/
  isFront(): boolean {
    // 根据相机设备判断是否为前置
    if (this.mCameraDevice) {
      return this.mCameraDevice.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT;
    }
    return false;
  }

  /**获取当前对焦模式*/
  getCurrentFocusMode(): camera.FocusMode | null {
    if (this.mSession) {
      return this.mSession.getFocusMode();
    }
    return null;
  }

  /**设置相机缩放比例
   * 直接立即设置缩放比例，效果是瞬间的
   */
  setZoomRatio(zoom: number) {
    try {
      this.mSession?.setZoomRatio(zoom);
    } catch (e) {
      Logger.error(TAG, 'setZoomRatio error ' + JSON.stringify(e));
    }
  }

  /**
   * 平滑缩放，缩放值和目标值之间产生一个渐进的过渡
   */
  setSmoothZoom(zoom: number) {
    try {
      this.mSession?.setSmoothZoom(zoom);
    } catch (e) {
      Logger.error(TAG, 'setSmoothZoom error ' + JSON.stringify(e));
    }
  }

  /**闪光灯模式*/
  setFlashMode(flashMode: camera.FlashMode) {
    try {
      const isSupported = this.mSession?.isFlashModeSupported(flashMode);
      if (!isSupported) {
        Logger.error(TAG, `setFlashMode error: flash mode ${flashMode} is not supported`);
        return;
      }
      this.mSession?.setFlashMode(flashMode);
    } catch (e) {
      Logger.error(TAG, 'setFlashMode error ' + JSON.stringify(e));
    }
  }

  /**获取当前曝光模式*/
  getCurrentExposureMode(): camera.ExposureMode | null {
    try {
      if (this.mSession) {
        const mode = this.mSession.getExposureMode();
        Logger.info('aaa', `获取到的当前曝光模式: ${mode}`);
        return mode;
      }
      Logger.warn('aaa', 'mSession未初始化');
      return null;
    } catch (error) {
      Logger.error('aaa', '获取当前曝光模式时出错: ' + JSON.stringify(error));
      return null;
    }
  }

  /**设置相机曝光模式*/
  setExposureMode(exposureMode: camera.ExposureMode): boolean {
    try {
      if (!this.mSession) {
        Logger.warn('aaa', 'setExposureMode: mSession未初始化');
        return false;
      }

      if (exposureMode === 0) {
        Logger.info('aaa', '关闭曝光模式');
        return true;
      }

      // 检查是否支持该曝光模式
      const isSupported = this.mSession.isExposureModeSupported(exposureMode);
      Logger.info('aaa', `曝光模式 ${exposureMode} 是否支持: ${isSupported}`);

      if (!isSupported) {
        Logger.error(TAG, `setExposureMode error: focus mode ${exposureMode} is not supported`);
        return false;
      }

      // 设置曝光模式
      this.mSession.setExposureMode(exposureMode);
      Logger.info('aaa', `曝光模式已设置为: ${exposureMode}`);
      return true;
    } catch (error) {
      Logger.error('aaa', 'setExposureMode error: ' + JSON.stringify(error));
      return false;
    }
  }

  // 获取photoSession对象
  getPhotoSession(): camera.PhotoSession | null {
    return this.mPhotoSession;
  }

  //设置photoSession对象
  setPhotoSession(photoSession: camera.PhotoSession): void {
    this.mPhotoSession = photoSession;
  }

  /**检查是否支持微距模式*/
  public isMacroSupported(): boolean {
    try {
      if (this.mPhotoSession) {
        return this.mPhotoSession.isMacroSupported();
      }
      return false;
    } catch (error) {
      Logger.error('aaa', '检查微距模式支持情况时出错: ' + (error as Error).message);
      return false;
    }
  }

  /**微距模式*/
  enableMacro(): boolean {
    try {
      if (this.mPhotoSession && this.isMacroSupported()) {
        this.mPhotoSession.enableMacro(true); // 启用微距模式
        Logger.info('aaa', '微距模式已启用');
        return true;
      } else {
        Logger.warn('aaa', '当前设备不支持微距模式或photoSession未初始化');
        return false;
      }
    } catch (error) {
      Logger.error('aaa', '启用微距模式时出错: ' + (error as Error).message);
      return false;
    }
  }


  //todo 白平衡模式(Api版本20才开始支持)


  release(): void {
    this.close();
    this.mListener = null;
    this.setState(CameraState.Release);
  }
}

