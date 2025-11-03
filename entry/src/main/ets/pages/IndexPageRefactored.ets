/**
 * IndexPage
 * 基于MVVM架构和状态管理V1
 *
 * 说明:
 * 1. ViewModel层: IndexPageViewModel使用@Observed管理所有状态
 * 2. View层: 拆分为多个独立Component,使用@ObjectLink绑定ViewModel
 * 3. 业务逻辑: 保留在Page中,通过回调方式与Component交互
 */

import { promptAction, router } from '@kit.ArkUI';
import { EntryUtils } from '../common/EntryUtils';
import { common, Want } from '@kit.AbilityKit';
import { EventManager, Level, Logger, SoundPlayUtils, Sounds, ActivityState, Utils } from 'common';
import { DecodeBusiness } from '../decoder/DecodeBusiness';
import { Decoder } from '../decoder/Decoder';
import { WebDecodeService } from '../service/WebDecodeService';
import { IWebDecodeResultHandle } from '../service/IWebDecodeResultHandle';
import { DecodeResultDTO } from '../common/models/json/DecodeResult';
import { WebDecodeError } from '../service/WebDecodeError';
import vibrator from '@ohos.vibrator';
import { AbsProductManager } from '../common/ProductManager/AbsProductManager';
import { AppProductManager } from '../common/ProductManager/AppProductManager';
import { IProductManageListener } from '../common/ProductManager/IProductManageListener';
import { getCurrentProductType, ProductType } from '../common/ProductType';
import { PopupManage } from '../common/popup/PopupManage';
import { ProgressDialog } from '../component/Dialog/ProgressDialog';
import PermissionManager from '../utils/PermissionManager';
import CameraConstant from '../constants/Constants';
import RefreshableTimer from '../utils/RefreshableTimer';
import { calCameraPoint, calCameraPoint2, getClampedChildPosition } from '../utils/CommonUtil';
import WindowUtil from '../utils/WindowUtil';
import { Point } from '@kit.TestKit';
import { IndexPageReceiver } from '../receiver/IndexPageReceiver';
import PreviewViewModel from '../viewmodels/PreviewViewModel';
import { AppSetting } from '../common/AppSetting';
import { UserSetting } from '../common/UserSetting';
import { BusinessError, systemDateTime } from '@kit.BasicServicesKit';

//导入ViewModel
import { IndexPageViewModel } from '../viewmodels/IndexPageViewModel';
//导入组件

import { HeaderComponent } from '../component/HeaderComponent';
import { ZoomSliderComponent } from '../component/ZoomSliderComponent';
import { ModeSwitchComponent } from '../component/ModeSwitchComponent';
import { LoadingComponent } from '../component/LoadingComponent';

import { BottomToolBarComponent } from '../component/BottomToolBarComponent';
import { BluetoothIndicatorComponent } from '../component/BluetoothIndicatorComponent';
import { PreviewComponent } from '../component/PreviewComponent';
import { ScanBoxComponent } from '../component/ScanBoxComponent';
import { IndexPageRefactoredReceiver } from '../receiver/IndexPageRefactoredReceiver';
import { ConfirmParams } from '../common/DialogFragmentManege/ConfirmParams';
import { ConfirmDialog } from '../component/Dialog/ConfirmDialog';
import { ShareDialog } from '../component/Dialog/ShareDialog';
import { pasteboard } from '@kit.BasicServicesKit';
import { DecodeResultBean } from '../bean/DecodeResultBean';
import { DestroyProductManager } from '../common/ProductManager/DestroyProductManager';

const TAG = 'IndexPage';

// 菜单选项类型定义
interface SelectOption {
  id: string;
  label: Resource;
  icon: Resource;
}

// 创建一个实现IProductManageListener接口的类
class IndexPageProductManager implements IProductManageListener {
  private page: IndexPageRefactored;

  constructor(page: IndexPageRefactored) {
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
struct IndexPageRefactored {
  // ========== ViewModel层 ==========
  // 使用@State装饰ViewModel实例,使其成为响应式对象
  @State viewModel: IndexPageViewModel = new IndexPageViewModel();
  @State previewVM: PreviewViewModel = new PreviewViewModel(this.getUIContext());

  // ========== 业务逻辑层 ==========
  private context: Context = this.getUIContext().getHostContext()!;
  private mDecodeBusiness: DecodeBusiness | null = null;
  private mEventReceiver: IndexPageRefactoredReceiver | null = null;
  private mWebDecodeService: WebDecodeService | null = null;
  private mProductManager: AbsProductManager | null = null;
  private productManageListener: IProductManageListener = new IndexPageProductManager(this);
  private currentState: ActivityState = ActivityState.Unknow;
  private focusBoxTimer: RefreshableTimer = new RefreshableTimer(() => {
    this.viewModel.isFocusBoxVisible = false;
  }, 1.0 * 1000);

  @State popupManage: PopupManage = new PopupManage(this.getUIContext().getHostContext()!)
  appSetting = new AppSetting(getContext())
  userSetting = new UserSetting(getContext())

  // 网络解码回调
  private mWebDecodeResultHandle: IWebDecodeResultHandle = {
    onStartWebDecode: (): void => {
      if (this.isCanHandleResult()) {
        this.viewModel.updateLoadingState(true);
        this.startRotation();
      }
      this.viewModel.isJumpSucceed = false;
      Logger.info(TAG, "onStartWebDecode");
    },

    onEndWebDecode: (result: DecodeResultDTO, error: WebDecodeError): void => {
      this.viewModel.updateLoadingState(false);
      // 根据错误类型处理不同的情况
      switch (error) {
        case WebDecodeError.None:
          Logger.info(TAG, "None");
          if (this.isCanHandleResult()) {
            if (this.mProductManager) {
              this.mProductManager.processDecodeResult(result);
            }
          }
          this.viewModel.isJumpSucceed = false;
          break;
        case WebDecodeError.Cancel:
          Logger.info(TAG, "Cancel");
          if (this.isCanHandleResult()) {
            this.showToast(EntryUtils.getStringByResourceManager(this.context, $r('app.string.already_canceled_decoding')), 2000);
          }
          this.viewModel.isJumpSucceed = false;
          break;
        case WebDecodeError.Destroy:
          Logger.info(TAG, "Destroy");
          if (this.isCanHandleResult()) {
            this.showToast(EntryUtils.getStringByResourceManager(this.context, $r('app.string.code_map_is_destroyed')), 2000);
          }
          this.viewModel.isJumpSucceed = false;
          break;
        case WebDecodeError.OffLine:
          Logger.info(TAG, "OffLine");
          if (this.isCanHandleResult()) {
            // 显示网络错误对话框
            this.showSetNetworkDialog();
          }
          this.viewModel.isJumpSucceed = false;
          break;
        case WebDecodeError.Unknown:
          Logger.info(TAG, "Unknown");
          if (this.isCanHandleResult()) {
            this.showToast(EntryUtils.getStringByResourceManager(this.context, $r('app.string.unknown_exception')), 2000);
          }
          this.viewModel.isJumpSucceed = false;
          break;
        case WebDecodeError.ServerError:
          Logger.info(TAG, "ServerError");
          if (this.isCanHandleResult()) {
            this.showToast(EntryUtils.getStringByResourceManager(this.context, $r('app.string.server_error')), 2000);
          }
          this.viewModel.isJumpSucceed = false;
          break;
        case WebDecodeError.NetPermissionDenied:
          Logger.info(TAG, "NetPermissionDenied");
          if (this.isCanHandleResult()) {
              //todo 检查网络（相机）权限 后续权限做统一管理
          }
          this.viewModel.isJumpSucceed = false;
          break;
        case WebDecodeError.NoConnectedNetwork:
          Logger.info(TAG, "NoConnectedNetwork");
          if (this.isCanHandleResult()) {
            // 显示网络错误对话框
            this.showSetNetworkDialog();
          }
          this.viewModel.isJumpSucceed = false;
          break;
      }
      this.closeDecodeLoading();
    }
  };

  // ========== 生命周期 ==========
  async aboutToAppear(): Promise<void> {
    if(this.viewModel.isTesting){
      setInterval(()=>{
        Logger.info(TAG,'isCanHandleResult:' + this.isCanHandleResult())
      },5000)
    }

    console.log('testtag IndexPageRefactored start')
    this.setStatus(ActivityState.Created);
    Logger.warn(TAG, '生命周期已触发：aboutToAppear--开始');

    // 初始化主题
    const color = await this.appSetting.getTheme();
    EntryUtils.setThemeColor(color);
    this.viewModel.updateThemeColor(color);

    // 初始化业务
    this.init();

    // 同步登录状态
    await this.syncLoginState();

    // 初始化进度条弹窗
    ProgressDialog.init(this.getUIContext(), () => {
      this.popupManage.hide(ProgressDialog.fragment!)
    });

    // 监听屏幕变化
    this.addOrientationChangeEventListener();

    Logger.warn(TAG, '生命周期已触发：aboutToAppear--结束');
  }

  async onPageShow(): Promise<void> {
    Logger.warn(TAG, '生命周期已触发：onPageShow--开始');
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
    this.viewModel.isEnabledShowQRUrlResult = true
    this.viewModel.isJumpSucceed = false

    if (this.previewVM.getReady()) {
      if (!this.mDecodeBusiness?.isCameraInit()) {
        this.mDecodeBusiness?.startCamera(this.viewModel.currentZoomValue);
      }
    }

    // 刷新蓝牙显示状态
    this.viewModel.isBluetoothShowOnMain = await this.appSetting.getIsBluetoothShowOnMain();

    //重置页面跳转开关
    if (this.mProductManager && this.mProductManager instanceof AppProductManager) {
      this.mProductManager.isQTCanStartProductActivity(true);
      Logger.info('aaaTest','重置isQTCanStartProductActivity为true');
    }
    this.setStatus(ActivityState.Running);
    Logger.warn(TAG, '生命周期已触发：onPageShow--结束');
  }

  aboutToDisappear(): void {
    this.removeOrientationChangeEventListener();
    this.mDecodeBusiness?.releaseCamera();
    this.mDecodeBusiness?.releaseDecode();
    this.setStatus(ActivityState.Destroy);
    Logger.warn(TAG, '生命周期已触发：aboutToDisappear');
  }

  onPageHide(): void {
    this.mDecodeBusiness?.stopCamera();
    this.setStatus(ActivityState.Stop);
    this.viewModel.isFlashOn = false;
    Logger.warn(TAG, '生命周期已触发：onPageHide');
  }

  onBackPress(){
    let curTime = systemDateTime.getTime()

    if(curTime - this.viewModel.exitPressTime < 3000){
      //真正关闭程序,配置removeMissionAfterTerminate可在后台任务列表中删除
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      ctx.terminateSelf();
      return false
    }
    //提示弹窗
    this.getUIContext().getPromptAction().showToast({ message: $r('app.string.tips_double_click_exit') })
    this.viewModel.exitPressTime = curTime

    return true
  }

  onWillApplyTheme(theme: Theme): void {
    this.viewModel.themeColor = theme.colors.brand;
    Logger.info(TAG,'onWillApplyTheme:' + this.viewModel.themeColor)
  }

  // ========== 初始化方法 ==========
  init() {
    // 初始化网络解码服务
    this.mWebDecodeService = new WebDecodeService(this.context, this.mWebDecodeResultHandle);
    this.mWebDecodeService.heartbeat();

    // 解码器
    Decoder.getInstance().setIsQTCode(this.viewModel.isQT);

    // 相机与解码业务
    this.mDecodeBusiness = new DecodeBusiness(this.context, this.previewVM);

    // 事件接收器
    this.mEventReceiver = new IndexPageRefactoredReceiver(this);
    EventManager.attach(this.mEventReceiver, Level.High);

    // 初始化ProductManager
    this.initProductManager();
  }

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

  private async syncLoginState() {
    if (!this.userSetting) {
      return;
    }
    try {
      Logger.info(TAG,'开始同步登录状态...');
      const accessToken = await this.userSetting.getUserAccessToken();
      Logger.info(TAG,`获取到的accessToken: "${accessToken}"`);
      this.viewModel.isLogin = !!(accessToken && accessToken !== "");

      Logger.info(TAG,`登录状态: ${this.viewModel.isLogin}`);

    } catch (error) {
      Logger.info('同步登录状态异常:', error);
      this.viewModel.isLogin = false;
    }
  }

  // ========== UI构建 ==========
  build() {
    Stack() {
      // 相机预览层
      PreviewComponent({
        viewModel: this.viewModel,
        previewVM: this.previewVM,
        onLoad: () => { this.handlePreviewLoad() },//AI生成的代码，需要加{}
        onClickTmp: (event) => {
          this.handlePreviewClick(event)
        },
        onPinchStart: () => {
          Logger.info(TAG, '双指缩放开始');
        },
        onPinchUpdate: this.handleZoomChange.bind(this),
        onPinchEnd: () => {
          Logger.info(TAG, '双指缩放结束');
        }
      })

      // 扫描框层
      ScanBoxComponent({ viewModel: this.viewModel })

      Column() {
        // 顶部导航栏
        HeaderComponent({
          viewModel: this.viewModel,
          onBackClick: () => {
            this.handleBackClick()
          },
          onHelpClick: () => {
            this.goToPage('pages/GuidePage')
          },
          customMenuBuilder: this.customMenuBuilder.bind(this)
        })

        // 蓝牙指示器
        BluetoothIndicatorComponent({
          viewModel: this.viewModel,
          onBluetoothClick: () => {
            this.goToPage('pages/BluetoothPage')
          }
        })

        // 缩放滑块
        ZoomSliderComponent({
          viewModel: this.viewModel,
          onZoomChange: this.handleZoomChange.bind(this)
        })

        // 模式切换按钮
        ModeSwitchComponent({
          viewModel: this.viewModel,
          onModeSwitch: this.handleModeSwitch.bind(this),
          onZoomChange: this.handleZoomChange.bind(this),
          onPermissionRequest: this.getPermission,
          onShowToast: this.showToast.bind(this),
        })

        // 底部工具栏
        BottomToolBarComponent({
          viewModel: this.viewModel,
          onFeedbackClick: () => {
            this.goToPage('pages/FeedbackPage')
          },
          onFlashToggle: this.handleFlashToggle.bind(this),
          onSettingClick: () => {
            this.goToPage('pages/SettingsPage')
          }
        })

        // GPS信息
        Row() {
          Text(`[GPS] Provider：${(this.viewModel.location == null ? 'Unknow' : 'Gps')}  ${(this.viewModel.location == null ? '-' : this.viewModel.location.longitude)},${(this.viewModel.location == null ? '-' : this.viewModel.location.latitude)}`)
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
      .hitTestBehavior(HitTestMode.Transparent)
      .margin({ top: px2vp(WindowUtil.avoidArea.topRect.height) })

      // 加载提示层
      LoadingComponent({ viewModel: this.viewModel })
    }
    .width('100%')
    .height('100%')
  }

  // ========== 事件处理方法 ==========
  private async handlePreviewLoad() {
    const getPermission = await this.getPermission();
    if (getPermission) {
      this.setPreviewVMReady();
    }
  }

  private handlePreviewClick(event: ClickEvent): void {
    console.log('testtag handlePreviewClick触发')
    const previewSize = this.previewVM.previewSize;
    const cameraPoint = calCameraPoint(
      this.getUIContext().vp2px(event.x),
      this.getUIContext().vp2px(event.y),
      previewSize.width,
      previewSize.height
    );

    // 显示聚焦框动画
    this.showFocusWithAnimation(event);

    // 执行相机聚焦
    if (this.mDecodeBusiness) {
      this.mDecodeBusiness.focusCamera(cameraPoint)
        .catch((error: Error) => {
          Logger.error(TAG, "Manual focus error: " + error.message);
        });
    }
  }

  private handleZoomChange(value: number) {
    if (!this.mDecodeBusiness || !this.mDecodeBusiness.isCameraInit()) {
      return;
    }
    if (this.viewModel.isQT) {
      this.viewModel.qtZoomValue = value;
    } else {
      this.viewModel.qrZoomValue = value;
    }
    this.mDecodeBusiness.setZoomRatio(value);
  }


  private handleModeSwitch(isQT: boolean) {
    Decoder.getInstance().setIsQTCode(isQT);
    if (this.mDecodeBusiness) {
      this.mDecodeBusiness.setZoomRatio(this.viewModel.currentZoomValue);
    }

    const message = isQT ?
    EntryUtils.getStringByResourceManager(this.context, $r('app.string.txt_qtcode_supported')) :
    EntryUtils.getStringByResourceManager(this.context, $r('app.string.txt_barcode_supported'));
    this.showToast(message, 1000);
  }

  private handleFlashToggle(isOn: boolean) {
    if (this.mDecodeBusiness) {
      this.mDecodeBusiness.getCameraFlash(isOn);
    }
  }

  private async handleBackClick() {
    // 初始化退出应用的确认条
    await ConfirmDialog.init(this.getUIContext(), () => {
      this.popupManage?.hide(ConfirmDialog.fragment!)
    })
    this.popupManage.show(ConfirmDialog.fragment!)
  }

  // ========== 工具方法 ==========
  private showFocusWithAnimation(event: ClickEvent): void {
    // 从事件中提取坐标
    const point: Point = { x: event.x, y: event.y };

    // 计算位置
    const previewSize = this.previewVM.previewSize;
    const position = getClampedChildPosition(
      { width: 120, height: 120 },
      {
        width: this.getUIContext().px2vp(previewSize.width),
        height: this.getUIContext().px2vp(previewSize.height)
      },
      point
    );

    // 显示聚焦框并重置缩放
    this.viewModel.updateFocusBox(position, true);

    // 执行缩放动画：1.0 → 0.6
    animateTo({ duration: 400, curve: Curve.EaseOut }, () => {
      this.viewModel.focusScale = 0.6;
    });

    // 启动定时器，1.5秒后隐藏
    this.focusBoxTimer.refresh();
  }

  async getPermission(): Promise<boolean> {
    await PermissionManager.request(CameraConstant.PERMISSIONS, this.context)
      .catch((e:BusinessError) => {
      Logger.error(TAG,'获取相机权限失败' + e.message)
      return
    });
    const getCameraPermission = await Utils.checkPermission(this.context, 'ohos.permission.CAMERA');

    if (!getCameraPermission) {
      this.showToast(EntryUtils.getStringByResourceManager(this.context, $r('app.string.txt_no_camera_permission')), 1000);
      this.viewModel.getCameraPermission = false;
      return false;
    }

    this.viewModel.getCameraPermission = true;
    this.setPreviewVMReady();
    return true;
  }

  async setPreviewVMReady() {
    const location = await Utils.getGpsLocation(this.context);
    this.viewModel.updateLocation(location);

    this.previewVM.surfaceId = this.previewVM.xComponentController.getXComponentSurfaceId();
    this.previewVM.setPreviewSize();
    this.previewVM.xComponentController.setXComponentSurfaceRotation({ lock: true });
    this.previewVM.setControllerReady();
  }

  goToPage(url: string) {
    this.viewModel.isJumpSucceed = false;
    router.pushUrl({ url: url })
      .catch((err: Error) => {
        Logger.error(TAG, '跳转失败:' + err.message);
      });
  }

  showToast(msg: string, time: number) {
    Logger.info(TAG,msg)
    promptAction.showToast({
      message: msg,
      duration: time
    });
  }

  showTipDialog(msg: Resource | string) {
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


  private startRotation() {
    setInterval(() => {
      this.viewModel.angle += 10;
      if (this.viewModel.angle >= 360) {
        this.viewModel.angle = 0;
      }
    }, 150);
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
            .fillColor(this.viewModel.themeColor);

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
          this.viewModel.selectVisible = false;
        })
      });
    }
    .borderRadius(15)
    .shadow({ radius: 0, color: Color.Transparent })
    .backgroundColor('rgba(0,0,0,0.3)')
    .width(120);
  }


  private isCanHandleResult(): boolean {
    return !this.isFloatPanelsExists()
      && !this.viewModel.selectVisible
      && this.currentState !== ActivityState.Paused
      && this.currentState !== ActivityState.Stop
      && this.currentState !== ActivityState.Destroy
      && !this.viewModel.isJumpSucceed;
  }

  /**
   * 判断当前界面是否存弹窗
   * @return boolean 是否存在弹窗
   */
  private isFloatPanelsExists(): boolean {
    return this.popupManage.existDialogs();
  }

  private closeDecodeLoading(): void {
    if (this.mWebDecodeService !== null) {
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


  showCodeDialog(code: string) {
    if(!this.popupManage.existDialogs()) {
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
        this.mDecodeBusiness?.screenshot(this.viewModel.isConnected);//这里传入蓝牙连接状态，配置是否开启蓝牙设备截图
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
      {id: 'Login', label: this.viewModel.isLogin ? ($r('app.string.login')) : ($r('app.string.login')),icon: this.viewModel.isLogin ? $r('app.media.ic_login_ture') : $r('app.media.ic_login_person')},
      {id: 'text_detector', label: ($r('app.string.text_detector')),icon: $r('app.media.bluetooth2')},
    ];
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

  // ========== 屏幕方向监听 ==========
  private windowClass = (this.context as common.UIAbilityContext).windowStage.getMainWindowSync();
  private setPreviewSize: () => void = () => { this.previewVM.setPreviewSize(); }

  addOrientationChangeEventListener() {
    this.windowClass.on('windowSizeChange', this.setPreviewSize);
  }

  removeOrientationChangeEventListener() {
    this.windowClass.off('windowSizeChange', this.setPreviewSize);
  }

  // 业务方法的getter
  public getDecodeBusiness() { return this.mDecodeBusiness; }
  public getWebDecodeService() { return this.mWebDecodeService; }
  public getStatus() { return this.currentState; }
  public setStatus(value: ActivityState) { this.currentState = value; }
}
interface isLoginSuccess {
  isLoginSuccess?: boolean;
}
export { IndexPageRefactored };


