import { LocationInfo, Logger } from 'common';
import { router } from '@kit.ArkUI';
import { WebViewType } from '../pages/WebPage';
import { DecodeBusiness } from '../decoder/DecodeBusiness';
import BuildProfile from 'BuildProfile';

/**
 * IndexPage的ViewModel
 * 使用@Observed实现状态管理V1
 */
@Observed
export class IndexPageViewModel {
  // UI状态
  public themeColor: ResourceColor = $r('app.color.ThemeColorBlue'); // 主题颜色
  public isLogin: boolean = false; // 用户登录状态
  public location: LocationInfo | null = null; // 位置信息
  public isLoading: boolean = false; // 控制加载提示显示
  public angle: number = 0; // 加载动画角度
  public getCameraPermission: boolean = true; // 是否获得相机权限
  public isEnabledShowQRUrlResult: boolean = true;

  // 相机相关状态
  public isFlashOn: boolean = false; // 闪光灯状态
  public isQT: boolean = true; // 是否为QT模式（true为QT模式，false为QR模式）
  public qtZoomValue: number = 2.5; // QT模式缩放值
  public qrZoomValue: number = 1.0; // QR模式缩放值
  public currentZoomValue: number = 2.5; // 当前模式使用的缩放值
  public zoomText: string = this.currentZoomValue.toFixed(1); // 显示的缩放文本
  public isExposureModeEnabled: boolean = false; // 曝光模式
  public isMacroModeEnabled: boolean = false; // 微距模式

  // 聚焦框状态
  public isFocusBoxVisible: boolean = false; // 控制聚焦框显示
  public focusBoxPosition: Edges = { top: 0, left: 0 }; // 聚焦框位置
  public focusScale: number = 1.0; // 聚焦框缩放状态

  // 扫描框位置
  public scanningEffectYPercent: number = 0.4; // Y轴位置安卓为40%

  // 布局位置
  public isQTBottom: number = 200; // QT/QR切换按钮的位置
  public isQTSize: number = 60; // QT/QR切换按钮的大小
  public isQTBottomSpacing: number = 30; // QT/QR切换按钮与扫描框的间距
  public sliderBottom: number = 110; // 缩放条的位置

  // 蓝牙相关
  public isBluetoothShowOnMain: boolean = false; // 控制主页是否展示蓝牙图标
  public isConnected: boolean = false; // 用于控制页面右上角的蓝牙图标显示模式
  public elePower: string = ''; // 电池电量
  public isPowerLow: boolean = false; // 用来控制电量显示是否是低电量

  // 菜单状态
  public selectVisible: boolean = false; // 控制Select组件显示
  public selectedIndex: number = 0; // 当前选中项索引

  // 按压状态
  public isFlashIconPressed: boolean = false; // 闪光灯图标按压状态
  public isSettingIconPressed: boolean = false; // 设置图标按压状态
  public isFeedbackIconPressed: boolean = false; // 反馈图标按压状态
  public isBluetoothIconPressed: boolean = false; // 蓝牙图标按压状态
  public isBackIconPressed: boolean = false; // 返回图标按压状态
  public isHelpIconPressed: boolean = false; // 帮助图标按压状态
  public isMenuIconPressed: boolean = false; // 菜单图标按压状态
  public isModeIconPressed: boolean = false; // 模式图标按压状态

  // 授权申请的波纹特效变量
  public rippleScale: number = 1; // 波纹缩放比例
  public rippleOpacity: number = 0.6; // 波纹透明度

  // 缩放相关
  public originZoomBeforePinch: number = 1.0; // 记录开始缩放前的当前缩放值
  public isZoomPinching: boolean = false; // 标记是否正在双指缩放

  // 页面跳转控制
  public isJumpSucceed: boolean = false; // 页面跳转成功标记
  public exitPressTime: number = 0; // 控制退出的时间标记

  // 测试相关
  public isTesting: boolean = BuildProfile.DEBUG; // 测试模式标记

  //业务
  private mDecodeBusiness: DecodeBusiness | null = null;
  public getDecodeBusiness(){ return this.mDecodeBusiness }

  /**
   * 更新缩放值
   */
  updateZoomValue(value: number): void {
    this.currentZoomValue = value;
    this.zoomText = this.currentZoomValue.toFixed(1);
    if (this.isQT) {
      this.qtZoomValue = value;
    } else {
      this.qrZoomValue = value;
    }
  }

  /**
   * 切换QT/QR模式
   */
  switchMode(): void {
    Logger.info('IndexPageViewModel', `切换模式被调用，当前QT模式: ${this.isQT}`);
    // 保存当前模式的缩放值
    if (this.isQT) {
      this.qtZoomValue = this.currentZoomValue;
    } else {
      this.qrZoomValue = this.currentZoomValue;
    }
    
    // 切换模式
    this.isQT = !this.isQT;
    Logger.info('IndexPageViewModel', `切换模式更新QT模式为: ${this.isQT}`);
    
    // 加载新模式的缩放值
    if (this.isQT) {
      this.currentZoomValue = this.qtZoomValue;
    } else {
      this.currentZoomValue = this.qrZoomValue;
    }
    this.zoomText = this.currentZoomValue.toFixed(1);
  }
  /**
   * 更新聚焦框位置
   */  updateFocusBox(position: Edges, visible: boolean): void {
    this.focusBoxPosition = position;
    this.isFocusBoxVisible = visible;
    this.focusScale = visible ? 1.0 : 0.6;
  }

  /**
   * 更新闪光灯状态
   */
  toggleFlash(): void {
    this.isFlashOn = !this.isFlashOn;
  }

  /**
   * 更新主题色
   */
  updateThemeColor(color: ResourceColor): void {
    this.themeColor = color;
  }

  /**
   * 更新登录状态
   */
  updateLoginState(isLogin: boolean): void {
    this.isLogin = isLogin;
  }

  /**
   * 更新位置信息
   */
  updateLocation(location: LocationInfo | null): void {
    this.location = location;
  }

  /**
   * 更新加载状态
   */
  updateLoadingState(isLoading: boolean): void {
    this.isLoading = isLoading;
  }

  /**
   * 更新蓝牙状态
   */
  updateBluetoothState(isConnected: boolean, elePower: string, isPowerLow: boolean): void {
    this.isConnected = isConnected;
    this.elePower = elePower;
    this.isPowerLow = isPowerLow;
  }

  /**
   * 重置按压状态
   */
  resetPressState(): void {
    this.isFlashIconPressed = false;
    this.isSettingIconPressed = false;
    this.isFeedbackIconPressed = false;
    this.isBluetoothIconPressed = false;
    this.isBackIconPressed = false;
    this.isHelpIconPressed = false;
    this.isMenuIconPressed = false;
    this.isModeIconPressed = false;
  }

  showUrl(url: string){
    if(this.isEnabledShowQRUrlResult){
      router.pushUrl({
        url: 'pages/WebPage',
        params:{
          url: url,
          type: WebViewType.DecodeResult
        }
      })
      this.isEnabledShowQRUrlResult = false
    }
  }

}