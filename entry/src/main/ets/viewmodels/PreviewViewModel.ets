/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 ("the License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { curves, display } from '@kit.ArkUI';
import { camera } from '@kit.CameraKit';
import WindowUtil from '../utils/WindowUtil';
import { image } from '@kit.ImageKit';
import { EventManager, Level, Logger } from 'common';
import { AppEvent } from '../common/event/AppEvent';
import { AppEventType } from '../common/event/AppEventType';
import { JSON5 } from '@wolfx/json5';

const TAG = 'PreviewViewModel';
/**
 * States and methods related to preview.
 */
class PreviewViewModel {
  private uiContext: UIContext;

  private scanBoxInfo :image.Region | null = null;
  getScanBoxInfo(){ return this.scanBoxInfo }
  setScanBoxInfo(value:image.Region){
    this.scanBoxInfo = value;
    Logger.info(TAG,`ScanBoxInfo(value):${JSON5.stringify(value)}`)
    if(!this.getReady())
      this.setScanBoxReady();
  }

  // [Start isFront]
  isFront: boolean = false;
  // [StartExclude isFront]
  xComponentController: XComponentController = new XComponentController();
  surfaceId: string = '';
  previewSize: Size = WindowUtil.getMaxDisplaySize();
  rates?: number[] = [];
  currentRate: number = 0;
  blurRadius: number = 0;
  blurRotation: RotateOptions = { y: 0.5, angle: 0};

  private mCheckList: boolean[] = [false, false];
  private static readonly CHECK_SCAN_BOX = 0;
  private static readonly CHECK_CONTROLLER = 1;
  public resetChecked(): void {
    this.mCheckList.fill(false);
  }
  private setCheck(index: number, value: boolean): void {
    this.mCheckList[index] = value;
    if(this.getReady())
      EventManager.async('PreviewReady',new AppEvent(AppEventType.PreviewReady,Level.High,true))
  }
  private setScanBoxReady(){
    this.setCheck(PreviewViewModel.CHECK_SCAN_BOX,true)
  }
  public setControllerReady(){
    this.setCheck(PreviewViewModel.CHECK_CONTROLLER,true)
  }
  public getReady(){
    return this.mCheckList.every(v => v);
  }

  constructor(uiContext: UIContext) {
    this.uiContext = uiContext;
  }

  // [EndExclude isFront]
  getCameraPosition() {
    return this.isFront
      ? camera.CameraPosition.CAMERA_POSITION_FRONT
      : camera.CameraPosition.CAMERA_POSITION_BACK;
  }
  // [End isFront]

  // [Start getProfile]
  // 声明一个名叫 getProfile 的函数属性，
  // 它的类型是 (cameraOrientation: number) => camera.Profile，
  // 而它的具体实现是一个箭头函数，参数名也叫 cameraOrientation，函数体在 {} 里。
  /**
   * 注意传参为cameraOrientation，相机安装方向
   * 后置摄像头为90，
   * width与屏幕竖直方向平行，
   * height与屏幕竖直方向平行，
   * 竖屏时需要交换宽高
   * */
  getProfile: (cameraOrientation: number) => camera.Profile = cameraOrientation => {
    const displaySize: Size = WindowUtil.getMaxDisplaySize();
    //屏幕方向竖屏为0
    const displayRotation = display.getDefaultDisplaySync().rotation * 90;
    const isRevert = (cameraOrientation + displayRotation) % 180 !== 0;
    return {
      format: camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP,
      size: {
        height: isRevert ? displaySize.width : displaySize.height,
        width: isRevert ? displaySize.height : displaySize.width
      }
    };
  }
  // [End getProfile]

  // [Start setPreviewSize]
  setPreviewSize() {
    const displaySize: Size = WindowUtil.getMaxDisplaySize();
    this.previewSize = displaySize;
    this.xComponentController.setXComponentSurfaceRect({
      surfaceWidth: displaySize.width,
      surfaceHeight: displaySize.height
    });
  }
  //安卓逻辑需要用到 DecodeBusiness.createCamera
  setPreviewSizeByCamera(size:Size){
    this.previewSize = size;
    this.xComponentController.setXComponentSurfaceRect({
      surfaceWidth: size.width,
      surfaceHeight: size.height
    });
  }
  // [End setPreviewSize]

  // 设置宽高比（对应原版的setAspectRatio）
  setAspectRatio(width: number, height: number): void {
    if (width < 0 || height < 0) {
      throw new Error("Size cannot be negative.")
    }
    // this.ratioWidth = width
    // this.ratioHeight = height
  }


  getPreviewWidth() {
    return this.uiContext.px2vp(this.previewSize.width);
  }

  getPreviewHeight() {
    return this.uiContext.px2vp(this.previewSize.height);
  }

  openPreviewBlur() {
    animateToImmediately({
      duration: 200,
      curve: Curve.Friction
    }, () => {
      this.blurRadius = 150;
    });
  }

  rotatePreviewBlur() {
    animateToImmediately({
      delay: 50,
      duration: 200,
      curve: curves.cubicBezierCurve(0.2, 0, 0.83, 1),
      onFinish: () => {
        this.rotatePreviewBlurSecond();
      }
    }, () => {
      this.blurRotation = { y: 0.5, angle: 90 };
    });
  }

  rotatePreviewBlurSecond() {
    this.blurRotation = { y: 0.5, angle: 270 };
    animateToImmediately({
      duration: 200,
      curve: curves.cubicBezierCurve(0.17, 0, 0.2, 1),
      onFinish: () => {
        this.blurRotation = { y: 0.5, angle: 0 };
      }
    }, () => {
      this.blurRotation = { y: 0.5, angle: 360 };
    });
  }

  closePreviewBlur() {
    animateToImmediately({
      duration: 200,
      curve: Curve.FastOutSlowIn
    }, () => {
      this.blurRadius = 0;
    });
  }
}

export default PreviewViewModel;