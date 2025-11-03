import { AbsDecoder } from './AbsDecoder';
import image from '@ohos.multimedia.image';
import { DecodeResultBean } from '../bean/DecodeResultBean';
import { BarcodeFormat, BinaryBitmap, DecodeHintType ,HybridBinarizer ,MultiFormatReader , RGBLuminanceSource } from '@ohos/zxing';
import { Logger } from 'common';
import { BsDecoderTypes } from '../bean/BsDecoderTypes';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'ZXingDecoder'
export class ZXingDecoder extends AbsDecoder {
  constructor(interval: number) {
    super(interval);
    this.decoder = new MultiFormatReader();
    const hints: Map<DecodeHintType, Array<BarcodeFormat>> = new Map()
    hints.set(DecodeHintType.POSSIBLE_FORMATS, [BarcodeFormat.AZTEC,
      BarcodeFormat.DATA_MATRIX,
      BarcodeFormat.QR_CODE,
      BarcodeFormat.PDF_417,
      BarcodeFormat.RSS_14,
      BarcodeFormat.UPC_A,
      BarcodeFormat.UPC_E,
      BarcodeFormat.EAN_13,
      BarcodeFormat.EAN_8,
      BarcodeFormat.CODE_39,
      BarcodeFormat.CODE_93,
      BarcodeFormat.CODE_128,
      BarcodeFormat.ITF,
      BarcodeFormat.CODABAR])
    this.decoder.setHints(hints);
  }

  private decoder:MultiFormatReader|null;

  public decode(int32Array: Int32Array,width:number,height:number): DecodeResultBean|null {
    if (this.isRunning()) {
      return null;
    }
    if(!this.decoder) return null;
    // if(this.mImageCrop==null || this.mScreenOrientation ==-1){
    //   Logger.error(TAG,"需要设置Crop跟屏幕方向");
    //   return null;
    // }
    let now = Date.now();
    if (now - this.mLastDecodeTime > this.mDecodeInterval) {
      this.mLastDecodeTime = now;
      try {
        this.mIsRunning = true;
        let timeBeginDecode = Date.now();

        const luminanceSource = new RGBLuminanceSource(int32Array, width, height)
        let luminanceSourceTime = Date.now();
        Logger.info (TAG, `ZXing,RGBLuminanceSource,耗时:${(luminanceSourceTime - timeBeginDecode)}`);

        const binaryBitmap = new BinaryBitmap(new HybridBinarizer(luminanceSource))
        let binaryBitmapTime = Date.now();
        Logger.info (TAG, `ZXing,BinaryBitmap,耗时:${(binaryBitmapTime - luminanceSourceTime)}`);


        let result = this.decoder.decode(binaryBitmap)
        let decodeTime = Date.now();
        Logger.info (TAG, `ZXing,decode,耗时:${(decodeTime - binaryBitmapTime)}`);

        let timeEndDecode = Date.now();
        if(result){
          let text = result.getText()
          if(text && text.length > 0){
            let bean = new DecodeResultBean();
            bean.setDecodeType(BsDecoderTypes.ZXing);
            bean.setElapsedTimeTick((timeEndDecode - timeBeginDecode) * 10000);
            bean.setSuccess(true);
            bean.setCode(text);
            Logger.info (TAG, `ZXing解码成功:${text},耗时:${(timeEndDecode - timeBeginDecode)}`);
            return bean;
          }
        }
        this.decoder.reset()
      }catch (err) {
        const error = err as BusinessError;
        Logger.info (TAG, `ZXing解码异常:${error}`);
        this.mIsRunning = false;
      }
      finally {
        this.mIsRunning = false;
      }
    }
    return null;
  }

  public release(): void {
    if (this.decoder != null) {
      this.decoder = null;
    }
    this.mImageCrop = null;
    this.mScreenOrientation = -1;
  }
}