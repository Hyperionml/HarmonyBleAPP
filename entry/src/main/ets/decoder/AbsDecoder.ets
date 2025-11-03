import { DecodeResultBean } from "../bean/DecodeResultBean";
import { DecoderCameraParameters,RectLike } from "./DecoderCameraParameters";
import { image } from '@kit.ImageKit';
/**
 *  -
 │  - 定义解码器的标准接口
 │  - 管理解码状态和参数
 │  - 提供图像裁剪和屏幕方向支持
 *  -
 */
export abstract class AbsDecoder {
  protected mIsRunning:boolean = false
  protected mLastDecodeTime:number = 0
  protected mDecodeInterval:number;
  protected mImageCrop:RectLike|null = null;// top left right bottom
  protected mScreenOrientation :number = -1;
  protected mParameters:DecoderCameraParameters | null = null;

  constructor(interval:number) {
    this.mDecodeInterval = interval
  }

  public abstract decode(int32Array: Int32Array|Uint8Array,width:number,height:number):DecodeResultBean|null;

  public abstract release(): void;

  public getScreenOrientation():number {
    return this.mScreenOrientation;
  }

  public isRunning():boolean  {
    return this.mIsRunning;
  }

  setDecoderCameraParameters(parameters: DecoderCameraParameters){
    this.mParameters = parameters;
    this.mScreenOrientation = parameters.getScreenOrientation();
    this.mImageCrop = parameters.getImageCrop();
  }

  public getDecoderCameraParameters():DecoderCameraParameters | null{
    return this.mParameters;
  }
}