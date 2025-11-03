/**
 * 鸿蒙配置相机参数与安卓配置相机参数Api不一样，
 * 鸿蒙通过@ohos.multimedia.camera（import { camera } from '@kit.CameraKit';）
 * session: camera.PhotoSession
 * session.enableAutoDeviceSwitch(isEnable);
 * 去调整相机参数，
 * 且鸿蒙相机参数更有限：仅支持自动曝光、闪光灯、对焦、色彩空间、白平衡、微距、变焦等有限配置
 * */

import { IRelease } from './IRelease';
import { AbsCamera, CameraState } from './AbsCamera';
import { common } from '@kit.AbilityKit';

/**
 * ParameterKey 定义：保持与安卓侧概念一致，必要时可扩展
 * - Version / ApiLevel 作为内置虚拟键，由 getVersion()/getApiLevel() 提供
 * - PreviewSize 仅能在 put() 阶段设置，禁止在 putAndSync() 中使用
 */
export enum ParameterKey {
  Version = 'Version',
  ApiLevel = 'ApiLevel',
  PreviewSize = 'PreviewSize',//todo 鸿蒙是否需要

  AutoExposure='AutoExposure',      //自动曝光   setExposureMode 自动/或者单独设置 setMeteringPoint曝光区域中心点，setExposureBias曝光补偿值
  ColorManagement='ColorManagement',//色彩空间   setColorSpace todo 未理解色彩空间是做什么的
  Flash = 'Flash',                  //闪光灯     setFlashMode 需先检查hasFlash/isFlashModeSupported
  Focus = 'Focus',                  //对焦      setFocusMode 需先检查isFocusModeSupported 自动/或者单独设置 setFocusPoint焦点（焦距有getFocalLength，但无法设置）
  Macro = 'Macro',                  //微距      enableMacro API 19才开始支持 需先检查isMacroSupported
  WhiteBalance = 'WhiteBalance',    //白平衡    setWhiteBalanceMode API20才开始支持 需先检查isWhiteBalanceModeSupported 可设置setWhiteBalance白平衡值 todo 未理解白平衡是做什么的
  Zoom = 'Zoom'                     //变焦      setZoomRatio设置变焦 setSmoothZoom触发平滑变焦
}

export interface Range<T> {
  min: T;
  max: T;
}

/**
 * 将参数同步到相机的接口（等价 ICameraParameterSync）
 * - 迁移时保留接口位点，实际实现由业务侧提供
 */
export interface ICameraParameterSync {
  syncAll(): boolean;
  syncSingle(key: ParameterKey, value: object): boolean;
}

/**
 * 迁移到 ArkTS（API12+）
 */
export abstract class AbsCameraParameter implements IRelease {
  protected mContext: common.BaseContext;
  protected mIsFront: boolean = false;
  protected mCameraId: string = '';
  protected mSupportedMap: Map<ParameterKey, boolean>| null = null;
  protected mMap: Map<ParameterKey, number>| null = null;//后续补充对应类型
  protected mModel: string = '';         // 手机型号，特殊手机，可能需要专门处理（鸿蒙侧可按需填充）
  protected mManufacturer: string = '';  // 制造商（鸿蒙侧可按需填充）
  protected isOpen: boolean = false;
  protected mCamera: AbsCamera;

  /**
   * 私有初始化，保持与安卓侧结构一致
   */
  private initMaps() {
    this.mSupportedMap = new Map<ParameterKey, boolean>();
    this.mMap = new Map<ParameterKey, number>();
  }

  protected constructor(context: common.BaseContext, camera: AbsCamera) {
    this.initMaps();
    this.mContext = context;
    this.mCamera = camera;
    // 鸿蒙获取机型/厂商信息的能力与安卓不同，这里仅保留字段；如需可在子类中补充。
  }

  // 初始化（由子类保存同步桥等引用）
  public abstract init(sync: ICameraParameterSync): boolean;

  /**
   * 仅在相机完成 open 后使用 putAndSync；init/配置期使用 put + syncAll
   * 设置参数（异步的）
   * @param map 要设置的属性
   */
  public put(map: Map<ParameterKey, object>): void {
    if (!map || map.size === 0) {
      return;
    }
    // 保持与安卓侧约束一致：仅在初始化阶段使用
    const state = this.mCamera.getState();
    if (state === CameraState.Running || state === CameraState.Close || state === CameraState.Release) {
      throw new Error("please use this method at init.");
    }
    map.forEach((value, key) => {
      this.changeProtected(key, value);
    });
  }

  public putAndSync(key: ParameterKey, value: object): void {
    if (!this.isOpen) {
      throw new Error("Don't use this method until camera opened");
    }
    if (key === ParameterKey.PreviewSize) {
      throw new Error("Don't set PreviewSize by 'putAndSync', use 'put' instead");
    }
    this.changeProtected(key, value);
    this.syncSingle(key, value);
  }

  public getId(): string {
    return this.mCameraId;
  }

  public isIsFront(): boolean {
    return this.mIsFront;
  }

  // 判断参数是否支持（带缓存）
  public isSupported(key: ParameterKey): boolean {
    if (this.mSupportedMap && !this.mSupportedMap.has(key)) {
      const supported = this.isSupportedProtected(key);
      this.mSupportedMap.set(key, !!supported);
    }
    return this.mSupportedMap?.get(key) === true;
  }

  public get<T>(key: ParameterKey): T | null {
    if (key === ParameterKey.Version) return this.getVersion() as T;
    if (key === ParameterKey.ApiLevel) return this.getApiLevel() as T;
    if(this.mMap && this.mMap.has(key)){
      return this.mMap.get(key) as T;
    }
    else{
      return null;
    }
  }

  /**
   * 获取所有参数用于保存
   * */
  public getAll(): Map<ParameterKey, number> {
    const map = new Map<ParameterKey, number>(this.mMap);
    map.set(ParameterKey.Version, this.getVersion());
    map.set(ParameterKey.ApiLevel, this.getApiLevel());
    return map;
  }


  public open(): boolean {
    this.isOpen = true;
    return this.isOpen;
  }

  public close(): boolean {
    this.isOpen = false;
    if (this.mMap && this.mMap.size > 0) {
      this.mMap.clear();
    }
    if (this.mSupportedMap && this.mSupportedMap.size > 0) {
      this.mSupportedMap.clear();
    }
    return !this.isOpen;
  }

  public release(): void {
    this.close();
  }

  // 能力/取值查询（由子类基于鸿蒙能力实现）
  public abstract getSupportedValue<T>(key: ParameterKey): T | null;
  public abstract getSupportedList<T>(key: ParameterKey): Array<T> | null;
  public abstract getSupportedRange<T>(key: ParameterKey): Range<T> | null;

  protected abstract isSupportedProtected(key: ParameterKey): boolean;

  /**
   * 摄像头传感器方向指的是传感器采集到的画面方向经过顺时针旋转多少度之后才能和局部坐标系的 y 轴正方向一致，（y 轴是当手机处于自然方向时，和手机屏幕平行且指向上方的坐标轴）
   * 通常情况下手机的自然方向就是竖着的时候，平板的自然方向就是横着的时候。
   * 所以手机的背后摄像头返回90°，前置摄像头返回270°
   * 平板的背后摄像头返回0°，前置摄像头返回180°
   */
  public abstract getCameraOrientation(): number;

  // 将参数同步到摄像机（子类内把缓存参数应用到鸿蒙 session）
  protected abstract syncAll(): boolean;
  protected abstract syncSingle(key: ParameterKey, value: object): boolean;

  // 版本信息（子类可按需覆盖）
  protected getVersion(): number { return 1; }
  protected getApiLevel(): number { return 12; }

  // 类型校验（如需严格校验可在子类覆盖）
  protected checkType<T>(_key: ParameterKey, _value: T): boolean { return true; }

  // 仅修改缓存，不直接落地
  protected changeProtected<T>(key: ParameterKey, value: T): void {
    if (!this.checkType(key, value)) {
      throw new Error(`参数${String(key)} 数据类型不符合`);
    }
    this.mMap?.set(key, value as number);
  }
}