import { IEventReceiver,Event, Logger, EventManager, Level, Log, Sounds, ActivityState } from 'common';
import {
  BTActionHelp,
  BTBattery,
  BTProtocol, BTScanResult,
  BTSetSystemTime,
  DeviceEvent, DeviceEventType,
  DeviceManager,
  DeviceSetting, Pair, QTBle } from 'devices';
import { AppEvent } from '../common/event/AppEvent';
import { AppEventType } from '../common/event/AppEventType';
import { IndexPage }  from '../pages/IndexPage'
import { LoadingDialog, promptAction, router, TipsDialog } from '@kit.ArkUI';
import { TextUtils } from '@ohos/fastble/Index';
import { BaseApp } from '../common/BaseApp';
import { systemDateTime } from '@kit.BasicServicesKit';
import { DecodeResultBean } from '../bean/DecodeResultBean';
import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit';
import { WebDecodeService } from '../service/WebDecodeService';
import { image } from '@kit.ImageKit';
import { CommonDialogFragment } from '../common/DialogFragmentManege/CommonDialogFragment';
import { ProgressParams } from '../common/DialogFragmentManege/ProgressParams';
import { BsDecoderTypes } from '../bean/BsDecoderTypes';
import { ProgressDialog } from '../component/Dialog/ProgressDialog';
import { JSON5 } from '@wolfx/json5';
import { CodeTypes } from 'decoder'
import { EntryUtils } from '../common/EntryUtils';
import BuildProfile from 'BuildProfile';
import { ScanBoxSafeArea } from '../component/view/ScanningEffectCanvas';

const TAG = 'IndexPageReceiver'
let atManager = abilityAccessCtrl.createAtManager()

interface TempBTScanResult {
  IsSuccess: boolean
  Code: string
  Text: string
  Elapsed: number
}

export class IndexPageReceiver implements IEventReceiver {
  private context: IndexPage
  mWebDecodeService: WebDecodeService
  waitGpsDecodeResult: DecodeResultBean | null = null

  dialogControllerProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: $r('app.string.dialog_waiting')
    })
  })

  isJumpSucceed: boolean = false


  constructor(context: IndexPage) {
    this.context = context
    this.mWebDecodeService = this.context.getWebDecodeService()!
  }

  async onEvent(sender: Object|null, event: Event, isAsync: boolean): Promise<void> {
    if (event instanceof AppEvent) {
      const appEvent = event as AppEvent;
      switch (appEvent.getAppType()) {
        case AppEventType.Ready: {
          this.context.getDecodeBusiness()?.startDecode();
          break;
        }
        case AppEventType.DecodeService:{
          let result:DecodeResultBean = event.getData() as DecodeResultBean;
          Logger.warn(TAG,`Baoshen/ZXing 解码结果: ${result.getCode().toString()}/${result.getOtherResult().toString()},IsSuccess: ${result.IsSuccess().toString()},DecodeType: ${result.getDecodeType().toString()},CodeType: ${result.getCodeType()?.toString()}`)
          if (result.getDecodeType() == BsDecoderTypes.Baoshen) {
            if (result.IsSuccess()) {
              this.context.decodeTip();
              if (result.getCodeType() == CodeTypes.Other) {
                let otherType = result.getOtherType();
                let codeType = result.getCodeType();
                let otherResult = result.getOtherResult();
                let extData = result.getExtData();
                let isBaoShenCode = extData != null && extData.length > 0;
                let lower = otherResult.toLowerCase();
                if (isBaoShenCode && (lower.startsWith("http://") || lower.startsWith("https://"))) {
                  this.context.showUrl(otherResult);
                } else {
                  this.context.showToast(otherResult,1000);
                }
              }
              else{
                this.mWebDecodeService.start(result)
              }
            }
          } else {
            let text = result.getCode();
            if (!TextUtils.isEmpty(text)) {
              Logger.warn(TAG, 'Zxing decoding success:' + text);
              let lower = text.toLowerCase();
              this.context.decodeTip();
              if (lower.startsWith("http://") || lower.startsWith("https://")) {
                //在showUrl判断 if (isEnabledShowQRUrlResult) {
                  //isEnabledShowQRUrlResult = false;
                  this.context.showUrl(text);
                //}
              } else {
                this.context.showCodeDialog(text);
              }
            }
          }
          break;
        }
        case AppEventType.ScreenShot:{
          this.context.setScreenShot(event.getData() as image.PixelMap,0)
          break;
        }
        case AppEventType.ScreenShot2:{
          this.context.setScreenShot(event.getData() as image.PixelMap,1)
          break;
        }
        case AppEventType.ScreenShot3:{
          this.context.setScreenShot(event.getData() as image.PixelMap,2)
          break;
        }
        case AppEventType.ScanBoxInitted:{
          let displayCrop = event.getData() as image.Region
          this.context.previewVM.setScanBoxInfo(displayCrop)
          break;
        }
        case AppEventType.ScanBoxSafeArea:{
          let scanBoxSafeArea = event.getData() as ScanBoxSafeArea;
          this.context.isQTBottom = scanBoxSafeArea.Bottom.size.height - this.context.isQTSize - this.context.isQTBottomSpacing;
          this.context.sliderBottom = this.context.isQTBottom - 70 - this.context.isQTBottomSpacing / 2;//70为缩放条高度
          break;
        }
        case AppEventType.DisplayRotation:{
          if(this.context.getStatus() == ActivityState.Running){
            //停止相机
            this.context.getDecodeBusiness()?.stopCamera()
            //这里需要重置一下解码器
            this.context.getDecodeBusiness()?.releaseDecode()
            this.context.setStatus(ActivityState.Stop);
            let _this = this;
            setTimeout(()=>{
              _this.context.getDecodeBusiness()?.startCamera(this.context.currentZoomValue);
              this.context.setStatus(ActivityState.Running);
            },300)
          }
          break;
        }
        case AppEventType.PreviewReady:{
          // Preview准备完成，启动相机
          this.context.getDecodeBusiness()?.startCamera(this.context.currentZoomValue);
          break;
        }
        default:
          if(typeof appEvent.getData() == 'string'){
            this.context.showToast(appEvent.getData() as string,2000)
            Logger.info(TAG,appEvent.getData() as string)
          }
      }
    }
    else if(event instanceof DeviceEvent){
      const deviceEvent = event as DeviceEvent;
      switch (deviceEvent.getEventType()){
        case DeviceEventType.BluetoothConnectionStarted:{
          this.context.isConnected = true
          break;
        }
        case DeviceEventType.BluetoothConnectionSuccess: {
          if(true){ // 鸿蒙似乎没有状态this.mActivityState == ActivityState.Running || this.mActivityState == ActivityState.Resume
            promptAction.openToast({message: $r('app.string.text_bluetooth_connect_success')})

            this.context.isConnected = true

            let pair = event.getData() as Pair<string, string>
            let deviceName = pair != null ? pair.first : null;
            let address = pair != null ? pair.second : null;
            if (!TextUtils.isEmpty(deviceName) && deviceName!.startsWith("QT") && !TextUtils.isEmpty(address)) {
              BaseApp.getSetting(this.context.getUIContext().getHostContext()!).setLastBluetooth(address!);
              DeviceSetting.getInstance(this.context.getUIContext().getHostContext()!).setDeviceConnectTime(deviceName!, systemDateTime.getTime());
            }
          }
          break;
        }

        case DeviceEventType.BluetoothConnectionFailed: {
          // this.mActivityState == ActivityState.Running
          if(true) {
            EventManager.sync(this, new AppEvent(AppEventType.WaitingMask, Level.Common, false))

            EventManager.sync(this, new DeviceEvent(DeviceEventType.BluetoothBatteryUnknown, Level.Common))
            this.context.showTipDialog($r('app.string.text_bluetooth_connect_failed'))
            QTBle.disconnectDevice()
          }
          break;
        }

        case DeviceEventType.BluetoothDisconnected: {
          // this.mActivityState == ActivityState.Running || this.mActivityState == ActivityState.Resume
          if(true) {
            this.context.showTipDialog($r('app.string.text_bluetooth_disconnect'))

            this.context.isConnected = false
            QTBle.disconnectDevice()

            EventManager.sync(this, new DeviceEvent(DeviceEventType.BluetoothBatteryUnknown, Level.Common));
          }
            break;
        }

        case DeviceEventType.BluetoothCode: {
          console.log('testtag BluetoothCode事件')
          let bluetoothScanResult = JSON5.parse<TempBTScanResult>(JSON5.stringify(event.getData()))
          console.log(`testtag bluetoothScanResult: ${JSON5.stringify(bluetoothScanResult)}`)
          if (bluetoothScanResult !== null) {
            Log.i(TAG, "testtag [Bluetooth]Scan Code:" + bluetoothScanResult.Code + "Elapsed:" + bluetoothScanResult.Elapsed)
            if(bluetoothScanResult.IsSuccess) {
              this.context.decodeTip();
              let result = new DecodeResultBean()
              result.setCode(bluetoothScanResult.Code)
              result.setCodeType(CodeTypes.Third)
              result.setSuccess(bluetoothScanResult.IsSuccess)
              console.log(`testtag result: ${JSON5.stringify(result)}`)

              this.mWebDecodeService.start(result)
              Logger.info('aaaTest',JSON5.stringify(result))

              // 这里无法进入this.mWebDecodeService.start(result)分支触发start()
              if(await this.checkGpsPermission()) {//requestGpsPermissionCount的判定在前 requestGpsPermissionCount > 0 ||
                Logger.info('ljj',JSON5.stringify(result))
                this.mWebDecodeService.start(result);
              }
              else{
                this.waitGpsDecodeResult = result;
              }
            }
          }
          break;
        }

        case DeviceEventType.TakePhoto: {
          console.log(`testtag TakePhoto事件`)
          //先判断蓝牙是否连接
          if(this.context.isConnected){
            // 进度归零
            ProgressDialog.progressNode.update(new ProgressParams('', 0))
            // 打开弹窗
            this.context.popupManage.show(ProgressDialog.fragment!)
            // 调用设备截图
            if(BuildProfile.BLE_MODE){
              QTBle.setIsTakePhoto(true)
            }else {
              DeviceManager.setIsTakePhoto(true)
            }
          }
          break
        }

        case DeviceEventType.CheckBluetoothVersion: {
          console.log(`testtag CheckBluetoothVersion事件`)
          EventManager.sync(this, new AppEvent(AppEventType.WaitingMask, Level.Common, true));
          QTBle.write(BTProtocol.write(BTActionHelp.makeRequestVersionAction())); // 20 20 2
          break
        }

        case DeviceEventType.SetBluetoothSysTime: {
          console.log(`testtag SetBluetoothSysTime事件`)
          QTBle.write(BTProtocol.write(new BTSetSystemTime())); // 20 20 20 2
          break
        }

        case DeviceEventType.CheckBluetoothVersionEnd: {
          EventManager.sync(this, new AppEvent(AppEventType.WaitingMask, Level.Common, false));
          break
        }

        case DeviceEventType.BluetoothCanUpdate: {
          if (QTBle.isConnected() && QTBle.getIsBatteryLow() != null && QTBle.getIsBatteryLow()!) {
            this.context.showTipDialog($r('app.string.text_cannot_update_bluetooth_by_low_battery'))
            return
          }
          EventManager.sync(this, new AppEvent(AppEventType.WaitingMask, Level.Common, false));
          if (await QTBle.setBluetoothUpdate()) {

            // 进度归零
            ProgressDialog.progressNode.update(new ProgressParams('更新中', 0))
            // 打开弹窗
            this.context.popupManage.show(ProgressDialog.fragment!)
          }
          break
        }

        case DeviceEventType.TransferProgress: {
          let progress = 100.;
          if (event.getData() != null) {
            progress = Number(event.getData()!.toString())
          }
          if (progress < 99.9) {
            // 更新进度
            ProgressDialog.progressNode.update(new ProgressParams('更新中', progress))
          } else {
            //蓝牙截图保存到相册
            await this.context.getDecodeBusiness()?.saveDeviceScreenshot();
            ProgressDialog.progressNode.update(new ProgressParams('更新中', 0))
            this.context.popupManage.hide(ProgressDialog.fragment!)// 关闭进度条
          }
          break
        }

        case DeviceEventType.BluetoothQC: {
          break
        }

        case DeviceEventType.BluetoothBatteryUnknown: {
          this.context.elePower = ''
          break
        }

        case DeviceEventType.BluetoothBattery: {
          Log.d('DeviceManager', "收到蓝牙电量事件");

          let batteryResult = event.getData() as BTBattery
          if (batteryResult != null) {
            let batteryPercent = Math.round(batteryResult.getBatteryPercent())
            let isBatteryChangedToLow: boolean = batteryResult.IsChangedToLow()

            // 有时候会出现电量高于100，当高于100时改为显示100
            let tempPower = batteryPercent >= 100 ? 100 : batteryPercent

            Log.d(TAG, `更新电量显示: ${tempPower}%`);
            this.context.elePower = tempPower + '%'
            this.context.isPowerLow = false

            if (isBatteryChangedToLow) {
              this.context.isPowerLow = true
              EventManager.async(this, new AppEvent(AppEventType.Voice, Level.Common, Sounds.Error));
              this.context.showTipDialog($r('app.string.message_bluetooth_battery_warning'))
              promptAction.openToast({message: $r('app.string.message_bluetooth_battery_warning')})
            } else {
              this.context.isPowerLow = false
            }
          } else {
            Log.e(TAG, "电池对象为空");
          }
          break
        }

        case DeviceEventType.BluetoothAutoConnect: {
          let bluetoothAddress = await BaseApp.getSetting(this.context.getUIContext().getHostContext()!).getLastBluetooth()
          if (!TextUtils.isEmpty(bluetoothAddress)) {
            let permissions: string[] = []
            permissions.push('ohos.permission.ACCESS_BLUETOOTH');

            let permissionsAndDesc: Pair<string, string>[] = []
            for (let i = 0; i < permissions.length; i++) {
              permissionsAndDesc[i] = new Pair(permissions[i], i == 0 ?
                this.context.getUIContext().getHostContext()!.resourceManager.getStringSync($r('app.string.txt_require_bluetooth').id) : '')
            }
            if(await this.isPermissionsGranted(permissions as Permissions[])) {
              // 这里有一堆注释代码，没复制过来
            }
          }
          break
        }

        case DeviceEventType.ReceivedFile: {
          //                    EventManager.sync(null, new AppEvent(AppEventType.ShowFragment, Level.Common, MainActivity.PictureFragmentIndex));
          //                    KeyValuePair<String, String> fileMsg = (KeyValuePair<String, String>) event.getData();
          //                    if (fileMsg != null) {
          //                        String filePath = fileMsg.getKey();
          //                        String jpgPath = PictureFragment.saveToJpeg(filePath);
          //                        if (!TextUtils.isEmpty(jpgPath)) {
          //                            PictureFragment fragment = (PictureFragment) lstFrg.get(PictureFragmentIndex);
          //                            fragment.setImage(jpgPath, ".jpg");
          //                        }
          //                    }
          break;
        }
      }
    }
  }

  async checkGpsPermission(): Promise<boolean>{
    let re: boolean = false
    let res = await EntryUtils.requestPermission(this.context.getUIContext().getHostContext()!, ['ohos.permission.APPROXIMATELY_LOCATION'])

    if(!res){
      promptAction.openToast({message: $r('app.string.text_not_supported_bluetooth')})
    }
    else {
      re = true
    }

    return re
  }

  async isPermissionsGranted(permissions: Permissions[]){
    // 检查权限列表中的所有权限是否已经获取
    let permissionRe = await EntryUtils.requestPermission(this.context.getUIContext().getHostContext()!, permissions)

    return permissionRe;
  }

}