/**
 * 三星 Z Fold 3(5G) ,焦距:5mm，像距为:5.28mm,镜头突出约2mm，架设93mm的高度进行拍摄，相机界面为149.5mm×112mm(4:3),对焦距离100mm，可拍摄范围是123.5*91.3mm（注意，这里没形成4：3的比例，应该是摄像头畸变导致的）
 * 小米 8 ,           焦距:4.216mm，像距为:4.41m,镜头突出1mm，保护壳1mm,假设94m的高度进行拍摄，相机界面为91×68mm，对焦距离100mm，可拍摄范围是121.2*8.85（注意，这里同样没形成4：3的比例)
 * 红米 K50,          焦距:4.71mm,像距为:4.96m,镜头突出约2+mm，架设93mm的高度进行拍摄，相机界面为92×69mm，对焦距离100mm，可拍摄范围是116.2*8.5（注意，这里同样没形成4：3的比例)
 * 红米 K50,  当对焦距离增加到150mm时，最大可视为185，增加的比较多，185:116.2＞15:10,也大于14.5:9.5，这可能是畸变导致的
 */
// 解码参数管理器，负责在解码过程中计算物理尺寸到像素尺寸的转换，为解码器提供准确的图像尺寸信息。
export class DecoderCameraParameters {
  private static readonly TAG: string = 'DecoderCameraParameters';
  /**最大对焦距离，不可超过此值（200mm）*/
  public static readonly MaxFocusDistancMM: number = 200; //单位：毫米
  /**最小对焦距离，不可超过此值(15mm)*/
  public static readonly MinFocusDistancMM: number = 15;
  /**最适用对焦距离，大部分相机的最近对焦距离是100mm*/
  public static readonly FitFocusDistancMM: number = 100;

  /**码图812dpi，1英寸(in) = 25.4毫米(mm)，PixeslPerMillimeter =  812 / 25.4 */
  private static readonly PixelsPerMillimeter: number = 813 / 25.4;
  //实际测量中：物距83mm时，在每台手机的 图像传感器 上，对应的拍摄的范围都是约108mm，
  //理论：物长 / 物距 = 像长 / 像距 ,  1 / 焦距 = 1 / 物距 + 1 / 像距,

  /**标准环境物距*/
  public static readonly LabPhysicalDistance: number = 95;

  /**物理距离(常见相机的最近对焦距离是100mm，像距约5mm)，实验室里是采用9cm左右的罐子+可自由叠加的纸张+焦距形成的*/
  public static readonly BestPhisicalDistance: number = 100 - 5;

  /**拍摄的范围(单位：毫米),拍摄物位菲林尺，使用的相机是红米K50*/
  //    public static final double LabRealWorldObjectSize = 116;

  /**标准环境物长*/
  public static readonly LabRealWorldObjectSize: number = 135;

  /**标准环境下，拍摄出的物体长度与物体距离的比值：物长 / 物距 */
  private static readonly LabObjectSizeDistanceRadio: number = DecoderCameraParameters.LabRealWorldObjectSize / DecoderCameraParameters.LabPhysicalDistance;

  /**视野宽度与物距的比值，也即是物体大小跟物距的比值，*/
  private mObjectSizeDistanceRadio: number;

  /**是否使用固定对焦距离*/
  private mIsManualSensor: boolean;

  /**图像传感器(感光元件,成像面)的物理尺寸，(单位：毫米)*/
  private mSensorPhysicalSize?: Size;

  /**焦距(单位：毫米)*/
  private mFocalLength?: number;

  /**对焦距离（像距+物距）(单位：毫米)*/
  private mFocusDistanceMM: number;

  /**物距(单位：毫米)*/
  private mPhysicsDistance: number = 0;

  /**像距(单位：毫米)*/
  private mImageDistance: number = 0;

  /**相机预览尺寸*/
  private mPreviewSize: Size;

  /**实际预览裁剪*/
  private mImageCrop: RectLike;

  /**屏幕分辨率*/
  private mScreenSize: Size;

  /**屏幕物理尺寸*/
  private mScreenSizeOfMM?: Size /* android.util.SizeF */;

  /**缩放率，100是无放大*/
  private mZoom: number;

  /**屏幕方向*/
  private mScreenOrientation: number;

  /**图像传感器(感光元件,成像面)的宽高比，数值大于等于1，用长的一边去除以短的一边*/
  private mSensorPixelSizeRatio: number;

  /**是否支持设备远离模式，开启后，相机离防伪码比较较远，也有概率识别*/
  private mIsSupportFarAwayMode?: boolean;

  /**
   * @param isManualSensor 是否支持手动控制相机设备
   * @param focusDistanceMM 如果可以手动控制相机设备,distance为对焦距离（像距+物距），否则distance为物距 （单位：mm）
   * @param zoom 缩放率
   * @param screenOrientation 屏幕方向
   * @param previewSize 相机预览尺寸
   * @param imageCrop 实际预览裁剪
   * @param focalLength 焦距
   * @param sensorPhysicalSize 图像传感器(感光元件,成像面)的物理尺寸
   * @param sensorPixelSizeRatio 图像传感器(感光元件,成像面)的宽高比
   * @param screenSize 屏幕分辨率
   * @param screenSizeOfMM 屏幕物理尺寸
   */
  constructor(
    isManualSensor: boolean,
    focusDistanceMM: number,
    zoom: number,
    screenOrientation: number,
    previewSize: Size,
    imageCrop: RectLike,
    focalLength?: number,
    sensorPhysicalSize?: Size,
    sensorPixelSizeRatio: number = 0,
    screenSize?: Size,
    screenSizeOfMM?: Size
  ) {
    this.mIsManualSensor = isManualSensor;

    //在Stacey的Pura 70 Ultra上，最短对焦距离只有7公分，但实际上这个对焦距离就糊了，改为使用默认的10公分作为对焦距离
    if (focusDistanceMM >= DecoderCameraParameters.MaxFocusDistancMM) {
      this.mFocusDistanceMM = DecoderCameraParameters.MaxFocusDistancMM;
    } else if (focusDistanceMM < DecoderCameraParameters.MinFocusDistancMM && focusDistanceMM > 0) {
      this.mFocusDistanceMM = DecoderCameraParameters.MinFocusDistancMM;
    } else {
      this.mFocusDistanceMM = focusDistanceMM;
    }
    this.mFocalLength = focalLength;

    let physicsDistanceAndImageDistance: PairNumber | null = null;
    if (this.mFocalLength != null) {
      physicsDistanceAndImageDistance = DecoderCameraParameters.getPhysicsDistanceAndImageDistance(this.mFocalLength, this.mFocusDistanceMM);
    }
    if (physicsDistanceAndImageDistance != null) {
      this.mPhysicsDistance = physicsDistanceAndImageDistance.first;
      this.mImageDistance = physicsDistanceAndImageDistance.second;
    } else {
      this.mPhysicsDistance = DecoderCameraParameters.BestPhisicalDistance;
    }

    this.mObjectSizeDistanceRadio = DecoderCameraParameters.LabObjectSizeDistanceRadio;

    this.mPreviewSize = previewSize;
    this.mZoom = zoom;
    this.mImageCrop = imageCrop;
    this.mScreenOrientation = screenOrientation;
    this.mSensorPixelSizeRatio = sensorPixelSizeRatio;
    this.mScreenSize = screenSize ?? { width: previewSize.width, height: previewSize.height };
    this.mScreenSizeOfMM = screenSizeOfMM;
  }

  /** 根据图像传感器(感光元件,成像面)的物理尺寸和焦距 计算 物长 与 物距 的 比值
   * 物长 / 物距 = 像长 / 像距
   * 注意：1、这里的像长是指图像传感器(感光元件,成像面)的物理尺寸
   * 2、像距 由方法getPhysicsDistanceAndImageDistance计算
   *
   * @param focalLength        焦距
   * @param sensorPhysicalSize 图像传感器(感光元件,成像面)的物理尺寸
   * @return
   */
  public calculatePhysicsWidthScale(focalLength?: number, sensorPhysicalSize?: Size): boolean {
    //这种调度外部接口的方式，是错误的，找个时间改改
    if (!this.mIsManualSensor)
      return false;
    if (sensorPhysicalSize == null || focalLength == null || focalLength <= 0)
      return false;

    console.info(DecoderCameraParameters.TAG, '根据图像传感器(感光元件,成像面)的物理尺寸和焦距 计算 物长 与 物距 的 比值');
    this.mFocalLength = focalLength;
    this.mSensorPhysicalSize = sensorPhysicalSize;
    const physicsDistanceAndImageDistance = DecoderCameraParameters.getPhysicsDistanceAndImageDistance(focalLength, this.mFocusDistanceMM);
    if (physicsDistanceAndImageDistance == null)
      return false;
    this.mPhysicsDistance = physicsDistanceAndImageDistance.first;
    this.mImageDistance = physicsDistanceAndImageDistance.second;
    //物长objectRealWorldWidth / 物距mPhysicsDistance = 像长mSensorPhysicalSize.getWidth() / 像距physicsDistanceAndImageDistance.second
    this.mObjectSizeDistanceRadio = sensorPhysicalSize.width / this.mImageDistance;
    return true;
  }

  /** 由（1）、1 / 焦距 = 1 / 物距 + 1 / 像距
   * （2）、物距 + 像距 = 对焦距离
   * （3）物距 > 像距
   * 得: - 物距 * 物距 + 对焦距离 * 物距 - 焦距*对焦距离 = 0(一元二次方程)
   * 已知对焦距离和焦距，求解一元二次方程
   *
   * @param focalLength     焦距
   * @param focusDistanceMM 物距+像距
   * @return 物距 和 像距
   */
  public static getPhysicsDistanceAndImageDistance(focalLength: number, focusDistanceMM: number): PairNumber | null {
    let physicsDistance: number; //物距
    let imageDistance: number;   //像距
    //根据一元二次方程的判别式,方程有两个不相等的实数根，所以 FocusDistanceMM * FocusDistanceMM - 4 * focalLength * FocusDistanceMM > 0
    const discriminant = focusDistanceMM * focusDistanceMM - 4 * focalLength * focusDistanceMM;
    if (discriminant < 0)
      return null;
    const sqrt = Math.sqrt(discriminant);
    const x1 = (focusDistanceMM + sqrt) / 2;
    const x2 = focusDistanceMM - x1;
    imageDistance = Math.min(x1, x2);
    physicsDistance = Math.max(x1, x2);
    return { first: physicsDistance, second: imageDistance };
  }

  /**
   * ljj worker只需要getImageSize的结果即可解码，不需要将整个DecoderCameraParameters对象postMessage到worker
   *
   * 裁减区域内 的 被扫描图像 宽高有多少个像素点
   * （已知 被扫描图像 每毫米有PixelsPerMillimeter个像素点，先算出 裁减区域内 的 被扫描图像 宽cropRealWorldPixelsWidth 和高cropRealWorldHeight，
   *  可以算出裁减区域内 的 被扫描图像 宽 = cropRealWorldPixelsWidth * PixelsPerMillimeter 和 高 = cropRealWorldHeight * PixelsPerMillimeter
   * 问题1：需要返回的的Size是否需要旋转
   *
   * @return
   */
  public getImageSize(): Size {
    // assert (mPhysicsDistance >0) : "未计算出物距";
    if (!(this.mPhysicsDistance > 0)) { throw new Error('未计算出物距') as Error }

    const zoom = this.getZoom() / 100.0;
    //传感器上图像的宽有多少个像素点
    let pixelsWidth = Math.max(this.mPreviewSize.width, this.mPreviewSize.height);
    let pixelsHeight = Math.min(this.mPreviewSize.width, this.mPreviewSize.height);

    //拿到传感器尺寸宽高比时，可以对图像裁切做更精准的处理
    let sensorPixelWidthIncrease = 1;
    if (this.mSensorPixelSizeRatio > 0) {
      const previewSizeRatio = pixelsWidth / (pixelsHeight as number);
      if (this.mSensorPixelSizeRatio - previewSizeRatio > 0.01) {
        //预览图像最大的方向被裁剪了一点，通过计算机型还原
        sensorPixelWidthIncrease = (pixelsHeight * this.mSensorPixelSizeRatio) / pixelsWidth;
        //                pixelsWidth = (int) (pixelsHeight * mSensorPixelSizeRatio);
      }
    }

    //投放到预览view中后，是否经过拉伸后，裁切掉了一部分，是就要另外再补(只处理最大边)
    const landscapeScreenWidth = Math.max(this.mScreenSize.width, this.mScreenSize.height); //采用横屏，跟相机一致（相机默认是横的，宽比高通常是4：3或3：2）
    const landscapeScreenHeight = Math.min(this.mScreenSize.width, this.mScreenSize.height);
    const landscapeScreenAspetRadio = landscapeScreenWidth / (landscapeScreenHeight as number);
    const newPreviewSizeRatio = pixelsWidth / (pixelsHeight as number); //这里的宽度(最大边，已经经过一次纠正的了)
    let viewPixelWidthIncrease = 1;
    if (newPreviewSizeRatio - landscapeScreenAspetRadio > 0.01) {
      //预览图像最大的方向上被裁剪了一点，通过计算机型还原（通常是平板，并且该设备的宽高比较接近）
      viewPixelWidthIncrease = newPreviewSizeRatio / landscapeScreenAspetRadio;
    }
    if (viewPixelWidthIncrease > 1 || sensorPixelWidthIncrease > 1) {
      pixelsWidth = Math.floor(pixelsWidth * Math.max(viewPixelWidthIncrease, sensorPixelWidthIncrease));
    }

    //视野宽度，能看到的物体的最大宽度（不是对角线，而是最长的边），单位毫米，
    const objectRealWorldWidth = this.mPhysicsDistance * this.mObjectSizeDistanceRadio;

    //裁减区域的高 与 传感器上图像的宽(最大边) 之比（裁切区域的宽会比高小，这是六角形摆放角度导致的）
    const cropScale = DecoderCameraParameters.rectHeight(this.mImageCrop) / (pixelsWidth as number);

    //裁减区域物长，单位毫米
    let cropRealWorldHeight = objectRealWorldWidth / zoom * cropScale;
    let cropRealWorldWidth = cropRealWorldHeight;
    if (DecoderCameraParameters.rectHeight(this.mImageCrop) != DecoderCameraParameters.rectWidth(this.mImageCrop)) {
      cropRealWorldWidth = cropRealWorldHeight * DecoderCameraParameters.rectWidth(this.mImageCrop) / DecoderCameraParameters.rectHeight(this.mImageCrop);
    }

    //裁减区域的物体宽高有多少个像素点
    let cropRealWorldPixelsWidth: number;
    let cropRealWorldPixelsHeight: number;
    //0°是正常竖屏，90°是设备向左倾倒；270°是向右倾倒
    if (this.mScreenOrientation % 180 == 0) {
      cropRealWorldPixelsWidth = Math.round(cropRealWorldHeight * DecoderCameraParameters.PixelsPerMillimeter);
      cropRealWorldPixelsHeight = Math.round(cropRealWorldWidth * DecoderCameraParameters.PixelsPerMillimeter);
    } else {
      cropRealWorldPixelsWidth = Math.round(cropRealWorldWidth * DecoderCameraParameters.PixelsPerMillimeter);
      cropRealWorldPixelsHeight = Math.round(cropRealWorldHeight * DecoderCameraParameters.PixelsPerMillimeter);
    }
    const cropRealWorldPixels: Size = { width: cropRealWorldPixelsWidth, height: cropRealWorldPixelsHeight };

    // todo DecoderCameraManager.getInstance().setCropRealWorldPixels(cropRealWorldPixels);

    console.info(DecoderCameraParameters.TAG, 'mFocalLength:' + this.mFocalLength);
    console.info(DecoderCameraParameters.TAG, 'mSensorPhysicalSize:' + JSON.stringify(this.mSensorPhysicalSize));
    console.info(DecoderCameraParameters.TAG, 'mImageDistance:' + this.mImageDistance);
    console.info(DecoderCameraParameters.TAG, 'mFocusDistanceMM:' + this.mFocusDistanceMM);
    console.info(DecoderCameraParameters.TAG, 'mPhysicsDistance:' + this.mPhysicsDistance);
    console.info(DecoderCameraParameters.TAG, 'mObjectWidthScale:' + this.mObjectSizeDistanceRadio);
    console.info(DecoderCameraParameters.TAG, 'cropRealWorldPixelsWidth（裁减区域的物体宽高有多少个像素点）:' + cropRealWorldPixelsWidth);

    console.info(DecoderCameraParameters.TAG, 'zoom:' + zoom);
    console.info(DecoderCameraParameters.TAG, 'pixelsWidth(传感器上图像的宽有多少个像素点):' + pixelsWidth);
    console.info(DecoderCameraParameters.TAG, 'cropScale(裁减区域的宽 与 传感器上图像的宽 之比):' + cropScale);
    console.info(DecoderCameraParameters.TAG, 'objectRealWorldWidth（总物长，单位毫米）:' + objectRealWorldWidth);
    console.info(DecoderCameraParameters.TAG, 'cropRealWorldWidth（裁减区域物长，单位毫米）:' + cropRealWorldWidth);
    console.info(DecoderCameraParameters.TAG, 'mSensorPixelSizeRatio:' + this.mSensorPixelSizeRatio);

    return cropRealWorldPixels;
  }

  /**
   * 设置距离最佳对焦
   *
   * @param focusDistanceMM
   */
  public setFocusDistanceMM(focusDistanceMM: number): boolean {
    if (focusDistanceMM > DecoderCameraParameters.MinFocusDistancMM && focusDistanceMM < DecoderCameraParameters.MaxFocusDistancMM) {
      // DecoderCameraManager.getInstance().setFocusDistanceMM(focusDistanceMM);
      this.mFocusDistanceMM = focusDistanceMM;
      if (!this.calculatePhysicsWidthScale(this.mFocalLength, this.mSensorPhysicalSize)) {
        if (this.mFocalLength != null) {
          this.mPhysicsDistance = focusDistanceMM - this.mFocalLength;
        } else {
          this.mPhysicsDistance = focusDistanceMM;
        }
      }
      return true;
    }
    return false;
  }

  public getPhysicsDistance(): number {
    return this.mPhysicsDistance;
  }

  public getPreviewSize(): Size {
    return this.mPreviewSize;
  }

  public getImageCrop(): RectLike {
    return this.mImageCrop;
  }

  public getZoom(): number {
    return this.mZoom;
  }

  public setZoom(zoom: number): void {
    this.mZoom = zoom;
  }

  public getScreenOrientation(): number {
    return this.mScreenOrientation;
  }

  public getPhysicsScale(): number {
    return this.mObjectSizeDistanceRadio;
  }

  // ===== Helpers =====
  private static rectWidth(r: RectLike): number { return Math.abs(r.right - r.left); }
  private static rectHeight(r: RectLike): number { return Math.abs(r.bottom - r.top); }
}

// ====== 辅助类型（替代 Android Rect / SizeF / Pair）======

// ArkTS 常用 Size { width:number, height:number } 在项目中已广泛使用，直接复用。

export interface RectLike {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

export interface PairNumber {
  first: number;
  second: number;
}