export class PhotoPageData {
  public errorImg?: Resource;
  public rightImg?: Resource;
  public bluetoothImg?: Resource;

  constructor(
  errorImg?: Resource, // 错误示例图
  rightImg?: Resource, // 正确示例图
    bluetoothImg?: Resource,
  // 正确示例图
  ) {
  this.errorImg = errorImg;
  this.rightImg = rightImg;
  this.bluetoothImg = bluetoothImg;
}
}

export function initGuidePages():  PhotoPageData[] {
  return [
    new PhotoPageData($r('app.media.guide_error_1'), $r('app.media.guide_right_1')),
    new PhotoPageData($r('app.media.guide_error_2'), $r('app.media.guide_right_2')),
    new PhotoPageData($r('app.media.guide_error_3'), $r('app.media.guide_right_3')),
    new PhotoPageData($r('app.media.guide_error_4'), $r('app.media.guide_right_4')),
    new PhotoPageData($r('app.media.guide_error_5'), $r('app.media.guide_right_5')),
  ];
}

export function initBlueToothGuidePage(): PhotoPageData[] {
  return[
    new PhotoPageData($r('app.media.bluetooth_guide1')),
    new PhotoPageData($r('app.media.bluetooth_guide2')),
    new PhotoPageData($r('app.media.bluetooth_guide3')),
    new PhotoPageData($r('app.media.bluetooth_guide4')),
  ]
}