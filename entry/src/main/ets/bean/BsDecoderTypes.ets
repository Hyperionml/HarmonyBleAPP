/**
 * 解码器类型枚举
 */
export enum BsDecoderTypes {
  Baoshen = 0,
  ZXing = 1
}

export function getBsDecoderTypeCode(type: BsDecoderTypes): number {
  return type;
}
