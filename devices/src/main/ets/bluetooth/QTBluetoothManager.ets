import { EventManager, Level } from 'common';
import { fileIo as fs } from '@kit.CoreFileKit';
import { Log } from 'common/src/main/ets/Log';
import { KeyValuePair } from 'common/src/main/ets/collection/KeyValuePair';
import { BTActionHelp } from '../bluetooth//BTActionHelp';
import { BluetoothBatteryMonitor, IBluetoothBatteryCallback } from './BluetoothBatteryMonitor';
import { BluetoothSocketCallback, SppSocket } from './SppSocket';
import { QTBleReader } from '../QTBleReader';
import { BTProtocol } from '../bluetooth/BTProtocol';
import { BTReport } from '../bluetooth/BTReport';
import { BTSection } from '../bluetooth/BTSection';
import { BTSectionType } from '../bluetooth/BTSectionType';
import { BTProtocolType } from '../bluetooth/BTProtocolType';
import { DeviceEvent } from '../DeviceEvent';
import { DeviceEventType } from '../DeviceEventType';
import { BTScanResult } from '../model/BTScanResult';
import { BTQCResult } from '../model/BTQCResult';
import { BTBattery } from '../model/BTBattery';
import { BTVersion } from '../model/BTVersion';
import { BTRequest } from '../model/BTRequest';
import { BTRequestFile } from '../model/BTRequestFile';
import { BTResponseFile } from '../model/BTResponseFile';
import { BTWaitForTransfer } from '../model/BTWaitForTransfer';
import { TextUtils } from '@ohos/fastble';
import { BuildConfig } from '../BuildConfig';
import { BluetoothFileReceiverSetting } from './BluetoothFileReceiverSetting';
import { BluetoothFileReceiver } from './BluetoothFileReceiver';
import { FileUtils } from 'common';
import { systemDateTime } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { QTBluetoothDevice } from './QTBluetoothDevice';

const APPLICATION_UUID = '00001101-0000-1000-8000-00805F9B34FB';
const TAG = 'QTBluetoothManager';

class IBluetoothBatteryCallbackImp implements IBluetoothBatteryCallback {
  send(): void {
    if (QTBluetoothManager.isTransferFile()) return;
    QTBluetoothManager.write(BTProtocol.write(BTActionHelp.makeRequestBatteryAction()));
  }
  checkReceive(time: number): boolean { return true; }
  offline(): void {
    if (QTBluetoothManager.getBatteryMonitor()){
      QTBluetoothManager.getBatteryMonitor().stop();
    }
  }
}

class TempBluetoothSocketCallback extends BluetoothSocketCallback {
  onStartConnect = () => {};
  onConnectFail = () => { /* 分发失败事件 */ };
  onConnectSuccess = () => { /* 分发成功事件/启动电量监控 */ };
  onDisConnected = () => { /* 调 cleanup 与分发断开事件 */ };
  onRead = async (bytes: Uint8Array) => {
    await QTBluetoothManager.handleData(bytes)
  };
};

//todo 与QTBle一致，如何重构
export class QTBluetoothManager{
  private static instance: QTBluetoothManager = new QTBluetoothManager();

  private static socket: SppSocket;
  //监听数据返回，reader同样用QTBleReader
  private static reader:QTBleReader;
  private static batteryMonitor: BluetoothBatteryMonitor;

  private deviceAddress: string | null = null;
  private device: QTBluetoothDevice |null = null;

  private static isCancel = false;
  private static isConnected = false;
  private static lastTransferFileTime = 0;
  private static bluetoothVersion: string | null = null

  private static isBatteryLow: boolean | null = false;
  private static batteryValue: number | null = null;

  private static isTakePhoto = false;//是否要拍照
  private static bluetoothFileReceiverSetting: BluetoothFileReceiverSetting | null = null
  private static bluetoothFileReceiver: BluetoothFileReceiver | null = null
  private static sppCallback: TempBluetoothSocketCallback = new TempBluetoothSocketCallback()


  public static getBatteryMonitor() {
    return QTBluetoothManager.batteryMonitor
  }

  public static setBluetoothFileReceiver(bluetoothFileReceiver: BluetoothFileReceiver | null){
    QTBluetoothManager.bluetoothFileReceiver = bluetoothFileReceiver
  }

  public static getBluetoothFileReceiverSetting(){
    return QTBluetoothManager.bluetoothFileReceiverSetting
  }

  public static setLastTransferFileTime(lastTransferFileTime: number){
    QTBluetoothManager.lastTransferFileTime = lastTransferFileTime
  }

  public static getBluetoothFileReceiver(){
    return QTBluetoothManager.bluetoothFileReceiver
  }

  public static setBluetoothFileReceiverSetting(bluetoothFileReceiverSetting: BluetoothFileReceiverSetting){
    QTBluetoothManager.bluetoothFileReceiverSetting = bluetoothFileReceiverSetting
  }

  public static getBluetoothVersion(){
    return QTBluetoothManager.bluetoothVersion
  }

  public static setBluetoothVersion(bluetoothVersion: string){
    QTBluetoothManager.bluetoothVersion = bluetoothVersion
  }

  public static getIsBatteryLow(): boolean | null { return QTBluetoothManager.isBatteryLow; }
  public static setIsBatteryLow(isBatteryLow: boolean){
    QTBluetoothManager.isBatteryLow = isBatteryLow
  }

  public static getBatteryValue(): number | null { return QTBluetoothManager.batteryValue; }
  public static setBatteryValue(batteryValue: number){
    QTBluetoothManager.batteryValue = batteryValue
  }

  private constructor() {
  }

  public static getInstance(): QTBluetoothManager {
    return QTBluetoothManager.instance
  }

  public init(): void {
    QTBluetoothManager.reader = new QTBleReader();
    QTBluetoothManager.socket = new SppSocket();
    QTBluetoothManager.batteryMonitor = new BluetoothBatteryMonitor();

  }

  public async connect(address: string): Promise<void> {
    this.deviceAddress = address;
    QTBluetoothManager.isCancel = false;
    QTBluetoothManager.isBatteryLow = null;
    QTBluetoothManager.batteryValue = null;

    EventManager.async(TAG, new DeviceEvent(DeviceEventType.BluetoothConnectionStarted, Level.Common));
    try {
      if (!QTBluetoothManager.socket) QTBluetoothManager.socket = new SppSocket();
      if (!QTBluetoothManager.reader) QTBluetoothManager.reader = new QTBleReader();

      // 用BleReader去读：SPP → Reader.mergeRead → 解析
      QTBluetoothManager.socket.setCallback(QTBluetoothManager.sppCallback);

      await QTBluetoothManager.socket.connect(address, APPLICATION_UUID, true);
      QTBluetoothManager.isConnected = true;

      // 电量轮询
      QTBluetoothManager.batteryMonitor?.start(new IBluetoothBatteryCallbackImp());

      // 连接成功
      EventManager.async(TAG, new DeviceEvent(DeviceEventType.BluetoothConnectionSuccess, Level.Common, null));
    } catch (e) {
      let error = e as Error;
      Log.e(TAG,error.message);
      EventManager.async(TAG, new DeviceEvent(DeviceEventType.BluetoothConnectionFailed, Level.Common, e));
      if (!QTBluetoothManager.isCancel) {
        EventManager.async(TAG, new DeviceEvent(DeviceEventType.BluetoothDisconnected, Level.Common));
      }
    }
  }

  public static async handleData(bytes: Uint8Array) :Promise<void>{
    try {
      const buff = await QTBluetoothManager.reader!.mergeRead(bytes);
      if (!buff) return;
      const report = BTProtocol.read(buff, 0, buff.length) as BTReport | null;
      if (report) QTBluetoothManager.handleReport(report, buff);
      QTBluetoothManager.maybeRequestNextFileBlock();
    } catch (e) {
      let error = e as Error;
      Log.e(TAG,error.message);
    }
  }

  public async disconnect(): Promise<void> {
    try { QTBluetoothManager.batteryMonitor?.stop(); } catch (_) {}
    try { QTBluetoothManager.socket?.setCallback(null); } catch (_) {}
    try { await QTBluetoothManager.socket?.close(); } catch (_) {}

    QTBluetoothManager.isConnected = false;
    QTBluetoothManager.isCancel = false;
    QTBluetoothManager.lastTransferFileTime = 0;
    QTBluetoothManager.isBatteryLow = null;
    QTBluetoothManager.batteryValue = null;
    QTBluetoothManager.bluetoothFileReceiver = null;
    this.deviceAddress = null;

    EventManager.async(TAG, new DeviceEvent(DeviceEventType.BluetoothDisconnected, Level.Common));
  }

  private stopBattery(): void {
    try { QTBluetoothManager.batteryMonitor?.stop(); } catch (_) {}
  }

  public isConnectedNow(): boolean {
    if (QTBluetoothManager.isConnected) QTBluetoothManager.isConnected = !!(QTBluetoothManager.socket && QTBluetoothManager.socket.isConnected());
    return QTBluetoothManager.isConnected;
  }

  public static write(content: Uint8Array): boolean {
    try {


      if (!QTBluetoothManager.socket || !QTBluetoothManager.socket.isConnected()) return false;
      // 如需严格串行，可加写队列；此处直接写
      void QTBluetoothManager.socket.write(content);
      return true;
    } catch (e) {
      let error = e as Error;
      Log.e(TAG,error.message);
      return false;
    }
  }

  public static isTransferFile(): boolean {
    return Date.now() - QTBluetoothManager.lastTransferFileTime < 2 * 60 * 1000;
  }

  public static isIsTakePhoto() {
    return QTBluetoothManager.isTakePhoto;
  }

  public static setIsTakePhoto(isTakePhoto: boolean) {
    if(QTBluetoothManager.isConnected){
      let request = new BTRequest();
      request.setRequestType(BTRequest.TYPE_PHOTO);
      QTBluetoothManager.write(BTProtocol.write(request));//请求拍照
      return true;
    }
    else {
      QTBluetoothManager.isTakePhoto = isTakePhoto;
      return false;
    }
  }

  public static async setBluetoothUpdate(){
    let filePath = await QTBluetoothManager.getNewVersion(QTBluetoothManager.bluetoothVersion!);
    let request = new BTWaitForTransfer();
    if(TextUtils.isEmpty(filePath!)){
      return false;
    }
    let fileType = FileUtils.getExtName(filePath!)

    let md5 = ''//com.baoshen.decoder.Utils.getMD5ofFile(filePath);
    request.setFileName(filePath!)
    request.setMD5(md5)
    request.setTotalLength(fs.statSync(filePath).size)
    request.setFileType(fileType!)
    QTBluetoothManager.write(BTProtocol.write(request));//请求拍照
    return true;
  }

  public static async getNewVersion(oldVersion: string){
    if (TextUtils.isEmpty(oldVersion)) {
      return null;
    }
    let filePath = null;
    let fileType = ".zip";
    let dir: fs.Stat | null = null;
    let files: string[]
    if (BuildConfig.DEBUG) {
      dir = fs.statSync(await FileUtils.getDownloadDir())
      files = fs.listFileSync((getContext() as common.UIAbilityContext).filesDir)
    } else {
      let path = await FileUtils.getAppExternalDirectory(getContext() as common.UIAbilityContext, FileUtils.AppCacheDir)
      dir = fs.statSync(path)
      files = fs.listFileSync(path)
    }
    let maxUpdateFile = -1;
    for (let item of files) {
      let fileName = item
      if (fileName.endsWith(".zip")) {
        let subName = fileName.substring(0, fileName.length - 4);
        try {
          let value = parseInt(subName, 10);
          if (value > maxUpdateFile) {
            maxUpdateFile = value;
          }
        } catch (ex) {}
      }

    }
    if (maxUpdateFile <= parseInt(oldVersion, 10)) {
      return null;
    }

    let newFile = fs.openSync(dir + String(maxUpdateFile) + ".zip")
    let updateFile = fs.openSync(dir + "update.zip")
    if (!FileUtils.copy(newFile.path, updateFile.path)) {
      return null;
    }
    return updateFile.path
  }

  /**
   * 数据逻辑
   * */
  private static async handleReport(report: BTReport, buff: Uint8Array): Promise<void> {
    const sections: Array<BTSection> = report.getSection();
    if (!sections || sections.length === 0) return;

    const first = sections[0];
    if (first.getSectionType() !== BTSectionType.Json) return;

    const json = first.getJson();
    if (TextUtils.isEmpty(json)) return;

    try {
      if (json?.includes(BTProtocolType.ScanResult.getSymbol())) {
        if(BuildConfig.DEBUG){
          let chars: string[]// = new string[buff.length*2];
          let result: string = ''
          for (let b of buff) {
            let temp = (b & 0xff).toString(16)
            if (temp.length == 1) {
              temp = "0" + temp;
            }
            result += temp;
            result += " , ";
          }
          Log.d("ScanResult",result);
        }
        let scanResult: BTScanResult = JSON.parse(json) as BTScanResult
        EventManager.async(TAG, new DeviceEvent(DeviceEventType.BluetoothCode, Level.Common,scanResult))
      } else if (json?.includes(BTProtocolType.QCResult.getSymbol())) {

        let qcResult: BTQCResult = JSON.parse(json) as BTQCResult
        EventManager.async(TAG, new DeviceEvent(DeviceEventType.BluetoothQC,Level.Common,qcResult))

      } else if (json?.includes(BTProtocolType.BatteryResult.getSymbol())) {

        let batteryResult = JSON.parse(json) as BTBattery
        let isLowOld = QTBluetoothManager.getIsBatteryLow()
        QTBluetoothManager.setBatteryValue(batteryResult.getBatteryPercent())
        //蓝牙电量变为低电量了
        if((isLowOld ==null && batteryResult.IsBatteryLow()) || isLowOld !=null && !isLowOld && batteryResult.IsBatteryLow()){
          batteryResult.setChangedToLow(true);
        }
        QTBluetoothManager.setIsBatteryLow(batteryResult.IsBatteryLow())
        EventManager.async(TAG, new DeviceEvent(DeviceEventType.BluetoothBattery,Level.Common,batteryResult));

      }
      else if(json?.includes(BTProtocolType.Version.getSymbol())){

        let versionResult: BTVersion = JSON.parse(json) as BTVersion
        EventManager.async(TAG, new DeviceEvent(DeviceEventType.BluetoothVersion, Level.Common, versionResult.getAppVersion()));
        let newVersionFile = await QTBluetoothManager.getNewVersion(versionResult.getAppVersion());
        QTBluetoothManager.setBluetoothVersion(versionResult.getAppVersion())

        if(!TextUtils.isEmpty(newVersionFile)){
          EventManager.async(null,new DeviceEvent(DeviceEventType.BluetoothCanUpdate,Level.Common,QTBluetoothManager.getBluetoothVersion()));
        }
        else{
          //不需要升级；或旧的版本不支持升级
          EventManager.async(null,new DeviceEvent(DeviceEventType.CheckBluetoothVersionEnd,Level.Common,QTBluetoothManager.getBluetoothVersion()));
        }
      }
      else if(json?.includes(BTProtocolType.WaitForTransfer.getSymbol())) {

        let waitForTransfer: BTWaitForTransfer = JSON.parse(json).BTWaitForTransfer
        //如果有旧的未完成的文件，也放弃掉
        QTBluetoothManager.setBluetoothFileReceiverSetting(BluetoothFileReceiverSetting.getInstance(getContext()))
        QTBluetoothManager.setBluetoothFileReceiver(
          await BluetoothFileReceiver.createFromContext(getContext() as common.UIAbilityContext,
            waitForTransfer.getFileName(),
            waitForTransfer.getFileType(),
            waitForTransfer.getMD5(),
            waitForTransfer.getTotalLength()
          )
        )

      }
      else if(json?.includes(BTProtocolType.RequestFile.getSymbol())){

        let requestFile: BTRequestFile = JSON.parse(json!) as BTRequestFile
        let responseFile: BTResponseFile = new BTResponseFile();
        let block = FileUtils.read(requestFile.getFileName(),requestFile.getBegin(),requestFile.getRequestLength())
        if(block != null && block.length>0) {
          responseFile.setBegin(requestFile.getBegin());
          responseFile.setFileName(requestFile.getFileName());
          responseFile.setResponseLength(block.length);
          QTBluetoothManager.setLastTransferFileTime(systemDateTime.getTime())
          QTBluetoothManager.write(BTProtocol.writeContent(JSON.stringify(responseFile),block));
          let fileTotalLength = FileUtils.getFileLength(requestFile.getFileName());
          let progress = 100.;
          if(fileTotalLength<=0){
            //文件异常了
            EventManager.async(null,new DeviceEvent(DeviceEventType.TransferProgress, Level.Common, progress));
          }
          else{
            progress = (block.length+requestFile.getBegin())*100.0/fileTotalLength;
            EventManager.async(null,new DeviceEvent(DeviceEventType.TransferProgress, Level.Common, progress));
          }
        }
        else{
          Log.e(TAG,"无法读取文件(蓝牙)");
        }
        //todo 处理文件
      }
      else if(json?.includes(BTProtocolType.ResponseFile.getSymbol())){
        let responseFile = JSON.parse(json!) as BTResponseFile
        if(sections.length > 1){
          let contentSection = sections[0]
          if(QTBluetoothManager.getBluetoothFileReceiver() != null && !QTBluetoothManager.getBluetoothFileReceiver()?.isComplete()){
            if(QTBluetoothManager.getBluetoothFileReceiver()?.receive(contentSection.getContent()!,responseFile.getBegin(),responseFile.getResponseLength())) {
              let progress = QTBluetoothManager.getBluetoothFileReceiver()?.getProgress();
              EventManager.async(null, new DeviceEvent(DeviceEventType.TransferProgress, Level.Common, progress));
            }
            else{
              EventManager.async(null, new DeviceEvent(DeviceEventType.TransferProgress, Level.Common, 100));
              Log.e(TAG, "无法写入文件(蓝牙)");
            }
          }
          if(QTBluetoothManager.getBluetoothFileReceiver() !=null && QTBluetoothManager.getBluetoothFileReceiver()?.isComplete()){
            if(QTBluetoothManager.getBluetoothFileReceiver()?.checkMd5()){
              // todo Utils.toast("文件传输完成，要做特殊处理", getContext());
              let msg = new KeyValuePair(QTBluetoothManager.getBluetoothFileReceiver()?.getLocalPath(),
                QTBluetoothManager.getBluetoothFileReceiver()?.getFileType());

              EventManager.async(null,new DeviceEvent(DeviceEventType.ReceivedFile, Level.Common, msg));
              //文件完成，要做特殊处理
              QTBluetoothManager.setBluetoothFileReceiver(null)
            }
          }
        }
      }
    }catch (e) {
      let error = e as Error;
      Log.e(TAG,error.message);
    }
  }

  private static async maybeRequestNextFileBlock(): Promise<void> {
    // BluetoothFileReceiverSetting
    // BluetoothFileReceiver
    if(QTBluetoothManager.getBluetoothFileReceiverSetting() == null){
      QTBluetoothManager.setBluetoothFileReceiverSetting(BluetoothFileReceiverSetting.getInstance(getContext()))
      if(!TextUtils.isEmpty(await QTBluetoothManager.getBluetoothFileReceiverSetting()?.getRemotePath())){
        if(QTBluetoothManager.getBluetoothFileReceiver() == null &&
          ((await QTBluetoothManager.getBluetoothFileReceiverSetting()?.getRetryTime()!) < BluetoothFileReceiver.MaxRetryTime)){
          QTBluetoothManager.setBluetoothFileReceiver(new BluetoothFileReceiver(QTBluetoothManager.getBluetoothFileReceiverSetting()!))
        }
      }
    }

    if(QTBluetoothManager.getBluetoothFileReceiver() != null){
      if(!QTBluetoothManager.getBluetoothFileReceiver()?.isComplete()){
        let requestBegin: number = QTBluetoothManager.getBluetoothFileReceiver()?.getBeginAndWait()!
        if(requestBegin >= 0) {
          let requestFile: BTRequestFile = new BTRequestFile();
          requestFile.setFileName(QTBluetoothManager.getBluetoothFileReceiver()?.getRemotePath()!);
          requestFile.setBegin(requestBegin);
          requestFile.setRequestLength(BluetoothFileReceiver.BlockLength);
          QTBluetoothManager.setLastTransferFileTime(systemDateTime.getTime())
          QTBluetoothManager.write(BTProtocol.write(requestFile))
        }
      }
    }
  }
}