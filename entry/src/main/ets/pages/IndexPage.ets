import { promptAction, router } from '@kit.ArkUI';
import BuildProfile from 'BuildProfile';
import { EntryUtils } from '../common/EntryUtils';
import { common, Want } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { BarcodeFormat } from '@ohos/zxing';
import QRCode from '../utils/zxing/QRCode';
import { ScanningEffectCanvasDynamic, ScanningEffectCanvasStatic } from '../component/view/ScanningEffectCanvas';
import { AppSetting } from '../common/AppSetting';
import { UserSetting } from '../common/UserSetting';
import PreviewViewModel from '../viewmodels/PreviewViewModel';
import CameraConstant from '../constants/Constants';
import RefreshableTimer from '../utils/RefreshableTimer';
import { calCameraPoint, calCameraPoint2, getClampedChildPosition } from '../utils/CommonUtil';
import WindowUtil from '../utils/WindowUtil';
import { Point } from '@kit.TestKit';
import { DecodeBusiness } from '../decoder/DecodeBusiness';
import { EventManager, Level, Logger, SoundPlayUtils, Sounds, ActivityState, Utils, LocationInfo } from 'common';
import { ScanStateMachine } from '../common/state/ScanStateMachine';
import { IndexPageReceiver } from '../receiver/IndexPageReceiver';
import { AppEvent } from '../common/event/AppEvent';
import { AppEventType } from '../common/event/AppEventType';
import { Decoder } from '../decoder/Decoder';
import { WebDecodeService } from '../service/WebDecodeService';
import { IWebDecodeResultHandle } from '../service/IWebDecodeResultHandle';
import { DecodeResultDTO } from '../common/models/json/DecodeResult';
import { WebDecodeError } from '../service/WebDecodeError';
import { DecodeResultBean } from '../bean/DecodeResultBean';
import vibrator from '@ohos.vibrator';
import { AbsProductManager } from '../common/ProductManager/AbsProductManager';
import { AppProductManager } from '../common/ProductManager/AppProductManager';
import { IProductManageListener } from '../common/ProductManager/IProductManageListener';
import { getCurrentProductType, ProductType } from '../common/ProductType';
import { BusinessError, pasteboard, systemDateTime } from '@kit.BasicServicesKit';
import { DestroyProductManager } from '../common/ProductManager/DestroyProductManager';
import { PopupManage } from '../common/popup/PopupManage';
import { ProgressDialog } from '../component/Dialog/ProgressDialog';
import { ImageSaver } from '../common/FileStorageManager';
import PermissionManager from '../utils/PermissionManager';
import { ConfirmDialog } from '../component/Dialog/ConfirmDialog';
import { ConfirmParams } from '../common/DialogFragmentManege/ConfirmParams';
import { ShareDialog } from '../component/Dialog/ShareDialog';
import { WebViewType } from './WebPage';

const TAG = 'IndexPage';
// 创建一个实现IProductManageListener接口的类
class IndexPageProductManager implements IProductManageListener {
  private page: IndexPage;
  constructor(page: IndexPage) {
    this.page = page;
  }

  onDestroySuccess(code: string[]): void {
    Logger.info(TAG, "onDestroySuccess called with codes: " + code.join(","));
  }
  onDestroyNOLogin(): void {
    Logger.info(TAG, "onDestroyNOLogin called");
  }
  onDestroyPopdown(): void {
    Logger.info(TAG, "onDestroyPopdown called");
  }
  onAppSuccess(code: string): void {
    Logger.info(TAG, "onAppSuccess called with code: " + code);
  }
  onSecrecySuccess(code: string): void {
    Logger.info(TAG, "onSecrecySuccess called with code: " + code);
  }
}


@Entry
@Component
struct IndexPage{
  @State location: LocationInfo | null = null;
  @State popupManage: PopupManage = new PopupManage(this.getUIContext().getHostContext()!)
  @State isJumpSucceed: boolean = false;
  @State themeColor: ResourceColor = $r('app.color.ThemeColorBlue');
  @State isLogin: boolean = false;
  @State selectVisible: boolean = false; // 控制Select组件显示
  @State selectedIndex: number = 0;     // 当前选中项索引
  @State isConnected: boolean = false // 用于控制页面右上角的蓝牙图标显示模式
  @State elePower: string = '' // 电池电量
  @State isPowerLow: boolean = false // 用来控制电量显示是否是低电量
  @State isBluetoothShowOnMain: boolean = false // 控制主页是否展示蓝牙图标
  @State exitPressTime: number = 0 //控制退出的时间标记
  @State angle: number = 0
  @State isLoading: boolean = false // 控制加载提示显示
  @State isQTBottom: number = 200; //QT/QR切换按钮的位置
  @State isQTSize: number = 60;    //QT/QR切换按钮的大小
  isQTBottomSpacing: number = 30;  //QT/QR切换按钮与扫描框的间距
  @State sliderBottom: number = 110;     //缩放条的位置
  @State getCameraPermission: boolean = true; //是否获得相机权限

  //授权申请的波纹特效变量
  @State rippleScale: number = 1
  @State rippleOpacity: number = 0.6

  // 为每个图标添加独立的按压状态
  @State isFlashIconPressed: boolean = false;
  @State isSettingIconPressed: boolean = false;
  @State isFeedbackIconPressed: boolean = false;
  @State isBluetoothIconPressed: boolean = false;
  @State isBackIconPressed: boolean = false;
  @State isHelpIconPressed: boolean = false;
  @State isMenuIconPressed: boolean = false;
  @State isModeIconPressed: boolean = false;

  //测试二维码解码
  @State mPixelMap:image.PixelMap|null = null;
  @State mPixelMap2:image.PixelMap|null = null;
  @State mPixelMap3:image.PixelMap|null = null;
  @State qrCodeWidth:number = 200;
  @State qrCodeHeight:number = 200;

  //Y轴位置安卓为40%
  @State scanningEffectYPercent: number = 0.4;

  @State isQT: boolean= true

  @State isTesting :boolean = BuildProfile.DEBUG;

  private context: Context = this.getUIContext().getHostContext()!;
  //XComponent预览的ViewModel
  @State previewVM: PreviewViewModel = new PreviewViewModel(this.getUIContext());
   //聚焦框相关
  @State isFocusBoxVisible: boolean = false;
  @State focusBoxPosition: Edges = { top: 0, left: 0 };
  @State private focusScale: number = 1.0;  // 添加缩放状态
  private focusBoxSize: Size = { width: 120, height: 120 };
  private focusBoxTimer: RefreshableTimer = new RefreshableTimer(() => {
    this.isFocusBoxVisible = false;
  }, 1.0 * 1000);
  //相机缩放相关
  @State qtZoomValue: number = 2.5; // QT 模式缩放值
  @State qrZoomValue: number = 1.0; // QR 模式缩放值
  @State currentZoomValue: number = 2.5; // 当前模式使用的缩放值
  @State zoomText: string = this.currentZoomValue.toFixed(1); // 显示的缩放文本
  @State isFlashOn: boolean = false;// 闪光灯状态
  @State originZoomBeforePinch: number = 1.0; // 记录开始缩放前的当前缩放值
  @State isZoomPinching: boolean = false; // 标记是否正在双指缩放
  @State private isExposureModeEnabled: boolean = false; //曝光模式
  @State private isMacroModeEnabled: boolean = false;// 微距模式
  //业务
  private mDecodeBusiness: DecodeBusiness | null = null;
  public getDecodeBusiness(){ return this.mDecodeBusiness }
  //事件接收器
  private mEventReceiver: IndexPageReceiver| null = null;
  //状态机
  private scanStateMachine : ScanStateMachine | null = null;
  //网络解码
  private mWebDecodeService: WebDecodeService| null = null;
  public getWebDecodeService(){ return this.mWebDecodeService }
  private mProductManager: AbsProductManager| null = null;
  // 创建IProductManageListener的实例
  private productManageListener: IProductManageListener = new IndexPageProductManager(this);

  private currentState: ActivityState = ActivityState.Unknow; // 当前页面状态

  private isEnabledShowQRUrlResult: boolean = true;
  private imageSaver: ImageSaver = new ImageSaver(this.context); // 创建ImageSaver实例

  // region 网络解码回调
  private mWebDecodeResultHandle: IWebDecodeResultHandle = {
    onStartWebDecode: (): void => {
      if (this.isCanHandleResult()) {//是否满足可处理结果的条件
        this.isLoading = true;
        this.startRotation(); // 启动旋转动画
      }
      this.isJumpSucceed = false;
      Logger.info(TAG, "onStartWebDecode");
    },

    onEndWebDecode: (result: DecodeResultDTO, error: WebDecodeError): void => {
      this.isLoading = false;
      // 根据错误类型处理不同的情况
      switch (error) {
        case WebDecodeError.None:
          Logger.info(TAG, "None");
          if (this.isCanHandleResult()) {
            if (this.mProductManager) {
              this.mProductManager.processDecodeResult(result);
            }
          }
          this.isJumpSucceed = false;
          break;
        case WebDecodeError.Cancel:
          Logger.info(TAG, "Cancel");
          if (this.isCanHandleResult()) {
            this.showToast(EntryUtils.getStringByResourceManager(this.context, $r('app.string.already_canceled_decoding')), 2000);
          }
          this.isJumpSucceed = false;
          break;
        case WebDecodeError.Destroy:
          Logger.info(TAG, "Destroy");
          if (this.isCanHandleResult()) {
            this.showToast(EntryUtils.getStringByResourceManager(this.context, $r('app.string.code_map_is_destroyed')), 2000);
          }
          this.isJumpSucceed = false;
          break;
        case WebDecodeError.OffLine:
          Logger.info(TAG, "OffLine");
          if (this.isCanHandleResult()) {
            // 显示网络错误对话框
            this.showSetNetworkDialog();
          }
          this.isJumpSucceed = false;
          break;
        case WebDecodeError.Unknown:
          Logger.info(TAG, "Unknown");
          if (this.isCanHandleResult()) {
            this.showToast(EntryUtils.getStringByResourceManager(this.context, $r('app.string.unknown_exception')), 2000);
          }
          this.isJumpSucceed = false;
          break;
        case WebDecodeError.ServerError:
          Logger.info(TAG, "ServerError");
          if (this.isCanHandleResult()) {
            this.showToast(EntryUtils.getStringByResourceManager(this.context, $r('app.string.server_error')), 2000);
          }
          this.isJumpSucceed = false;
          break;
        case WebDecodeError.NetPermissionDenied:
          Logger.info(TAG, "NetPermissionDenied");
          if (this.isCanHandleResult()) {
              //todo 检查网络（相机）权限 后续权限做统一管理
          }
          this.isJumpSucceed = false;
          break;
        case WebDecodeError.NoConnectedNetwork:
          Logger.info(TAG, "NoConnectedNetwork");
          if (this.isCanHandleResult()) {
            // 显示网络错误对话框
            this.showSetNetworkDialog();
          }
          this.isJumpSucceed = false;
          break;
      }
      this.closeDecodeLoading();
    }
  };
  // endregion

  appSetting = new AppSetting(getContext())
  userSetting = new UserSetting(getContext())

  // region 生命周期监听
  async aboutToAppear(): Promise<void> {
    // if(this.isTesting){
    //   setInterval(()=>{
    //     Logger.info(TAG,'isCanHandleResult:' + this.isCanHandleResult())
    //   },1000)
    // }

    this.setStatus(ActivityState.Created);
    Logger.warn(TAG,'生命周期已触发：aboutToAppear--开始 ActivityState.Created')
    const color = await this.appSetting.getTheme()
    EntryUtils.setThemeColor(color)

    //监听屏幕尺变化
    this.addOrientationChangeEventListener()
    //初始化
    this.init()

    // 读取本地保存的登录状态
    const params = router.getParams() as isLoginSuccess;
    if (params?.isLoginSuccess) {
      await this.syncLoginState();
    }

    await this.syncLoginState();
    // 初始化更新进度条弹窗
    ProgressDialog.init(this.getUIContext(), () => {
      this.popupManage.hide(ProgressDialog.fragment!)
    })

    Logger.warn(TAG,'生命周期已触发：aboutToAppear--结束')
  }
  async onPageShow(): Promise<void> {
    Logger.warn(TAG,'生命周期已触发：onPageShow--开始')
    // 每次页面显示时刷新登录状态
    await this.syncLoginState();
    const params = router.getParams() as isLoginSuccess;
    if (params?.isLoginSuccess) {
      await this.syncLoginState();
      this.getUIContext().getPromptAction().showToast({
        message: 'QT:' + EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext(), $r('app.string.login_tip_login_Success')),
        duration: 3000 ,
        alignment: Alignment.Top,
        offset: { dx: 0, dy: 300 },
      });
      router.clear();
    }
    if(this.previewVM.getReady()){
      if(!this.mDecodeBusiness?.isCameraInit()){
        this.mDecodeBusiness?.startCamera(this.currentZoomValue);
      }
    }
    this.isEnabledShowQRUrlResult = true

    // 每次启动页面都刷新该状态
    this.isBluetoothShowOnMain = await this.appSetting.getIsBluetoothShowOnMain()

    //重置页面跳转开关
    if (this.mProductManager && this.mProductManager instanceof AppProductManager) {
      this.mProductManager.isQTCanStartProductActivity(true);
      Logger.info('aaaTest','重置isQTCanStartProductActivity为true');
    }
    this.setStatus(ActivityState.Running);
    Logger.warn(TAG,'生命周期已触发：onPageShow--结束 ActivityState.Running')
  }
  onBackPress(){
    let curTime = systemDateTime.getTime()

    if(curTime - this.exitPressTime < 3000){
      //真正关闭程序,配置removeMissionAfterTerminate可在后台任务列表中删除
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      ctx.terminateSelf();
      return false
    }
    //提示弹窗
    this.getUIContext().getPromptAction().showToast({ message: $r('app.string.tips_double_click_exit') })
    this.exitPressTime = curTime

    return true
  }
  aboutToDisappear(): void {
    this.removeOrientationChangeEventListener();
    this.mDecodeBusiness?.releaseCamera()
    this.mDecodeBusiness?.releaseDecode()

    this.setStatus(ActivityState.Destroy);
    Logger.warn(TAG,'生命周期已触发：aboutToDisappear,releaseCamera(),releaseDecode() ActivityState.Destroy')
  }
  onPageHide(): void {
    //停止相机
    this.mDecodeBusiness?.stopCamera()
    this.setStatus(ActivityState.Stop);
    this.isFlashOn = false;
    Logger.warn(TAG,'生命周期已触发：onPageHide,stopCamera() ActivityState.Stop')
  }
  public setStatus(value:ActivityState){
    this.currentState = value
    Logger.warn(TAG,'ActivityState：'+value)
  }
  public getStatus(){ return this.currentState }
  // endregion

  /**
   * 安卓onCreate
   * */
  init(){
    //app更新
    this.update()
    this.mWebDecodeService = new WebDecodeService(this.context, this.mWebDecodeResultHandle);
    // 网络QC先不实现

    //向https服务器发起一次心跳连接，加快服务器解码速度
    this.mWebDecodeService.heartbeat();

    // 解码器
    Decoder.getInstance().setIsQTCode(this.isQT)

    //相机与解码业务
    this.mDecodeBusiness = new DecodeBusiness(this.context, this.previewVM);

    //事件接收器
    this.mEventReceiver = new IndexPageReceiver(this);
    //添加监听，等级为High
    EventManager.attach(this.mEventReceiver, Level.High);

    //测试代码
    EventManager.async(this, new AppEvent(AppEventType.DecodeService, Level.Common, '测试EventManager与事件接收器'));
    Logger.info(TAG,'测试EventManager与事件接收器')

    // 初始化ProductManager
    this.initProductManager();
  }

  //todo app更新
  update(){

  }

  /**
   * 初始化ProductManager
   * 根据产品类型选择合适的ProductManager实现
   */
  private initProductManager(): void {
    const productType = getCurrentProductType();
    Logger.info("IndexPage", "Current product type: " + productType);

    switch (productType) {
      case ProductType.Destroy:
        // 初始化DestroyProductManager
        this.mProductManager = new DestroyProductManager(this.productManageListener);
        Logger.info("IndexPage", "Initialized DestroyProductManager for Destroy product type");
        break;
      case ProductType.Secrecy:
      case ProductType.Normal:
      //case ProductType.Preview:
      default:
        // QC版改为跟通用版一样，但会提示当前是QC，并且请求的API不统计扫描次数
        Logger.info("初始化AppProductManager，listener是否为null：", `${this.productManageListener === null}`);
        this.mProductManager = new AppProductManager(this.productManageListener);
        Logger.info("IndexPage", "Initialized AppProductManager for Secrecy/Normal product type");
        break;
    }
  }

  //同步登录状态
  private async syncLoginState() {
    if (!this.userSetting) {
      return;
    }
    try {
      Logger.info(TAG,'开始同步登录状态...');
      const accessToken = await this.userSetting.getUserAccessToken();
      Logger.info(TAG,`获取到的accessToken: "${accessToken}"`);
      this.isLogin = !!(accessToken && accessToken !== "");

      Logger.info(TAG,`登录状态: ${this.isLogin}`);

    } catch (error) {
      Logger.info('同步登录状态异常:', error);
      this.isLogin = false;
    }
  }

  // 显示聚焦框动画
  private showFocusWithAnimation(event: ClickEvent): void {
    // 从事件中提取坐标
    const point: Point = { x: event.x, y: event.y };

    // 计算位置
    const previewSize = this.previewVM.previewSize;
    this.focusBoxPosition = getClampedChildPosition(this.focusBoxSize, {
      width: this.getUIContext().px2vp(previewSize.width),
      height: this.getUIContext().px2vp(previewSize.height)
    }, point); // 传入提取的坐标对象

    // 显示聚焦框并重置缩放
    this.isFocusBoxVisible = true;
    this.focusScale = 1.0;

    // 执行缩放动画：1.0 → 0.6
    animateTo({ duration: 400, curve: Curve.EaseOut }, () => {
      this.focusScale = 0.6;
    });

    // 启动定时器，1.5秒后隐藏
    this.focusBoxTimer.refresh();
  }

  // 监听主题变化
  onWillApplyTheme(theme: Theme): void {
    this.themeColor = theme.colors.brand;
    Logger.info(TAG,'onWillApplyTheme:' + this.themeColor)
  }

  /* region 自适应预览尺寸 */
  private windowClass = (this.context as common.UIAbilityContext).windowStage.getMainWindowSync();
  private setPreviewSize: () => void = () => { this.previewVM.setPreviewSize(); }
  addOrientationChangeEventListener() {
    this.windowClass.on('windowSizeChange', this.setPreviewSize);
  }
  removeOrientationChangeEventListener() {
    this.windowClass.off('windowSizeChange', this.setPreviewSize);
  }
  /* endregion */

  //展示截图
  setScreenShot(image:image.PixelMap,index:number){
    try{
      let size = image.getImageInfoSync().size
      this.qrCodeWidth = px2vp(size.width / 2)
      this.qrCodeHeight = px2vp(size.height / 2)
      switch (index){
        case 0:
          this.mPixelMap = image
          break;
        case 1:
          this.mPixelMap2 = image
          break;
        case 2:
          this.mPixelMap3 = image
          break;
        default :
          break;
      }
    }catch(err) {
      const error = err as BusinessError;
      Logger.error(TAG,'setScreenShot error:'+ error.message);
    }
  }

  public async decodeTip() {
    if (await this.appSetting.getIsSound()) {
      SoundPlayUtils.play(Sounds.Scan);
      Logger.warn(TAG,'decodeTip-播放声音')
    }
    if (await this.appSetting.getIsShake()) {
      vibrator.startVibration({type: 'time' , duration: 100}, {usage: 'physicalFeedback'})
      Logger.warn(TAG,'decodeTip-震动')
    }
  }

  goToPage(url: string){
    this.isJumpSucceed = false
    router.pushUrl({ url: url })
      .catch((err: Error) => {
        Logger.error(TAG,'跳转失败:'+ err.message);
      });
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

  showCodeDialog(code:string){
    if(!this.popupManage.existDialogs()){
      let params = new ConfirmParams(code, $r('app.string.dialog_result_no'), $r('app.string.dialog_copy_all'),
        () => {}, () => {
          this.copyTextToClipBoard(code);
        })
      ConfirmDialog.init(this.getUIContext(), () => {
        this.popupManage?.hide(ConfirmDialog.fragment!)
      },params)
      this.popupManage.show(ConfirmDialog.fragment!)
    }
  }

  async copyTextToClipBoard(text: string) {
    const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    const systemPasteboard = pasteboard.getSystemPasteboard();
    systemPasteboard.setData(pasteboardData); // Put data into clipboard
    systemPasteboard.getData().then((data) => { // Read clipboard content
      if (data) {
        this.showToast(EntryUtils.getStringByResourceManager(this.context, $r('app.string.tips_result_copy_to_clip_board')),1000);
      }
    })
  }

  async getPermission(): Promise<boolean>{
    await PermissionManager.request(CameraConstant.PERMISSIONS, this.context)
      .catch((e:BusinessError) => {
        Logger.error(TAG,'获取相机权限失败' + e.message)
        return
      });
    const getCameraPermission = await Utils.checkPermission(this.context, 'ohos.permission.CAMERA');
    if(!getCameraPermission){
      this.showToast(EntryUtils.getStringByResourceManager(this.context, $r('app.string.txt_no_camera_permission')),1000);
      this.getCameraPermission = false;
      return false;
    }
    this.getCameraPermission = true;
    this.setPreviewVMReady();
    return true;
  }

  async setPreviewVMReady(){
    this.location = await Utils.getGpsLocation(this.context);
    this.previewVM.surfaceId = this.previewVM.xComponentController.getXComponentSurfaceId();
    this.previewVM.setPreviewSize();
    this.previewVM.xComponentController.setXComponentSurfaceRotation({ lock: true });//锁定方向
    this.previewVM.setControllerReady()
  }

  //点击授权的波纹特效
  startRippleAnimation() {
    let _this = this;
    const run = () => {
      animateTo({
        duration: 1600,                 // 动画持续 1.6 秒
        curve: Curve.EaseOut,           // 缓出曲线，先快后慢
        onFinish: () => {               // 动画结束后的回调
          // 重置
          animateTo({ duration: 0 }, () => {
            this.rippleScale = 1
            this.rippleOpacity = 0.6
            if(!_this.getCameraPermission)
              run() // 再次循环
          })
        }
      }, () => {
        this.rippleScale = 2.5          // 波纹放大到 2.5 倍
        this.rippleOpacity = 0          // 同时透明度变为 0（淡出）
      })
    }
    if(!this.getCameraPermission)
      run()
  }

  // region UI 相关
  build() {
    Stack() {
      //XComponent预览
      this.preview()
      //遮罩和扫描框
      this.ScanBoxMask()
      Column() {
        // 导航栏
        this.buildHeader()

        if(this.isBluetoothShowOnMain){
          // 蓝牙图标
          this.buildBluetoothImage()
        }

        // //测试代码
        // if(this.isTesting){
        //   this.testing()
        // }

        //缩放条
        Column(){
          Row(){
            Text($r('app.string.tool_zoom'))
              .fontSize(14)
              .fontColor(Color.White);
            Text(this.zoomText)
              .id('seekbarZoom')
              .fontSize(14)
              .fontColor(Color.White)
              .margin({ left: 8 });
          }
          .padding({ left: 8 })
          .width('100%')

          Slider({
            value: this.currentZoomValue,
            min: 1.0,
            max: 4.0,
            step: 0.1
          })
            .blockColor(this.themeColor)
            .trackColor(Color.White)
            .selectedColor(this.themeColor)
            .onChange((value: number) => {
              this.currentZoomValue = value;
              this.zoomText = this.currentZoomValue.toFixed(1);
              // 根据当前模式，将值更新到对应状态
              if (this.isQT) {
                this.qtZoomValue = value;
              } else {
                this.qrZoomValue = value;
              }
              if (this.mDecodeBusiness) {
                this.mDecodeBusiness.setZoomRatio(value);
              }
            });
        }
        .width('90%')
        .padding({ left: 20, right: 20, bottom: 13 })
        .backgroundColor(Color.Transparent)
        .borderRadius(8)
        //.border({width:1,color:Color.Red})//测试边框
        .position({ bottom: this.sliderBottom, left: 20 })

        Row(){
          Column(){
            if(this.getCameraPermission){
              Image(this.isQT ? $r('app.media.qt_code') : $r('app.media.icon_scanqt'))
                .width(this.isQTSize)
                .height(this.isQTSize)
                .fillColor(this.themeColor)
                .onTouch((event: TouchEvent) => {
                  if (event.type === TouchType.Down) {
                    this.isModeIconPressed = true;
                  } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                    this.isModeIconPressed = false;
                  }
                })
                .shadow({ radius: this.isModeIconPressed ? 8 : 0, color: Color.Black, offsetX: 0, offsetY: 2 })
              Text(this.isQT ? 'QT' : 'QR')
                .fontSize(17)
                .fontWeight(500)
                .fontColor(this.themeColor)
                .margin({ top: 2 })
            }
            else
            {
              Image($r('app.media.qt_code'))
                .width(this.isQTSize)
                .height(this.isQTSize)
                .fillColor(this.themeColor)
                .shadow({ radius: this.isModeIconPressed ? 8 : 0, color: Color.Black, offsetX: 0, offsetY: 2 })
              Text($r('app.string.permission_title'))
                .fontSize(17)
                .fontWeight(500)
                .fontColor(this.themeColor)
                .margin({ top: 2 })
              // 背景波纹（无限循环）
              Circle()
                .width(this.isQTSize)
                .height(this.isQTSize)
                .fill(this.themeColor)
                .opacity(this.rippleOpacity)                         //透明度
                .scale({ x: this.rippleScale, y: this.rippleScale }) //缩放比, x: 横向缩放比, y: 纵向缩放比
                .position({ x: 4, y: 0 })                            // 居中
                .onAppear(() => {
                  this.startRippleAnimation()
                })
            }
          }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              if(!this.getCameraPermission){
                this.getPermission();
                return;
              }

              let newStatus = !this.isQT
              //保存当前模式的缩放值
              if(this.isQT) {
                this.qtZoomValue = this.currentZoomValue;
              } else {
                this.qrZoomValue = this.currentZoomValue;
              }

              //切换模式
              Decoder.getInstance().setIsQTCode(newStatus);
              this.isQT = newStatus

              // 加载新模式的缩放值
              if (this.isQT) {
                this.currentZoomValue = this.qtZoomValue;
                this.showToast(EntryUtils.getStringByResourceManager(this.context, $r('app.string.txt_qtcode_supported')),1000);
              } else {
                this.currentZoomValue = this.qrZoomValue;
                this.showToast(EntryUtils.getStringByResourceManager(this.context, $r('app.string.txt_barcode_supported')),1000);
              }
              this.zoomText = this.currentZoomValue.toFixed(1);
              if (this.mDecodeBusiness) {
                this.mDecodeBusiness.setZoomRatio(this.currentZoomValue);
              }
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .position({ bottom: this.isQTBottom, left: 0 })

        Row() {
            //反馈图标
            Image($r('app.media.vector_pageedit'))
              .id('Feedback')
              .width(70) // 图标宽度
              .height(70) // 图标高度
              .fillColor(this.themeColor)
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) {
                  this.isFeedbackIconPressed = true;
                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                  this.isFeedbackIconPressed = false;
                }
              })
              .shadow({ radius: this.isFeedbackIconPressed ? 8 : 0, color: Color.Black, offsetX: 0, offsetY: 2 })
              .onClick(() => {
                // 点击跳转到设置页面
                this.goToPage('pages/FeedbackPage')              })
              .padding(10)
              .borderRadius(8)

            // 闪光灯
            Image(this.isFlashOn ? $r('app.media.vector_light_line') : $r('app.media.vector_light'))
              .id('appBarBtnLight')
              .width(70) // 图标宽度
              .height(70) // 图标高度
              .fillColor(this.themeColor)
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) {
                  this.isFlashIconPressed = true;
                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                  this.isFlashIconPressed = false;
                }
              })
              .shadow({ radius: this.isFlashIconPressed ? 8 : 0, color: Color.Black, offsetX: 0, offsetY: 2 })
              .onClick(() => {
                // 切换闪光灯状态
                this.isFlashOn = !this.isFlashOn;
                // 控制闪光灯
                if(this.mDecodeBusiness) {
                  this.mDecodeBusiness.getCameraFlash(this.isFlashOn);
                }
              })
              .padding(10)
              .borderRadius(8)

            //设置图标
            Image($r('app.media.vector_setting'))
              .id('appBarBtnSetting')
              .width(70) // 图标宽度
              .height(70) // 图标高度
              .fillColor(this.themeColor)
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) {
                  this.isSettingIconPressed = true;
                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                  this.isSettingIconPressed = false;
                }
              })
              .shadow({ radius: this.isSettingIconPressed ? 8 : 0, color: Color.Black, offsetX: 0, offsetY: 2 })
              .onClick(() => {
                // 点击跳转到设置页面
                this.goToPage('pages/SettingsPage')              })
              .padding(10)
              .borderRadius(8)
          }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly) // 水平方向均匀分布
        //.alignItems(VerticalAlign.Bottom)
        .position({ bottom: 0, left: 0 })
        .padding({ right: 10, bottom: 30 })

        Row() {
          Text(`[GPS] Provider：${(this.location == null ? 'Unknow':'Gps')}  ${(this.location == null ? '-':this.location.longitude)},${(this.location == null ? '-':this.location.latitude)}`)
            .fontColor(Color.Black)
            .fontSize(10)
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .position({ bottom: 10, left: 10 })
        .padding({ right: 10, bottom: 10 })
      }
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.Transparent)//使得点击事件穿透到XComponent
      .margin({top:px2vp(WindowUtil.avoidArea.topRect.height)})

      // 这是在网络解码时的一个等待提示框
      if (this.isLoading) {
        this.buildLoading(); // 显示请稍等...
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  testing(){
    Row(){
      // 微距模式按钮
      this.macroModeButton();
      //曝光模式按钮
      this.exposureModeButton();
    }
    Row() {
      Button('测试页面').onClick(() => {
        this.getUIContext().getRouter().pushUrl({
          url: 'pages/TestPage/EventTestPage'
        });
      })

      Button('测试ZXing解码').onClick(async (event: ClickEvent) => {
        const ctx = getContext(this) as common.UIAbilityContext;
        const resMgr = ctx.resourceManager;
        const rawFd = resMgr.getRawFdSync('baidu_qrcode.png'); // 返回 RawFileDescriptor
        const imageSource = image.createImageSource(rawFd);
        let pixelMap = imageSource.createPixelMapSync();

        this.mPixelMap = pixelMap;

        let size = imageSource.getImageInfoSync().size
        // this.qrCodeWidth = size.width
        // this.qrCodeHeight = size.height
        let qrcode = new QRCode()
        let message = await qrcode.decode(pixelMap, {
          width: size.width,
          height: size.height,
          format: BarcodeFormat.QR_CODE
        })
        this.showToast('调用ZXing解码成功:' + message,2000)
      })

      Button('ble测试').onClick(() => {
        this.getUIContext().getRouter().pushUrl({
          url: 'pages/BleDemo/Index'
        });
      })
    }
    Row() {
      Button('保存图像').onClick(async () => {
        if (this.mPixelMap) {
          const success = await this.imageSaver.savePixelMap(this.mPixelMap);
          if (success) {
            this.getUIContext().getPromptAction().showToast({
              message: '图片已保存至相册',
              duration: 3000,
              alignment: Alignment.Top,
              offset: { dx: 0, dy: 300 },
            });
          } else {
            this.getUIContext().getPromptAction().showToast({
              message: '保存失败，请重试',
              duration: 3000,
              alignment: Alignment.Top,
              offset: { dx: 0, dy: 300 },
            });
          }
        } else {
          this.getUIContext().getPromptAction().showToast({
            message: '请先解码获取图片',
            duration: 2000,
            alignment: Alignment.Top,
            offset: { dx: 0, dy: 300 },
          });
        }
      })

      Button('声音测试').onClick(async () => {
        this.decodeTip()
        this.showCodeDialog('1111');
      })
      Button('截图').onClick(async () => {
        this.mDecodeBusiness?.screenshot()
      })
    }
    Row(){
      Button('Web解码测试')
        .onClick(async () => {
          //WebDecodeServiceTest.testManualRequest(this.context);

          //测试网络解码
          this.mWebDecodeService?.heartbeat();
          let bean = new DecodeResultBean()
          bean.setCode('20140')
          this.mWebDecodeService?.start(bean);
        })
        .width(150)
        .height(50)
        .margin({ top: 10 })
      Button('保存蓝牙截图测试')
        .onClick(async () => {
          this.mDecodeBusiness?.saveDeviceScreenshot();
        })
        .width(150)
        .height(50)
        .margin({ top: 10 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    Row() {
      Column(){
        Text('AbsCameraReader视频帧')
        Image(this.mPixelMap).width(this.qrCodeWidth).height(this.qrCodeHeight).border({width:2})
      }
      Column(){
        Text('相机视频帧')
        Image(this.mPixelMap2).width(this.qrCodeWidth).height(this.qrCodeHeight).border({width:2})
      }
    }
    Row() {
      Column(){
        Text('Worker视频帧')
        Image(this.mPixelMap3).width(this.qrCodeWidth).height(this.qrCodeHeight).border({width:2})
      }
    }
  }

  // 等待提示框
  @Builder
  buildLoading() {
    Stack() {
      // 半透明遮罩
      Column()
        .width('100%')
        .height('100%')

      Column({ space: 10 }) {
        Image($r('app.media.progressbar_animated'))
          .fillColor(this.themeColor)
          .width(40)
          .height(40)
          .rotate({ angle: this.angle, z: 1 }); // 绑定旋转角度

        Text($r('app.string.dialog_waiting'))
          .fontSize(16)
          .fontColor(Color.White);
      }
      .width(120)
      .height(120)
      .borderRadius(12)
      .padding(20)
      .backgroundColor('rgba(30,30,30,0.5)')
      .alignItems(HorizontalAlign.Center);
    }
    .width('100%')
    .height('100%');
  }


  //请稍后...动画效果
  startRotation() {
    setInterval(() => {
      this.angle += 10;  // 每次增加 10 度
      if (this.angle >= 360) {
        this.angle = 0;  // 重置角度
      }
    }, 150);
  }

  @Builder
  private exposureModeButton() {
    Button(this.isExposureModeEnabled ? "关闭曝光" : "开启曝光")
      .width(100)
      .height(50)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .backgroundColor(this.isExposureModeEnabled ? Color.Red : Color.Blue)
      .onClick(() => {
        if (this.mDecodeBusiness) {
          const result = this.mDecodeBusiness.toggleExposureMode();
          if (result) {
            this.isExposureModeEnabled = !this.isExposureModeEnabled;
          }
        }
      })
      .margin({ top: -50, bottom: -10 });
  }
  @Builder
  private macroModeButton() {
    Button(this.isMacroModeEnabled ? "关闭微距" : "开启微距")
      .width(100)
      .height(50)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .backgroundColor(this.isMacroModeEnabled ? Color.Red : Color.Blue)
      .onClick(() => {
        if (this.mDecodeBusiness) {
          const success = this.mDecodeBusiness.toggleMacroMode();
          this.isMacroModeEnabled = success;
        }
      })
      .margin({ top: -50, bottom: -10 });
  }
  @Builder
  preview(){
    Stack({
      alignContent: Alignment.Center
    }){
      XComponent({
        type: XComponentType.SURFACE,
        controller: this.previewVM.xComponentController
      })
        .width(this.previewVM.getPreviewWidth())
        .height(this.previewVM.getPreviewHeight())
        .onLoad(async () => {
          const getPermission = await this.getPermission();
          if(!getPermission)
            return;

          this.setPreviewVMReady();
        })
        .onClick(event => {
          const previewSize = this.previewVM.previewSize;
          const cameraPoint = calCameraPoint(
            this.getUIContext().vp2px(event.x),
            this.getUIContext().vp2px(event.y),
            previewSize.width,
            previewSize.height
          );

          // 使用动画方法显示聚焦框
          this.showFocusWithAnimation(event);
          // 执行手动相机聚焦
          if(this.mDecodeBusiness) {
            // 执行手动聚焦
            this.mDecodeBusiness.focusCamera(cameraPoint)//{ x:this.getUIContext().vp2px(event.x),y:this.getUIContext().vp2px(event.y) }
              .catch((error: Error) => {
                Logger.error(TAG, "Manual focus error: " + error.message);
              });
          }
        })
        //手势缩放相机
        .gesture(
          PinchGesture({ fingers: 2 })
            .onActionStart(() => {
              // 记录开始缩放前的当前缩放值
              this.originZoomBeforePinch = this.currentZoomValue;
              this.isZoomPinching = true;
            })
            .onActionUpdate((event:GestureEvent) => {
              const targetZoom = this.originZoomBeforePinch * event.scale;
              const minZoom = 1.0;
              const maxZoom = 4.0;
              this.currentZoomValue = Math.min(Math.max(targetZoom, minZoom), maxZoom);
              this.zoomText = this.currentZoomValue.toFixed(1);
              if (this.isQT) {
                this.qtZoomValue = this.currentZoomValue;
              } else {
                this.qrZoomValue = this.currentZoomValue;
              }
              if (this.mDecodeBusiness) {
                this.mDecodeBusiness.setZoomRatio(this.currentZoomValue);
              }
            })
            .onActionEnd(() => {
              this.isZoomPinching = false;  //缩放结束，重置状态
            })
        )
      // 聚焦框
      if (this.isFocusBoxVisible) {
        Image($r('app.media.focus_crosshair'))
          .width(120)
          .height(120)
          .fillColor(this.themeColor)
          .scale({ x: this.focusScale, y: this.focusScale }) // 添加缩放动画
          .position(this.focusBoxPosition)
      }
    }
  }

  @Builder
  ScanBoxMask(){
    ScanningEffectCanvasStatic({
      isQT:this.isQT,
      themeColor:this.themeColor,
      centerY: this.scanningEffectYPercent
    })
      .hitTestBehavior(HitTestMode.Transparent)//使得点击事件穿透到XComponent
      .onAreaChange((_, area: Area) => {
        let canvasWidth = area.width as number;//387.69
        let canvasHeight = area.height as number;//770.15
        let canvasWidthPX = vp2px(canvasWidth);//1260
        let canvasHeightPX = vp2px(canvasHeight);//2530
      })

    ScanningEffectCanvasDynamic({
      isQT:this.isQT,
      themeColor:this.themeColor,
      centerY: this.scanningEffectYPercent,
      //V2的方法
      // scanBoxInfo:(info:ScanBoxInfo)=>{//返回扫描框信息
      //   this.scanBoxInfo = info;
      //   //界面渲染完成
      // }
    })
      .hitTestBehavior(HitTestMode.Transparent)//使得点击事件穿透到XComponent
  }

  @Builder
  customMenuBuilder() {
    Column({ space: 2 }) {
      ForEach(this.getSelectOptions(), (option: SelectOption, index: number) => {
        Row({ space: 12 }) {
          // 图标使用主题色
          Image(option.icon)
            .width(20)
            .height(20)
            .fillColor(this.themeColor);

          Text(option.label)
            .fontSize(16)
            .fontColor(Color.White)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis }) // 超出省略
            .flexShrink(1) // 允许缩小
            .layoutWeight(1) // 占据剩余空间
        }
        .width('100%')
        .height(50)
        .padding({ left: 16, right: 10, top: 12, bottom: 12 })
        .onClick(async () => {
          await this.handleSelectAction(index);
          // 点击后关闭菜单
          this.selectVisible = false;
        })
      });
    }
    .borderRadius(15)
    .shadow({ radius: 0, color: Color.Transparent })
    .backgroundColor('rgba(0,0,0,0.3)')
    .width(120);
  }

  // 蓝牙图标
  @Builder
  buildBluetoothImage(){
    Row(){
      Blank().flexGrow(1)

      if(this.isConnected){
        Column(){
          Image($r('app.media.bluetooth'))
            .fillColor(this.themeColor)
            .width(60)
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.isBluetoothIconPressed = true;
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.isBluetoothIconPressed = false;
              }
            })
            .shadow({ radius: this.isBluetoothIconPressed ? 8 : 0, color: Color.Black, offsetX: 0, offsetY: 2 })
            .onClick(() => {
              this.goToPage('pages/BluetoothPage')
            })

          Stack(){
            if(!this.isPowerLow){
              Image($r('app.media.bluetooth_battery_ok'))
                .height(52)
                .fillColor(this.themeColor)
            }
            else {
              Image($r('app.media.bluetooth_battery')) // 这个低电量图标内使用了2种颜色，但是鸿蒙的api无法只替换一个所以不能修改外框颜色
                .height(52)
            }
            Text(this.elePower)
              .fontSize(11)
              .fontColor(Color.White)
          }
          .opacity(this.elePower === '' ? 0 : 1)
          .onAppear(() => {
            Logger.info(TAG, `蓝牙电量显示: ${this.elePower}, 是否低电量: ${this.isPowerLow}`);
          })
        }
        .width(70)
      }
      else {
        Image($r('app.media.bluetooth_disabled'))
          .fillColor(this.themeColor)
          .width(60)
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.isBluetoothIconPressed = true;
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.isBluetoothIconPressed = false;
            }
          })
          .shadow({ radius: this.isBluetoothIconPressed ? 8 : 0, color: Color.Black, offsetX: 0, offsetY: 2 })
          .onClick(() => {
            this.goToPage('pages/BluetoothPage')
          })
      }
    }
    .margin({ right: 23 })
    .height(90)
    .width('100%')
    .justifyContent(FlexAlign.Start)
  }

  //顶部标题栏
  @Builder
  buildHeader(){
    Row() {
      //返回
      Image($r('app.media.vector_drawable_headback'))
        .id('exit')
        .width(48) // 图标宽度
        .height(48) // 图标高度
        .margin({left: 20})
        .fillColor(this.themeColor)
        .borderRadius(8)
        .onClick(() => {
          // 初始化退出应用的确认条
          ConfirmDialog.init(this.getUIContext(), () => {
            this.popupManage?.hide(ConfirmDialog.fragment!)
          })
          this.popupManage.show(ConfirmDialog.fragment!)
        })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.isBackIconPressed = true;
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.isBackIconPressed = false;
          }
        })
        .shadow({ radius: this.isBackIconPressed ? 8 : 0, color: Color.Black, offsetX: 0, offsetY: 2 })
      Blank()

      //指导
      Image($r('app.media.vector_help'))
        .id('btnHelp')
        .width(60) // 图标宽度
        .height(60) // 图标高度
        .fillColor(this.themeColor)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.isHelpIconPressed = true;
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.isHelpIconPressed = false;
          }
        })
        .shadow({ radius: this.isHelpIconPressed ? 8 : 0, color: Color.Black, offsetX: 0, offsetY: 2 })
        .onClick(() => {
          // 点击跳转到设置页面
          this.goToPage('pages/GuidePage')        })
        .padding(10)
        .borderRadius(8)

      Blank()

      Image($r('app.media.vector_add_light'))
        .id('btnPlus')
        .width(55)
        .height(55)
        .margin({ right: 20 })
        .fillColor(this.themeColor)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.isMenuIconPressed = true;
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.isMenuIconPressed = false;
          }
        })
        .onClick(() => {
          this.selectVisible = false;
          animateTo({ duration: 0 }, () => {
            this.selectVisible = true;
          });
        })
        .shadow({ radius: this.isMenuIconPressed ? 8 : 0, color: Color.Black, offsetX: 0,  offsetY: 2  })
        .bindMenu(this.selectVisible,this.customMenuBuilder, {
          offset: { x: 50, y: 0 },
          onDisappear:() => {
            this.selectVisible = false;
          }
        } as MenuOptions)

    }
    .padding({ top:10 })
    .width('100%')
    .justifyContent(FlexAlign.SpaceEvenly) // 水平方向均匀分布
    .alignItems(VerticalAlign.Top)

  }

  // endregion

  //Select选项点击事件处理
  async handleSelectAction(index: number) {
    const options = this.getSelectOptions();
    const option = options[index];

    switch(option.id) {
      case 'share':
        await ShareDialog.init(this.getUIContext(), () => {
          this.popupManage.hide(ShareDialog.fragment!)
        })

        this.popupManage.show(ShareDialog.fragment!)
        break;
      case 'Screenshot':
        this.mDecodeBusiness?.screenshot(this.isConnected);//这里传入蓝牙连接状态，配置是否开启蓝牙设备截图
        break;
      case 'Login':
        Logger.info(TAG,'testtag 跳转login')
        this.goToPage('pages/LoginPage')
        break;
      case 'text_detector':
        this.goToPage('pages/BluetoothPage')
        break;
    }
  }

  getSelectOptions(): SelectOption[] {
    return [
      {id: 'share', label: ($r('app.string.btn_share')),icon: $r('app.media.share')},
      {id: 'Screenshot', label: ($r('app.string.btn_Screenshot')),icon: $r('app.media.photo')},
      {id: 'Login', label: this.isLogin ? ($r('app.string.login')) : ($r('app.string.login')),icon: this.isLogin ? $r('app.media.ic_login_ture') : $r('app.media.ic_login_person')},
      {id: 'text_detector', label: ($r('app.string.text_detector')),icon: $r('app.media.bluetooth2')},
    ];
  }

  showToast(msg:string,time:number){
    Logger.info(TAG,msg)
    promptAction.showToast({
      message: msg,
      duration: time
    });
  }

  showTipDialog(msg: Resource | string){
    this.getUIContext().showAlertDialog(
      {
        message: msg,
        autoCancel: false,
        alignment: DialogAlignment.Center,
        primaryButton: {
          value: $r('app.string.dialog_result_no'),
          fontColor: Color.Black,
          action: () => {}
        },
        secondaryButton: {
          value: $r('app.string.dialog_result_yes'),
          fontColor: Color.Black,
          action: () => {}
        }
      }
    )
  }

  /**
   * 满足可处理结果的条件（3个）
   * 1.当前界面没有弹窗
   * 2.当前ability的状态不能为Paused，Stop，Destroy这三种状态（此时ability不能与用户交互）
   * 3.当前没有要跳转（isJumpToAnother==false）
   *
   * @return boolean 是否满足可处理结果的条件
   */
  private isCanHandleResult(): boolean {
    return !this.isFloatPanelsExists()
      && !this.selectVisible
      && this.currentState !== ActivityState.Paused
      && this.currentState !== ActivityState.Stop
      && this.currentState !== ActivityState.Destroy
      && !this.isJumpSucceed;
  }

  /**
   * 判断当前界面是否存弹窗
   * @return boolean 是否存在弹窗
   */
  private isFloatPanelsExists(): boolean {
    return this.popupManage.existDialogs();
  }

  private closeDecodeLoading(): void {
    if (this.mWebDecodeService !== null && this.mWebDecodeService !== undefined) {
      this.mWebDecodeService.setIsRunning(false);
    }
    //todo mWebQcService未实现
    Logger.info('IndexPage', "closeDecodeLoading");
  }


  // 显示网络错误对话框
  private showSetNetworkDialog(): void {
    this.getUIContext().showAlertDialog({
      message: EntryUtils.getStringByResourceManager(this.context, $r('app.string.network_error')),
      autoCancel: true, // 允许点击对话框外部区域关闭对话框
      alignment: DialogAlignment.Center,
      offset: { dx: 0, dy: -20 },
      primaryButton: {
        value: EntryUtils.getStringByResourceManager(this.context, $r('app.string.feedback_btn_cancel')),
        fontColor: Color.Black,
        action: () => {
          Logger.info(TAG, "取消了网络设置对话框");
        }
      },
      secondaryButton: {
        value: EntryUtils.getStringByResourceManager(this.context, $r('app.string.setting_up_the_network')),
        fontColor: Color.Black,
        action: () => {
          // 实现跳转到系统网络设置页面的功能，安卓是跳转到无线网络设置，鸿蒙细分了wifi和移动网络
          Logger.info(TAG, "点击了网络设置按钮");
          let context = getContext(this) as common.UIAbilityContext;
          let want: Want = {
            bundleName: 'com.huawei.hmos.settings',
            abilityName: 'com.huawei.hmos.settings.MainAbility',
            uri: "wifi_entry",
            //uri: "mobile_network_entry",
            parameters: {
              // 传应用的包名
              pushParams: 'com.baoshen.HiddenCode'
            }
          };
          context.startAbility(want);
        }
      }
    });
  }
}

interface isLoginSuccess {
  isLoginSuccess?: boolean;
}

// 定义Select组件的选项类型
interface SelectOption {
  label: Resource | string;
  icon: Resource;
  id: string
}

export { IndexPage };
