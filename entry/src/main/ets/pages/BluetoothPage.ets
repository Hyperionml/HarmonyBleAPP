import { EntryUtils } from '../common/EntryUtils';
import { promptAction, router } from '@kit.ArkUI';
import { ble } from '@kit.ConnectivityKit';
import { systemDateTime } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, bundleManager } from '@kit.AbilityKit';
import { AppSetting } from '../common/AppSetting';
import { UserSetting } from '../common/UserSetting';
import WindowUtil from '../utils/WindowUtil';
import { BleDevice, BleManager, BleScanCallback, BleScanState, TextUtils } from '@ohos/fastble/Index';
import { DeviceManager, QTBle } from 'devices'
import { EventManager, Level } from 'common';
import { DeviceEvent } from 'devices/src/main/ets/DeviceEvent';
import { DeviceEventType } from 'devices/src/main/ets/DeviceEventType';
import { DeviceSetting } from 'devices/src/main/ets/bluetooth/DeviceSetting'
import i18n from '@ohos.i18n';
import { AppEvent } from '../common/event/AppEvent';
import { AppEventType } from '../common/event/AppEventType';
import { ArkTSUtils } from '@kit.ArkTS';
import { deviceInfo } from '@kit.BasicServicesKit';
import { intl } from '@kit.LocalizationKit';
import { BluetoothDevice } from 'devices/src/main/ets/DeviceManager';
import BuildProfile from 'BuildProfile';

let TAG = 'BluetoothActivity'
let atManager = abilityAccessCtrl.createAtManager()
let visibility: boolean
let deviceSetting: DeviceSetting | null = null

class TempBleScanCallback extends BleScanCallback {

  bluetoothPage: BluetoothPage | null = null

  constructor(bluetoothPage: BluetoothPage) {
    super()
    this.bluetoothPage = bluetoothPage
  }

  public onScanStarted(success: boolean): void {
    setScanProgressBarVisibility(true, this.bluetoothPage!);
  }

  public onLeScan(bleDevice: BleDevice): void {
  }

  public onScanFinished(scanResultList: BleDevice[]): void {
    setScanProgressBarVisibility(false, this.bluetoothPage!);
  }


  public async onScanning(bleDevice: BleDevice): Promise<void> {
    let device = ble.createGattClientDevice(bleDevice.mDeviceId);
    if (device != null) {
      let deviceName = "N/A";
      let deviceAddress = "N/A";

      let deviceClass = -1;
      let deviceBondState = -1;
      let deviceParcelUuidArray: [] = [];

      if (await device.getDeviceName() != null) {
        deviceName = bleDevice.getName()
      }
      if (bleDevice.getMac() != null) {
        deviceAddress = bleDevice.getMac()
      }
      // ble.GattClientDevice里面似乎没有uuid
      // if (bleDevice.getUuids() != null) {
      //   deviceParcelUuidArray = device.getUuids();
      // }

      console.log(TAG, " BLE NAME:" + deviceName + ";MAC:" + deviceAddress
        + ";CLASS:" + deviceClass + ";BOND:" + deviceBondState);
      if (deviceParcelUuidArray != null) {
        for (let n = 0; n < deviceParcelUuidArray.length; n++) {
          console.log(TAG,
            "BLE device name : " + deviceName + " ;Mac address  : "
              + deviceAddress + " ParcelUuidArray " + n + " : " + deviceParcelUuidArray[n]);
        }

      }

      if(this.bluetoothPage?.bleIsHas(bleDevice)) return

      if(bleDevice.getName().startsWith('QT')){
        this.bluetoothPage?.deviceList.unshift(bleDevice)
      }else {
        this.bluetoothPage?.deviceList.push(bleDevice)
      }

    }
  }
}


@Entry
@Component
struct BluetoothPage {
  @State themeColor: ResourceColor = ''
  @State selectDevice: string = 'null' // 这里不要写空串
  @State time: string = ''
  @State isRefreshing: boolean = false
  @State deviceList: BleDevice[] = []

  @State lastClickTime: number = 0

  appSetting = new AppSetting(this.getUIContext().getHostContext()!)
  userSetting = new UserSetting(this.getUIContext().getHostContext()!)

  async aboutToAppear(): Promise<void> {
    this.themeColor = await this.appSetting.getTheme()
    EntryUtils.setThemeColor(this.themeColor)

    // 如果已经连接了qt设备则在第二次进入界面是显示与qt设备的连接状态
    if (BuildProfile.BLE_MODE) {
      if (QTBle.getDevice() !== null) {
        this.selectDevice = (QTBle.getDevice() as BleDevice).getName();
      }
    } else {
      // 使用DeviceManager
      if (DeviceManager.getDevice() !== null) {
        this.selectDevice = DeviceManager.getDevice()!.deviceName;
      }
    }
    deviceSetting = DeviceSetting.getInstance(this.getUIContext().getHostContext()!)

    this.isRefreshing = true
    this.startScan()
    setTimeout(() => {
      this.isRefreshing = false
    }, 10000)
  }


  build() {
    Column() {
      Blank()
        .height(px2vp(WindowUtil.avoidArea.topRect.height))
        .width('100%')
        .backgroundColor($r('app.color.start_window_background'))
      this.buildHeader()
      this.line()

      ForEach(this.deviceList, (item: BleDevice) => {
        Row() {
          Text(item.mDeviceName === '' ? item.getMac() : item.getName())
            .fontSize(14)
            .fontColor(item.mDeviceName.startsWith('QT') ? $r('sys.color.black') : $r('app.color.languageSettingFontColor'))
            .flexGrow(1)
            .width('50%')

          if(item.mDeviceName === this.selectDevice){
            Text(this.time)
              .fontSize(14)
              .fontColor($r('app.color.lineColor'))
              .flexGrow(1)
              .width('25%')
          }

          Row({ space: 5 }) {
            if(item.mDeviceName === this.selectDevice){
              this.checkImg(1)
            }
            else {
              this.checkImg(0)
            }
          }

        }
        .height(35)
        .backgroundColor($r('app.color.start_window_background'))
        .width('100%')
        .padding({ left: 16, right: 10 })
        .onClick(async () => {
          await this.clickItem(item)
        })

        this.line()
      })
    }
    .backgroundColor($r('app.color.start_window_background'))
    .height('100%')
  }

  //顶部标题栏
  @Builder
  buildHeader(){
    Row() {
      Button({ type: ButtonType.Normal }) {
        Row() {
          Image($r('app.media.headback'))
            .width(30)
            .height(30)
            .fillColor(this.themeColor)
            .onClick(()=>{
              router.back();
            })
        }
        .margin({ right: 6, left: 6 })
      }
      .backgroundColor($r('app.color.start_window_background'))
      .borderRadius(5)

      Blank()

      // 探测器介绍
      Image($r('app.media.vector_help'))
        .width(36) // 图标宽度
        .height(36) // 图标高度
        .fillColor(this.themeColor)
        .onClick(() => {
          // 点击跳转到设置页面
          router.pushUrl({ url: 'pages/BluetoothGuidePage' })
            .catch((err:Error) => {
              console.error('跳转失败:', err);
            });
        })

      Blank()

      if(this.isRefreshing){
        LoadingProgress()
          .color(this.themeColor)
          .width(36)
          .height(36)
      }
      else {
        Image($r('app.media.refresh2'))
          .id('refresh')
          .fillColor(this.themeColor)
          .width(36)
          .height(36)
          .onClick(() => {
            this.deviceList = []
            this.isRefreshing = true
            setTimeout(() => {
              this.isRefreshing = false
            }, 10000)
            this.startScan()
          })
      }
    }
    .backgroundColor($r('app.color.start_window_background'))
    .borderRadius(5)
    .padding({ left: 12, right: 15, top: 10, bottom: 15 })
    .height(48)
    .width('100%')
  }

  @Builder
  line(){
    Divider()
      .height(1.5)
      .color($r('app.color.lineColor'))
      .width('100%')
      .margin({ left: 16, right: 16 }) // 与开关缩进对齐
  }

  @Builder
  checkImg(opacity: number){
    Image($r('app.media.check'))
      .width(30)
      .height(30)
      .objectFit(ImageFit.Contain)
      .fillColor(this.themeColor)
      .opacity(opacity)
  }

  async startScan(){
    console.log('testtag 扫描启动')
    //是否已经在扫描了
    if (BleManager.getInstance().getScanSate() === BleScanState.STATE_SCANNING) {
      console.log('testtag 已经在扫描了')
      return;
    }

    let isPermisstionsGranted: abilityAccessCtrl.GrantStatus | null = null
    try {
      isPermisstionsGranted = atManager.verifyAccessTokenSync(
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION).appInfo.accessTokenId,
        'ohos.permission.ACCESS_BLUETOOTH')

      console.log('testtag isPermisstionsGranted:', isPermisstionsGranted)
    }catch (e) {
      console.log('testtag e:', e)
    }



    //是否有扫描权限
    if (isPermisstionsGranted === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
      console.log('testtag 没权限')
      let permissionRequestResult = await EntryUtils.requestPermission(this.getUIContext().getHostContext()!, ['ohos.permission.ACCESS_BLUETOOTH'])

      if(!permissionRequestResult){
        promptAction.openToast({message: $r('app.string.text_not_supported_bluetooth')})
        router.back()
        return
      }

      // 在成功获取权限之后直接再次触发该方法
      this.startScan()

      return
    }

    //需要开启GPS才可以搜索蓝牙
    // if (isPermisstionsGranted === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
    //   atManager.requestPermissionsFromUser(this.getUIContext().getHostContext()!, ['ohos.permission.ACCESS_BLUETOOTH'])
    //     .then((res) => {
    //       if(res.authResults[0] === -1){
    //         promptAction.openToast({message: '没有蓝牙权限无法使用'})
    //         router.back()
    //       }
    //     })
    //   return
    // }

    if(QTBle.isSupportBle()){
      console.log('testtag 还真开始扫描了')
      BleManager.getInstance().scan(new TempBleScanCallback(this))
    }
    else {
      bluetoothNotSupportedTips()
    }
  }

  private showAlertDialog(){
    this.getUIContext().showAlertDialog(
      {
        message: $r('app.string.text_qt_detector_name_like'),
        autoCancel: false,
        alignment: DialogAlignment.Center,
        primaryButton: {
          value: $r('app.string.ok'),
          fontColor: Color.Black,
          action: () => {}
        },
        secondaryButton: {
          value: $r('app.string.btn_help'),
          fontColor: Color.Black,
          action: () => { router.pushUrl({ url: 'pages/BluetoothGuidePage' })}
        }
      }
    )
  }

  private toTimeString(time: number){
    if(deviceInfo.sdkApiVersion < 18 ){
      let formatter = new intl.DateTimeFormat('zh-CN', { dateStyle: 'short', timeStyle: 'medium', hourCycle: 'h24' });
      return formatter.format(new Date(time));
    }

    let formatter: i18n.SimpleDateTimeFormat | null = null
    try {
      formatter = i18n.getSimpleDateTimeFormatBySkeleton('yMdHm')
    }
    catch (e) {
      console.log('testtag e:', e)
    }
    return formatter!.format(new Date(time))
  }

  /**
   * 点击链接
   * @param device
   * @returns
   */
  async clickItem(device: BleDevice){
    console.log('testtag clickItem触发')
    let curTime = systemDateTime.getTime()

    if(curTime - this.lastClickTime < 1000){
      return false
    }

    let deviceName = device.getName()
    if(TextUtils.isEmpty(deviceName) || !deviceName.startsWith("QT")){
      this.showAlertDialog()
      return false
    }

    this.lastClickTime = curTime;

    this.selectDevice = ''

    let setting = new AppSetting(this.getUIContext().getHostContext()!)
    if(setting != null){
      this.selectDevice = device.getName()
      this.time = this.toTimeString(systemDateTime.getTime())
      console.log('testtag time: ', this.time)
    }

    let bleDevice: BleDevice | null = null
    this.deviceList.forEach((item) => {
      if(device.getName() === item.getName()){
        bleDevice = item
      }
    })

    //调整为，关闭现有的，然后不进行
    if(BuildProfile.BLE_MODE){
      if(!QTBle.isConnected()){
        this.selectDevice = device.getName()

        BleManager.getInstance().cancelScan()
        // 这是链接的入口
        QTBle.setDevice(bleDevice!)
      } else{
        QTBle.disconnectDevice()

        EventManager.sync('BluetoothActivity', new AppEvent(AppEventType.WaitingMask,Level.Common,true));
        setTimeout(() => {
          BleManager.getInstance().cancelScan();
          QTBle.setDevice(device);
        }, 1000)
      }
    }else {
      //使用DeviceManager进行蓝牙连接
      if (!DeviceManager.IsConnected()) {
        this.selectDevice = device.getName()

        BleManager.getInstance().cancelScan()
        // 设备类型适配：构造DeviceManager需要的BluetoothDevice
        const bluetoothDevice: BluetoothDevice = {
          deviceId: bleDevice!.mDeviceId,
          deviceName: bleDevice!.getName(),
          address: bleDevice!.getMac()
        };
        DeviceManager.setDevice(bluetoothDevice)
      } else {
        DeviceManager.disconnectDevice()

        EventManager.sync('BluetoothActivity', new AppEvent(AppEventType.WaitingMask, Level.Common, true));
        setTimeout(() => {
          BleManager.getInstance().cancelScan();
          // 构造新设备并发起连接
          const bluetoothDevice: BluetoothDevice = {
            deviceId: device.mDeviceId,        // BLE设备ID
            deviceName: device.getName(),      // BLE设备名称
            address: device.getMac()           // BLE设备MAC地址
          };
          DeviceManager.setDevice(bluetoothDevice);
        }, 1000)
      }
    }

    setTimeout(() => {
      // 连接之后返回主界面
      router.back()
    }, 3000)


    return true;
  }

  bleIsHas(bleDevice: BleDevice){
    let tag = false
    this.deviceList.forEach((item) => {
      if(item.getMac() === bleDevice.getMac()){
        tag = true
      }
    })
    return tag
  }

}

function setScanProgressBarVisibility(TempVisibility: boolean, bluetoothPage: BluetoothPage) {
  // 这里不能控制ui所以只传递值
  visibility = TempVisibility

  if(!visibility){
    EventManager.sync(bluetoothPage, new DeviceEvent(DeviceEventType.BluetoothDiscoverEnd, Level.Common));
  }
}

function bluetoothNotSupportedTips() {
  promptAction.openToast({message: $r('app.string.text_not_supported_bluetooth')})
}

function stringCompareTo(str1: string, str2: string): number {
  const len1 = str1.length;
  const len2 = str2.length;
  const minLength = Math.min(len1, len2);

  // 逐字符比较
  for (let i = 0; i < minLength; i++) {
    const charCode1 = str1.charCodeAt(i);
    const charCode2 = str2.charCodeAt(i);

    if (charCode1 !== charCode2) {
      return charCode1 - charCode2;
    }
  }

  // 如果公共部分相同，比较长度
  return len1 - len2;
}

@Concurrent
async function tempRunnable(device: BleDevice){
  EventManager.sync('BluetoothActivity', new AppEvent(AppEventType.WaitingMask,Level.Common,true));
  try {
    const conditionVariable: ArkTSUtils.locks.ConditionVariable = new ArkTSUtils.locks.ConditionVariable()
    conditionVariable.waitFor(2000)
  }
  catch (ex){

  }
  BleManager.getInstance().cancelScan();
  QTBle.setDevice(device);
}