import { image } from '@kit.ImageKit';
import { AbsDecoder } from './AbsDecoder';
import { DecoderCameraParameters } from './DecoderCameraParameters';
import { DecodeResultBean, DecodeResultData } from '../bean/DecodeResultBean';
import { AppSetting } from '../common/AppSetting';
import { DeviceInfoUtils } from '../common/DeviceInfoUtils';
import { BsDecoderTypes } from '../bean/BsDecoderTypes';
import { ValueUtils } from 'common';
import { getCurrentProductType, ProductType } from '../common/ProductType';
import { CodeTypes, Decoder, ImageFormat, Options, PerformanceMode } from 'decoder';
import { DecodeMode } from 'decoder';


export class BaoshenDecoder extends AbsDecoder {
  static readonly TAG: string = 'BaoshenDecoder';

  private decoder: Decoder|null = null;
  private options: Options|null = null;

  private isEnabledHyperfocalDistance?: boolean = undefined;
  private zoomSizes?: number[];
  private decodeImageSize?: Size;
  private isQTOpertionChanged: boolean = false;

  constructor(interval: number) {
    super(interval);

    // const setting = AppSetting.getInstance(); // TODO: 适配鸿蒙的设置获取方式
    // this.isEnabledHyperfocalDistance = setting.existedIsEnabledHyperfocalDistance() ?
    // setting.getIsEnabledHyperfocalDistance() : DeviceInfoUtils.isHighPerformanceDevice();

    this.isEnabledHyperfocalDistance = true;
    const isSupportPrintQuality = getCurrentProductType() === ProductType.Secrecy;

    this.options = Decoder.createOption();

    this.options.setDecodeMode(DecodeMode.Local);                                     //解码方式，本地
    this.options.setCodeTypes([CodeTypes.First,CodeTypes.Second,CodeTypes.Third]);    //支持的QT码版本，正式版应该不支持第三方,CodeTypes.Other
    if (this.isEnabledHyperfocalDistance) {
      this.options.setDimensions([1.0, 1.2, 0.8]);
    } else {
      this.options.setDimensions([1.0, 1.2, 0.8, 0.6]);//0.6其实没什么用的
    }
    this.options.setDimensions([1.0, 1.2, 0.8]);                                      //维度，现在的相机性能都比较高了，可以用0.8跟1.2了
    this.options.setPerformanceMode(PerformanceMode.Hard);                            //模式，Hard
    this.options.setIsEnabledQC(isSupportPrintQuality);                               //是否开启品检
    this.options.setDetectCount(isSupportPrintQuality ? 3 : 1);                       //寻找定位点个数
    this.decoder = new Decoder(this.options);//目前新的逻辑，创建Decoder时，就会配置一些参数，所以要改为先创建，再设置options
  }

  public override setDecoderCameraParameters(parameters: DecoderCameraParameters): void {
    super.setDecoderCameraParameters(parameters);
    // const setting = AppSetting.getInstance(); // TODO: 适配鸿蒙的设置获取方式
    // this.isEnabledHyperfocalDistance = setting.existedIsEnabledHyperfocalDistance() ?
    // setting.getIsEnabledHyperfocalDistance() : DeviceInfoUtils.isHighPerformanceDevice();

    //ljj: setDecoderCameraParameters 就用到一个 parameters.getImageSize() worker应该postMessage这个即可
    // this.setDecodeImageSize(parameters.getImageSize());
  }

  public release(): void {
    if (this.decoder != null) {
      this.decoder.release();
      this.decoder = null;
      this.options = null;
    }
    this.mImageCrop = null;
    this.mScreenOrientation = -1;
  }

  public decode(uint8Array: Uint8Array,width:number,height:number): DecodeResultBean|null {
    if (this.decoder == null || width === 0 || height === 0) {
      return null;
    }
    if (this.mIsRunning) {
      return null;
    }
    if (this.mImageCrop == null || this.mScreenOrientation === -1) {
      console.error(BaoshenDecoder.TAG, '需要设置Crop跟屏幕方向');
      //return null;
    }
    if (this.zoomSizes == null || this.zoomSizes.length < 3) {
      console.error(BaoshenDecoder.TAG, '需要设置缩进尺寸');
      return null;
    }
    const now = Date.now();
    let bean: DecodeResultBean | null = null;
    if (now - this.mLastDecodeTime > this.mDecodeInterval) {
      this.mLastDecodeTime = now;
      try {
        //const size = this.mParameters!.getImageSize();//todo ljj mParameters.getImageSize() 暂时用图片大小代替
        const size:Size = { width:width,height:height };
        const options = this.decoder.getOptions();
        console.info(BaoshenDecoder.TAG, 'decode size:' + JSON.stringify(size));
        if (size.width < 150 || size.height < 150) {
          return null;
        }
        //由于对焦距离没有做限制，导致图像缩放过大
        if (this.isQTOpertionChanged) {
          options.setZoomSizes(this.zoomSizes);
          this.isQTOpertionChanged = false;
        }

        if (this.isEnabledHyperfocalDistance) {
          options.setReverseFrequency(8);//大概1到2秒会执行一次
        } else {
          options.setReverseFrequency(5);
        }

        this.mIsRunning = true;
        const timeBeginDecode = Date.now();

        const decodeStart = Date.now();

        let matFormat:ImageFormat = ImageFormat.Rgba;
        let result = this.decoder.decode(uint8Array,matFormat,width,height);

        const decodeTime = Date.now() - decodeStart;
        if (decodeTime > 300) {
          console.error(BaoshenDecoder.TAG, '解码时间过长:' + decodeTime);//纯解码时长
        }

        const timeEndDecode = Date.now();//解码总时长(包括Java与C++的内存转化)
        bean = new DecodeResultBean();
        bean.setElapsedTimeTick((timeEndDecode - timeBeginDecode) * 10000);
        bean.setDecodeType(BsDecoderTypes.Baoshen);

        if (result != null) {
          bean.setSuccess(result.isSuccess());
          if (result.getCodeType() != CodeTypes.Other) {
            if (result.isSuccess()) {
              const resultData = result.getResultData();
              if (resultData != null && resultData.length > 0) {
                bean.setCode(ValueUtils.toLong(resultData).toString());
              } else {
                let index = 0;
                const codeDataList: Uint8Array[] = [];
                while (true) {
                  const codeData = result.getCodeData(index);
                  if (codeData == null || codeData.length === 0) {
                    break;
                  }
                  codeDataList.push(codeData);
                  index++;
                }
                if (codeDataList.length > 0) {
                  bean.setCodeDataList(codeDataList);
                }
              }
            }
          } else {
              bean.setOtherType(result.getOtherType());
              bean.setCodeType(result.getCodeType());
              bean.setOtherResult(result.getOtherResult());
              bean.setExtData(result.getExtData());
          }

          //let successIndex = -1;
          // const blockCount = result.getBlockDetailsCount ? result.getBlockDetailsCount() : 0;
          // if (blockCount > 0) {
          //   for (let i = 0; i < blockCount; i++) {
          //     if (result.isSuccess(i)) {
          //       successIndex = i;
          //       break;
          //     }
          //   }
          //   if (successIndex > -1) {
          //     bean.setCodeType(result.getCodeType());
          //     bean.setHeaderErrorBitsCount(result.getHeaderErrorBitsCount ? result.getHeaderErrorBitsCount(successIndex) : 0);
          //     bean.setHeaderErrorBytesCount(result.getHeaderErrorBytesCount ? result.getHeaderErrorBytesCount(successIndex) : 0);
          //     bean.setContentErrorBitsCount(result.getContentErrorBitsCount ? result.getContentErrorBitsCount(successIndex) : 0);
          //     bean.setContentErrorBytesCount(result.getContentErrorBytesCount ? result.getContentErrorBytesCount(successIndex) : 0);
          //   }
          //
          //   if (options != null && options.getIsEnabledQC()) { // TODO: 实现品检选项检查
          //       for (let i = 0; i < blockCount; i++) {
          //           if (result.isSuccess(i)) {
          //               PrintQualityInfo qualityInfo = new PrintQualityInfo(result.getErrorFixedDotCount(i),
          //                       result.getHeaderErrorBitsCount(i),
          //                       result.getContentErrorBitsCount(i),
          //                       result.getDotPixelCounts(i)); // TODO: 实现品质信息
          //               bean.getPrintQualityList().add(qualityInfo);
          //           }
          //       }
          //   }
          // }

          const logs: string[] = [];
          //logs.push(`解码${(result.isSuccess() ? '成功' : '失败')},C++耗时:${result.getElapsed ? result.getElapsed() : 0},全链路耗时:${(Date.now() - timeBeginDecode)},尺度:${result.getDimension ? result.getDimension().toFixed(1) : '0.0'},缩进倍率:${result.getZoomPercent ? result.getZoomPercent() : 0},检测(缩图)时长:${result.getTestTime ? result.getTestTime() : 0}`);

          if (!result.isSuccess() && result.getErrorDescription && result.getErrorDescription().length > 0) {
            logs.push(result.getErrorDescription());
          }
          const logList = result.getLogs ? result.getLogs() : null;
          if (logList != null) {
            for (const line of logList) {
              logs.push(line);
            }
          }
          logs.push(`纯解码耗时(鸿蒙):${timeEndDecode-decodeStart} , 全程耗时(鸿蒙):${Date.now() - decodeStart}\n`);
          // if (successIndex > -1) {
          //   logs.push(`种类:${result.getCodeType ? result.getCodeType().toString() : 'Unknown'} , `);
          //   logs.push(`成像缩放倍率:${result.getImageScale ? result.getImageScale(successIndex).toFixed(4) : '0.0000'} , `);
          //
          //   if (result.getHeaderErrorBitsCount && result.getHeaderErrorBitsCount(successIndex) > 0) {
          //     logs.push(`纠错点数(Header)数,${result.getHeaderErrorBitsCount(successIndex)} bits,${result.getHeaderErrorBytesCount ? result.getHeaderErrorBytesCount(successIndex) : 0} bytes, `);
          //   }
          //   if (result.getContentErrorBitsCount && result.getContentErrorBitsCount(successIndex) > 0) {
          //     logs.push(`纠错点数(Content)数,${result.getContentErrorBitsCount(successIndex)} bits,${result.getContentErrorBytesCount ? result.getContentErrorBytesCount(successIndex) : 0} bytes`);
          //   }
          // }
          // const setting = AppSetting.getInstance(); // TODO: 适配鸿蒙的设置获取
          // if (result.isSuccess() && setting != null && setting.getIsShowDecodeDetails()) {
          //   bean.setDecodeDetails(logs.join(' , '));
          //   //com.baoshen.common.Utils.toast(logs.toString(),BaseApp.getInstance(),true);
          // }

          // if (BuildConfig.DEBUG) { // TODO: 适配鸿蒙的调试标志
          // console.warn(BaoshenDecoder.TAG, logs.join(' , '));
          // }
          result.release();
        }
      } finally {
        this.mIsRunning = false;
      }
    }
    return bean;
  }

  //ljj worker只需要post这个Size结果即可
  public setDecodeImageSize(size: Size): void {
    if (this.zoomSizes == null || this.decodeImageSize == null || this.decodeImageSize.width !== size.width || this.decodeImageSize.height !== size.height) {
      this.decodeImageSize = size;
      if (this.isEnabledHyperfocalDistance) {
        //const zooms = [100, 125, 150, 75];
        const zooms = [100, 125, 75];
        const data: number[] = new Array(zooms.length * 3);//由于放大150倍的效果非常不明显，又非常耗费资源，所以暂时不考虑
        for (let i = 0; i < zooms.length; i++) {
          const zoomPercent = zooms[i];
          const zoomWidth = size.width * zoomPercent / 100;
          const zoomHeight = size.height * zoomPercent / 100;
          data[i * 3] = zoomPercent;
          data[i * 3 + 1] = Math.max(160, Math.min(1500, zoomWidth));
          data[i * 3 + 2] = Math.max(160, Math.min(1500, zoomHeight));
        }
        this.zoomSizes = data;
      } else {
        this.zoomSizes = [100, size.width, size.height];
      }
      this.isQTOpertionChanged = true;
    }
  }
}