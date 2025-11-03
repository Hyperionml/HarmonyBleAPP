import { Utils } from 'common';
import { BsDecoderTypes } from './BsDecoderTypes';
import { CodeTypes, PrintQuality, BarcodeFormat } from 'decoder';

/**
 * 解码结果数据封装类
 * 用于存储和传递解码操作的结果信息
 */
export class DecodeResultBean {
  private static readonly KEY_ISSUCCESS: string = "IsSuccess";
  private static readonly KEY_CODE: string = "Code";
  private static readonly KEY_CODE_DATA_LIST: string = "CodeDataList";
  private static readonly KEY_DECODE_TIME: string = "DecodeTime";

  private elapsedTimeTick: number = 0;
  private reason: string = '';
  private isSuccess: boolean = false;
  private code: string = '';
  private otherResult: string = '';
  private decodeType: BsDecoderTypes = BsDecoderTypes.Baoshen;
  private codeDataList: Uint8Array[] = [];
  private otherType: BarcodeFormat | null = null;
  private codeType: CodeTypes | null = null;
  private extData: Uint8Array | null= null;
  private printQualityList: PrintQuality[] = [];
  private headerErrorBitsCount: number = 0;
  private headerErrorBytesCount: number = 0;
  private contentErrorBitsCount: number = 0;
  private contentErrorBytesCount: number = 0;
  private decodeDetails: string = '';

  constructor() {
    this.printQualityList = [];
  }

  public getElapsedTimeTick(): number {
    return this.elapsedTimeTick;
  }

  public setElapsedTimeTick(elapsedTimeTick: number): void {
    this.elapsedTimeTick = elapsedTimeTick;
  }

  public getReason(): string {
    return this.reason;
  }

  public setReason(reason: string): void {
    this.reason = reason;
  }

  public IsSuccess(): boolean {
    return this.isSuccess;
  }

  public setSuccess(success: boolean): void {
    this.isSuccess = success;
  }

  public getCode(): string {
    return this.code;
  }

  public setCode(code: string): void {
    this.code = code;
  }

  public getDecodeType(): BsDecoderTypes {
    return this.decodeType;
  }

  public setDecodeType(value: BsDecoderTypes): void {
    this.decodeType = value;
  }

  public getCodeDataList(): Uint8Array[] {
    return this.codeDataList;
  }

  public setCodeDataList(codeDataList: Uint8Array[]): void {
    this.codeDataList = codeDataList;
  }

  public static toRouterParams(bean: DecodeResultBean): Record<string, Object> {
    // 类型检查替代Assert
    if (!bean) {
      throw new Error("bean cannot be null");
    }

    let code = bean.getCode();
    if (code != null && code.length > 16) {
      code = Utils.substring(code, code.length - 16);
    }

    const params: Record<string, Object> = {};
    params[DecodeResultBean.KEY_DECODE_TIME] = String(bean.getElapsedTimeTick() / 10000000);
    params[DecodeResultBean.KEY_CODE] = code;
    params[DecodeResultBean.KEY_ISSUCCESS] = bean.IsSuccess();

    const codeDataList = bean.getCodeDataList();
    if (codeDataList != null && codeDataList.length > 0) {
      for (let i = 0; i < codeDataList.length; i++) {
        // Uint8Array转为数组以便传递
        params[DecodeResultBean.KEY_CODE_DATA_LIST + i] = Array.from(codeDataList[i]);
      }
    }

    return params;
  }

  public static fromRouterParams(params: Record<string, Object>): DecodeResultBean {
    const bean = new DecodeResultBean();

    bean.setCode(params[DecodeResultBean.KEY_CODE] as string || '');
    bean.setSuccess(params[DecodeResultBean.KEY_ISSUCCESS] as boolean || false);

    const elapsedTimeSecondStr = params[DecodeResultBean.KEY_DECODE_TIME] as string;
    if (elapsedTimeSecondStr && elapsedTimeSecondStr !== '') {
      const elapsedTime = Math.floor(parseFloat(elapsedTimeSecondStr) * 10000000);
      bean.setElapsedTimeTick(elapsedTime);
    }

    const codeDataList: Uint8Array[] = [];
    for (let i = 0; i < 10000; i++) {
      const codeData = params[DecodeResultBean.KEY_CODE_DATA_LIST + i] as number[];
      if (!codeData || codeData.length === 0) {
        break;
      }
      // 数组转回Uint8Array
      codeDataList.push(new Uint8Array(codeData));
    }

    if (codeDataList.length > 0) {
      bean.setCodeDataList(codeDataList);
    }

    return bean;
  }

  public getCodeType(): CodeTypes | null {
    return this.codeType;
  }

  public setCodeType(codeType: CodeTypes | null): void {
    this.codeType = codeType;
  }

  public getHeaderErrorBitsCount(): number {
    return this.headerErrorBitsCount;
  }

  public setHeaderErrorBitsCount(headerErrorBitsCount: number): void {
    this.headerErrorBitsCount = headerErrorBitsCount;
  }

  public getHeaderErrorBytesCount(): number {
    return this.headerErrorBytesCount;
  }

  public setHeaderErrorBytesCount(headerErrorBytesCount: number): void {
    this.headerErrorBytesCount = headerErrorBytesCount;
  }

  public getContentErrorBitsCount(): number {
    return this.contentErrorBitsCount;
  }

  public setContentErrorBitsCount(contentErrorBitsCount: number): void {
    this.contentErrorBitsCount = contentErrorBitsCount;
  }

  public getContentErrorBytesCount(): number {
    return this.contentErrorBytesCount;
  }

  public setContentErrorBytesCount(contentErrorBytesCount: number): void {
    this.contentErrorBytesCount = contentErrorBytesCount;
  }

  public getPrintQualityList(): PrintQuality[] {
    return this.printQualityList;
  }

  public setPrintQualityList(printQualityList: PrintQuality[]): void {
    this.printQualityList = printQualityList;
  }

  public getOtherResult(): string {
    return this.otherResult;
  }

  public setOtherResult(otherResult: string): void {
    this.otherResult = otherResult;
  }

  public getExtData(): Uint8Array|null {
    return this.extData;
  }

  public setExtData(extData: Uint8Array|null): void {
    this.extData = extData;
  }

  public getOtherType(): BarcodeFormat | null {
    return this.otherType;
  }

  public setOtherType(otherType: BarcodeFormat | null): void {
    this.otherType = otherType;
  }

  public getDecodeDetails(): string {
    return this.decodeDetails;
  }

  public setDecodeDetails(decodeDetails: string): void {
    this.decodeDetails = decodeDetails;
  }

  //worker内部转换成DecodeResultData后postMessage
  public toPlainObject(): DecodeResultData {
    return {
      elapsedTimeTick: this.elapsedTimeTick,
      reason: this.reason,
      IsSuccess: this.isSuccess,
      code: this.code,
      otherResult: this.otherResult,
      decodeType:this.decodeType,
      codeDataList: this.codeDataList,
      extData: this.extData,
      headerErrorBitsCount: this.headerErrorBitsCount,
      headerErrorBytesCount: this.headerErrorBytesCount,
      contentErrorBitsCount: this.contentErrorBitsCount,
      contentErrorBytesCount: this.contentErrorBytesCount,
      decodeDetails: this.decodeDetails,
      codeType:this.codeType
    };
  }

  //接收到worker的消息后，转换成DecodeResultBean
  public static fromPlainObject(data: DecodeResultData): DecodeResultBean {
    const bean = new DecodeResultBean();
    bean.elapsedTimeTick = data.elapsedTimeTick;
    bean.reason = data.reason;
    bean.isSuccess = data.IsSuccess;
    bean.code = data.code;
    bean.otherResult = data.otherResult;
    bean.decodeType = data.decodeType;
    bean.codeDataList = data.codeDataList;
    bean.extData = data.extData;
    bean.headerErrorBitsCount = data.headerErrorBitsCount;
    bean.headerErrorBytesCount = data.headerErrorBytesCount;
    bean.contentErrorBitsCount = data.contentErrorBitsCount;
    bean.contentErrorBytesCount = data.contentErrorBytesCount;
    bean.decodeDetails = data.decodeDetails;
    bean.codeType = data.codeType;
    return bean;
  }
}

// 定义可序列化的数据接口，供worker postMessage
export interface DecodeResultData {
  IsSuccess: boolean;
  code: string;
  decodeType:BsDecoderTypes;
  elapsedTimeTick: number;
  reason: string;
  codeDataList: Uint8Array[];
  otherResult: string;
  extData: Uint8Array|null;
  headerErrorBitsCount: number;
  headerErrorBytesCount: number;
  contentErrorBitsCount: number;
  contentErrorBytesCount: number;
  decodeDetails: string;
  codeType:CodeTypes| null;
}