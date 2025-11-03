import ble from "@ohos.bluetooth.ble";
import { BluetoothBatteryMonitor, IBluetoothBatteryCallback } from "./bluetooth/BluetoothBatteryMonitor";
import { BluetoothFileReceiver } from "./bluetooth/BluetoothFileReceiver";
import { BluetoothFileReceiverSetting } from "./bluetooth/BluetoothFileReceiverSetting";
import { common } from "@kit.AbilityKit";
import { Utils } from "common/src/main/ets/Utils";
import { QTBleReader } from "./QTBleReader";
import { BleDevice, BleException, BleGattCallback, BleManager,
    BleNotifyCallback,
    BleScanRuleConfig,
    BleWriteCallback,
    TextUtils} from "@ohos/fastble";
import { EventManager, Level } from "common";
import { DeviceEvent } from "./DeviceEvent";
import { DeviceEventType } from "./DeviceEventType";
import { Log } from "common/src/main/ets/Log";
import { ArkTSUtils } from "@kit.ArkTS";
import { BTWaitForTransfer } from "./model/BTWaitForTransfer";
import { FileUtils } from "common/src/main/ets/file/FileUtils";
import { fileIo as fs } from '@kit.CoreFileKit';
import { BuildConfig } from "./BuildConfig";
import { deviceInfo, systemDateTime } from "@kit.BasicServicesKit";
import { BTProtocol } from "./bluetooth/BTProtocol";
import { BTActionHelp } from "./bluetooth/BTActionHelp";
import { BTReport } from "./bluetooth/BTReport";
import { BTSection } from "./bluetooth/BTSection";
import { BTSectionType } from "./bluetooth/BTSectionType";
import { BTProtocolType } from "./bluetooth/BTProtocolType";
import { BTScanResult } from "./model/BTScanResult";
import { BTQCResult } from './model/BTQCResult'
import { BTBattery } from "./model/BTBattery";
import { BTVersion } from "./model/BTVersion";
import { BTRequestFile } from "./model/BTRequestFile";
import { BTRequest } from "./model/BTRequest";
import { BTResponseFile } from "./model/BTResponseFile";
import { KeyValuePair } from 'common/src/main/ets/collection/KeyValuePair'
import { isSuccessTempFun } from "./common/TaskpoolUtils";
import parse from "@wolfx/json5/src/main/ets/json5/parse";
import { JSON5 } from "@wolfx/json5";
import { promptAction, PromptAction } from "@kit.ArkUI";
import { constant } from '@kit.ConnectivityKit';

interface TempBTBattery{
    IsBatteryLow: boolean
    BatteryPercent: number
}

interface TempBTWaitForTransfer {
    FileName: string
    FileType: string
    MD5: string
    TotalLength: number
}

interface TempBTResponseFile{
    FileName: string
    Begin: number
    ResponseLength: number
}

interface TempBTVersion {
    AppVersion: string
    SysVersion: string
}

/**
 * 连接回调实现
 */
class TempBleGattCallback extends BleGattCallback {

    public onStartConnect(): void {
    }

    // 连接失败时触发
    public onConnectFail(bleDevice: BleDevice, exception: BleException): void {
        if(!QTBle.getIsCancel()) {//如果不是人工取消的话
            EventManager.async(QTBle.TAG, new DeviceEvent(DeviceEventType.BluetoothDisconnected, Level.Common));
        }
    }

    // 连接成功时触发
    public async onConnectSuccess(bleDevice: BleDevice, gatt: ble.GattClientDevice, status: number) {
        await QTBle.onConnectSuccess(bleDevice,gatt,status);
    }


    public onDisConnected(isActiveDisConnected: boolean, device: BleDevice, gatt: ble.GattClientDevice,
        status: number): void {
        let bleDevice: BleDevice | null = null;
        if(QTBle.getDevice()!=null && QTBle.getDevice() instanceof BleDevice) {
            bleDevice = QTBle.getDevice() as BleDevice
        }
        if (bleDevice!=null && BleManager.getInstance().isConnected(bleDevice)) {
            BleManager.getInstance().disconnect(bleDevice);
        }
        if(!QTBle.getIsCancel()) {//如果不是人工取消的话
            EventManager.async(QTBle.TAG, new DeviceEvent(DeviceEventType.BluetoothDisconnected, Level.Common));
        }
    }

}

/**
 * 这是进行对蓝牙设备写操作的时候的回调函数
 */
class TempBleWriteCallback extends BleWriteCallback{
    public onWriteSuccess(current: number, total: number, justWrite: Uint8Array): void {
        Log.i("写流完成","testtag length:"+(justWrite!=null?justWrite.length:-1));
    }

    public onWriteFailure(exception: BleException): void {
        Log.e(QTBle.TAG, "testtag Bluetooth WriteFailed" + exception.getDescription());
    }
}

class IBluetoothBatteryCallbackImp implements IBluetoothBatteryCallback {

    send(): void {
        if(QTBle.isTransferFile()){
            return;
        }
        if(!QTBle.write(BTProtocol.write(BTActionHelp.makeRequestBatteryAction()))) {
            if(QTBle.getBatteryMonitor() != null) {
                QTBle.getBatteryMonitor().stop();
            }
        }
    }

    checkReceive(time: number): boolean {
        //return lastPingTime>time;
        return true;
    }

    offline(): void {
        if(QTBle.getBatteryMonitor()!=null) {
            QTBle.getBatteryMonitor().stop();
        }
    }

}

class TempBleNotifyCallback extends BleNotifyCallback {
    public onNotifySuccess(): void {
    }

    public onNotifyFailure(exception: BleException): void {
    }

    /**
     * 当手持扫描器扫到东西时会触发该方法
     * @param data
     * @returns
     */
    public async onCharacteristicChanged(data: Uint8Array): Promise<void> {
        {
            let buff: Uint8Array | null = null;
            if(QTBle.getBleReader() != null){
                buff = (await QTBle.getBleReader().mergeRead(data))!;
            }

            Log.i(QTBle.TAG,"读取到蓝牙数据 length:"+(buff!=null?buff.length:0));

            if(buff == null) {
                return
            }

            // 进入这一步才是真扫到码了，进行处理
            let report: BTReport = BTProtocol.read(buff, 0, buff.length) as BTReport
            if(report != null && report.getSection() != null){
                let sections: Array<BTSection> = report.getSection()
                if(sections != null && sections.length > 0){
                    let section: BTSection = sections[0];
                    if(section.getSectionType().getTypeValue() === BTSectionType.Json.getTypeValue()){
                        let json = section.getJson()
                        if(!TextUtils.isEmpty(json)){
                            try {
                                console.log(`testtag json: ${json}`)
                                // 扫描事件
                                if (json?.includes(BTProtocolType.ScanResult.getSymbol())) {
                                    if(BuildConfig.DEBUG){
                                        //let chars: string[]// = new string[buff.length*2];
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

                                    // 到这里是解析完扫描结果了
                                    let scanResult: BTScanResult = JSON5.parse<BTScanResult>(json.replace('TRUE', 'true'))
                                    EventManager.async(QTBle.TAG, new DeviceEvent(DeviceEventType.BluetoothCode, Level.Common, scanResult))

                                // 质检事件
                                } else if (json?.includes(BTProtocolType.QCResult.getSymbol())) {

                                    let qcResult: BTQCResult = JSON5.parse(json) as BTQCResult
                                    EventManager.async(QTBle.TAG, new DeviceEvent(DeviceEventType.BluetoothQC,Level.Common,qcResult))

                                // 电量事件
                                } else if (json?.includes(BTProtocolType.BatteryResult.getSymbol())) {
                                    let batteryResult: BTBattery = new BTBattery()

                                    let tempBatteryResult = JSON5.parse(json.replace('FALSE', 'false')) as TempBTBattery
                                    batteryResult.setBatteryPercent(tempBatteryResult.BatteryPercent)
                                    batteryResult.setBatteryLow(tempBatteryResult.IsBatteryLow)

                                    let isLowOld = QTBle.getIsBatteryLow()
                                    QTBle.setBatteryValue(batteryResult!.getBatteryPercent())
                                    //蓝牙电量变为低电量了
                                    if((isLowOld == null && batteryResult!.IsBatteryLow()) || isLowOld != null && !isLowOld && batteryResult!.IsBatteryLow()){
                                        batteryResult!.setChangedToLow(true);
                                    }
                                    QTBle.setIsBatteryLow(batteryResult!.IsBatteryLow())
                                    EventManager.async(QTBle.TAG, new DeviceEvent(DeviceEventType.BluetoothBattery,Level.Common,batteryResult!));

                                }
                                // 版本事件
                                else if(json?.includes(BTProtocolType.Version.getSymbol())){

                                    let versionResult = JSON5.parse(json) as TempBTVersion
                                    EventManager.async(QTBle.TAG, new DeviceEvent(DeviceEventType.BluetoothVersion, Level.Common, versionResult.AppVersion));
                                    let newVersionFile = await QTBle.getNewVersion(versionResult.AppVersion);
                                    QTBle.setBluetoothVersion(versionResult.AppVersion)

                                    if(!TextUtils.isEmpty(newVersionFile)){
                                        EventManager.async(null,new DeviceEvent(DeviceEventType.BluetoothCanUpdate,Level.Common,QTBle.getBluetoothVersion()));
                                    }
                                    else{
                                        //不需要升级；或旧的版本不支持升级
                                        EventManager.async(null,new DeviceEvent(DeviceEventType.CheckBluetoothVersionEnd,Level.Common,QTBle.getBluetoothVersion()));
                                    }

                                }
                                // 文件传输等待
                                else if(json?.includes(BTProtocolType.WaitForTransfer.getSymbol())) {

                                    let waitForTransfer: TempBTWaitForTransfer = JSON5.parse(json)
                                    console.log(`testtag waitForTransfer.FileType: ${waitForTransfer.FileType}`)
                                    if(waitForTransfer.FileType === 'yuyv'){
                                        EventManager.async(null, new DeviceEvent(DeviceEventType.TakePhoto, Level.Common, null))
                                    }

                                    //如果有旧的未完成的文件，也放弃掉
                                    QTBle.setBluetoothFileReceiverSetting(BluetoothFileReceiverSetting.getInstance(getContext()))
                                    QTBle.setBluetoothFileReceiver(
                                        await BluetoothFileReceiver.createFromContext(getContext() as common.UIAbilityContext,
                                            waitForTransfer.FileName,
                                            waitForTransfer.FileType,
                                            waitForTransfer.MD5,
                                            waitForTransfer.TotalLength
                                        )
                                    )

                                }
                                // 文件传输请求
                                else if(json?.includes(BTProtocolType.RequestFile.getSymbol())){
                                    Log.e(QTBle.TAG,"testtag 文件传输请求");

                                    let requestFile: BTRequestFile = JSON5.parse(json!) as BTRequestFile
                                    let responseFile: BTResponseFile = new BTResponseFile();
                                    let block = FileUtils.read(requestFile.getFileName(),requestFile.getBegin(),requestFile.getRequestLength())
                                    if(block != null && block.length>0) {
                                        responseFile.setBegin(requestFile.getBegin());
                                        responseFile.setFileName(requestFile.getFileName());
                                        responseFile.setResponseLength(block.length);
                                        QTBle.setLastTransferFileTime(systemDateTime.getTime())
                                        QTBle.write(BTProtocol.writeContent(JSON.stringify(responseFile),block));
                                        let fileTotalLength = FileUtils.getFileLength(requestFile.getFileName());
                                        let progress = 100.;
                                        if(fileTotalLength<=0){
                                            //文件异常了
                                            console.log(`testtag progress: ${progress}`)
                                            EventManager.async(null,new DeviceEvent(DeviceEventType.TransferProgress, Level.Common, progress));
                                        }
                                        else{
                                            progress = (block.length+requestFile.getBegin())*100.0/fileTotalLength;
                                            console.log(`testtag progress: ${progress}`)
                                            EventManager.async(null,new DeviceEvent(DeviceEventType.TransferProgress, Level.Common, progress));
                                        }
                                    }
                                    else{
                                        Log.e(QTBle.TAG,"testtag 无法读取文件(蓝牙)");

                                    }
                                    //todo 处理文件
                                }
                                // 文件传输响应
                                else if(json?.includes(BTProtocolType.ResponseFile.getSymbol())){
                                    let responseFile = JSON5.parse(json!) as TempBTResponseFile
                                    console.log(`testtag responseFile: ${JSON5.stringify(responseFile)}`)

                                    if(sections.length > 1){
                                        let contentSection = sections[1]

                                        console.log(`testtag getTotalLength: ${QTBle.getBluetoothFileReceiver()?.getTotalLength()}`)
                                        console.log(`testtag getCurrentLength: ${QTBle.getBluetoothFileReceiver()?.getCurrentLength()}`)
                                        console.log(`testtag QTBle.getBluetoothFileReceiver()?.isComplete(): ${QTBle.getBluetoothFileReceiver()?.isComplete()}`)

                                        if(QTBle.getBluetoothFileReceiver() != null && !QTBle.getBluetoothFileReceiver()?.isComplete()){
                                            if(QTBle.getBluetoothFileReceiver()?.receive(contentSection.getContent()!,responseFile.Begin,responseFile.ResponseLength)) {
                                                let progress = QTBle.getBluetoothFileReceiver()?.getProgress();
                                                console.log(`testtag 接收成功，进度: ${progress}%`);
                                                EventManager.async(null, new DeviceEvent(DeviceEventType.TransferProgress, Level.Common, progress));
                                            }
                                            else{
                                                EventManager.async(null, new DeviceEvent(DeviceEventType.TransferProgress, Level.Common, 100));
                                                //let context = getContext();
                                                Log.e(QTBle.TAG, "testtag 无法写入文件(蓝牙)");

                                            }
                                        }
                                        // 检查是否已完成传输
                                        if(QTBle.getBluetoothFileReceiver() !== null  && QTBle.getBluetoothFileReceiver()?.isComplete()){
                                            console.log(`testtag QTBle.getBluetoothFileReceiver()?.isComplete(): ${QTBle.getBluetoothFileReceiver()?.isComplete()}`)

                                            if(await QTBle.getBluetoothFileReceiver()?.checkMd5()){
                                                console.log(`testtag 文件传输完成，要做特殊处理`)
                                                if(deviceInfo.sdkApiVersion >= 18){
                                                    promptAction.openToast({message: "文件传输完成，要做特殊处理"})
                                                }

                                                let msg = new KeyValuePair(QTBle.getBluetoothFileReceiver()?.getLocalPath(),
                                                    QTBle.getBluetoothFileReceiver()?.getFileType());
                                                console.log(`testtag msg: ${JSON5.stringify(msg)}`)

                                                EventManager.async(null,new DeviceEvent(DeviceEventType.ReceivedFile, Level.Common, msg));
                                                //文件完成，要做特殊处理
                                                QTBle.setBluetoothFileReceiver(null)
                                            }
                                        }
                                    }
                                }
                            }
                            catch (ex)
                            {
                                Log.e(QTBle.TAG, 'testtag' + ex);
                            }
                        }
                    }
                    else{
                        throw new Error('UnsupportedOperationException')
                    }
                }
            }

            if(QTBle.getBluetoothFileReceiverSetting() == null){
                // 1. 初始化文件接收配置
                QTBle.setBluetoothFileReceiverSetting(BluetoothFileReceiverSetting.getInstance(getContext()))
                // 2. 检查配置中是否保存了一个未完成传输的远程文件路径
                if(!TextUtils.isEmpty(await QTBle.getBluetoothFileReceiverSetting()?.getRemotePath())){
                    // 3. 如果当前没有正在进行的接收任务，并且重试次数未超限
                    if(QTBle.getBluetoothFileReceiver() == null &&
                        ((await QTBle.getBluetoothFileReceiverSetting()?.getRetryTime()!) < BluetoothFileReceiver.MaxRetryTime)){
                        // 4. 创建一个新的文件接收器，准备继续接收
                        QTBle.setBluetoothFileReceiver(new BluetoothFileReceiver(QTBle.getBluetoothFileReceiverSetting()!))
                    }
                }
            }

            if(QTBle.getBluetoothFileReceiver() != null){
                // 1. 检查当前接收器是否已完成接收
                if(!QTBle.getBluetoothFileReceiver()?.isComplete()){
                    // 2. 获取下一个需要请求的数据块的起始位置
                    let requestBegin: number = QTBle.getBluetoothFileReceiver()?.getBeginAndWait()!
                    if(requestBegin >= 0) {
                        // 3. 构建一个"请求文件块"的协议数据包
                        let requestFile: BTRequestFile = new BTRequestFile();
                        requestFile.setFileName(QTBle.getBluetoothFileReceiver()?.getRemotePath()!);
                        requestFile.setBegin(requestBegin);// 请求的起始偏移量
                        requestFile.setRequestLength(BluetoothFileReceiver.BlockLength);// 请求的数据块长度
                        // 4. 更新最后传输文件时间，用于判断是否处于传输状态
                        QTBle.setLastTransferFileTime(systemDateTime.getTime())
                        // 5. 将请求包发送给蓝牙设备
                        QTBle.write(BTProtocol.write(requestFile))
                    }
                }
            }
        }
    }

}

export class Pair<F, S> {
    public first: F
    public second: S

    constructor(first: F, second: S) {
        this.first = first;
        this.second = second;
    }
}

export class QTBle {
    public static readonly TAG = 'QTBle'
    private static mDevice: object | null = null
    private static mDeviceGatt: ble.GattClientDevice | null

    private static isBatteryLow: boolean | null = false;
    private static batteryValue: number | null = null;

    private static isTakePhoto = false;//是否要拍照
    private static bluetoothFileReceiverSetting: BluetoothFileReceiverSetting | null = null
    private static bluetoothFileReceiver: BluetoothFileReceiver | null = null
    private static batteryMonitor: BluetoothBatteryMonitor

    private static lastTransferFileTime = 0;//最近一次传输文件的时间

    private static bluetoothVersion: string | null = null

    private static isCancel: boolean//手动停止的

    //private static _context: common.ApplicationContext
    private static serviceUUID = Utils.getUuidFrom16Bits('FF00')
    private static readUUID = Utils.getUuidFrom16Bits('FF01')
    private static writeUUID = Utils.getUuidFrom16Bits('FF02')

    private static bleReader: QTBleReader

    private static bleGattCallback: BleGattCallback = new TempBleGattCallback()

    private static bleWriteCallback: BleWriteCallback = new TempBleWriteCallback()

    /**
     * 初始化QTBle，安卓在BaseActvity的onCreate中调用，鸿蒙应该在EntryAbility的onCreate中调用
     * */
    public static init(){
        QTBle.bleReader = new QTBleReader();

        BleManager.getInstance().init();
        BleManager.getInstance()
            .enableLog(true)
            .setReConnectCount(1, 5000)
            .setConnectOverTime(10000)
            .setOperateTimeout(5000);

        let scanRuleConfig: BleScanRuleConfig = BleScanRuleConfig.Builder
            .setAutoConnect(false) //不确定具体效果，是否扫描发现时，自动连接？这是否会导致无法切换设备？
            .setScanTimeOut(10000)
            .build();
        BleManager.getInstance().initScanRule(scanRuleConfig);
    }

    /**
     * 这是QT设备的初始化方法
     * 该方法在进行与QT设备连接时触发，由界面将QT设备的BleDevice传入
     * @param device
     */
    public static setDevice(device: BleDevice){
        // 防止重复连接
        if(QTBle.mDevice === device){
            return;
        }

        QTBle.mDevice = device;
        QTBle.isCancel = false;
        QTBle.isBatteryLow = null;
        QTBle.batteryValue = null;
        QTBle.mDeviceGatt = null;

        if (QTBle.bleGattCallback == null) {
            throw new Error(`Assertion failed: bleGattCallback (${QTBle.bleGattCallback}) != null`)
        }
        if (!(QTBle.mDevice != null && QTBle.mDevice instanceof  BleDevice)) {
            throw new Error(`Assertion failed: mDevice (${QTBle.mDevice}) != null && mDevice (${QTBle.mDevice}) instanceof  BleDevice`)
        }

        // 发送蓝牙连接事件
        EventManager.async(QTBle.TAG,new DeviceEvent(DeviceEventType.BluetoothConnectionStarted, Level.Common));

        try {
            QTBle.bluetoothVersion = null;
            // 检查是否已连接
            if(BleManager.getInstance().isConnected(device)) {
                return;
            }
            let bleDevice = QTBle.mDevice as BleDevice

            ble.createGattClientDevice(bleDevice.getMac()).on('BLEConnectionStateChange', (newStatus: ble.BLEConnectionChangeState) => {
                if(newStatus.state === constant.ProfileConnectionState.STATE_DISCONNECTED){
                    EventManager.sync(QTBle.TAG, new DeviceEvent(DeviceEventType.BluetoothDisconnected, Level.Common))
                }
            })

            // 连接设备
            BleManager.getInstance().connect(bleDevice, QTBle.bleGattCallback)

            // todo 是否在这里，持久化虚拟设备地址 api16+才支持
            //access.addPersistentDeviceId(bleDevice.getMac());

            // 连接之后从BleManager中获取对应的GattClientDevice实例(可抛弃)
            // 关于这里给mDeviceGatt赋值的问题：追踪回调会发现在成功回调里也有一个给mDeviceGatt的赋值，我猜测两次赋值应该是一样的对象，只是多余操作了，在这里赋值只是复刻原本的操作
            // 此处赋值在追踪源码后发现也存在线程安全问题，回调中对mDeviceGatt才能保证线程安全，但没有保证同步性，但是可以在ui界面做等待操作来解决这个问题
            //QTBle.mDeviceGatt = BleManager.getInstance().getBleBluetooth(bleDevice)?.getBluetoothGatt()!
        } catch (e) {
            Log.e(QTBle.TAG, e);
            EventManager.async(QTBle.TAG, new DeviceEvent(DeviceEventType.BluetoothConnectionFailed, Level.Common, e));
        }
    }

    /**
     * 断连
     */
    public static disconnectDevice() {
        QTBle.isCancel = true;
        if(QTBle.mDevice!=null && QTBle.mDevice instanceof  BleDevice) {
            // 让BleManager断连指定设备
            BleManager.getInstance().disconnect(QTBle.mDevice as BleDevice);
        }
        if(QTBle.batteryMonitor!=null) {
            // 停止电池监控
            QTBle.batteryMonitor.stop();
        }

        // 初始化
        QTBle.batteryValue = null;
        QTBle.isBatteryLow = null;
        QTBle.mDevice = null;
    }

    /**
     * 向蓝牙设备写数据
     * @param content 需要发送的数据
     * @returns 是否发送成功
     */
    public static async write(content: Uint8Array){
        let lock: ArkTSUtils.locks.AsyncLock = ArkTSUtils.locks.AsyncLock.request("QTBle.write")
        return lock.lockAsync((): boolean => {
            if(QTBle.mDevice!=null && QTBle.mDevice instanceof  BleDevice && QTBle.mDeviceGatt!=null) {
                let bleDevice = QTBle.mDevice as BleDevice
                let characteristic = QTBle.getCharacteristic2(QTBle.mDeviceGatt, QTBle.serviceUUID, QTBle.writeUUID);
                if(characteristic!=null){
                    try {
                        // 在底层操作BleManager进行写操作
                        BleManager.getInstance().write(
                            bleDevice,
                            QTBle.serviceUUID.toString(),
                            QTBle.writeUUID.toString(),
                            content,true,true,0,
                            // 回调里面只有日志输出
                            QTBle.bleWriteCallback);
                    }
                    catch (ex){
                        Log.e(QTBle.TAG, 'testtag' + ex);
                        return false;
                    }
                    return true;
                }

            }
            return false
        })
    }

    /**
     * 用于检查是否处于连接状态
     * @returns 连接状态
     */
    public static isConnected(){
        if(QTBle.mDevice === null) return false;

        if(!(QTBle.mDevice instanceof BleDevice)){
            throw new Error('QTBle.mDevice not instanceof BleDevice')
        }
        // 向下查询
        // todo 目前我发现该接口的底层是connection.getPairedDevices，其中返回的mac列表是虚拟的，和连接是扫描到的mac地址存在偏差，所以无法使用
        let isConnect = BleManager.getInstance().isConnected(QTBle.mDevice as BleDevice);
        // console.log(`testtag mac: ${(QTBle.mDevice as BleDevice).mDeviceId}`)
        // console.log(`testtag isConnect: ${isConnect}`)
        return true
    }

    /**
     * 拍照模式修改的接口（没找到相关位置，可能是硬件的功能）
     * @param isTakePhoto
     * @returns
     */
    public static setIsTakePhoto(isTakePhoto: boolean) {
        console.log(`testtag QTBle.isConnected(): ${QTBle.isConnected()}`)
        if(QTBle.isConnected()){
            console.log('testtag 进入拍照逻辑')
            let request = new BTRequest();
            request.setRequestType(BTRequest.TYPE_PHOTO);
            QTBle.write(BTProtocol.write(request));//请求拍照
            return true;
        }
        else {
            QTBle.isTakePhoto = isTakePhoto;
            return false;
        }
    }

    /**
     * 似乎是给设备升级的接口
     * @returns
     */
    public static async setBluetoothUpdate(){
        let filePath = await QTBle.getNewVersion(QTBle.bluetoothVersion!)
        let request = new BTWaitForTransfer()
        if(TextUtils.isEmpty(filePath!)){
            return false;
        }
        let fileType = FileUtils.getExtName(filePath!)

        let md5 = ''//com.baoshen.decoder.Utils.getMD5ofFile(filePath)
        request.setFileName(filePath!)
        request.setMD5(md5)
        request.setTotalLength(fs.statSync(filePath).size)
        request.setFileType(fileType!)
        QTBle.write(BTProtocol.write(request))//请求拍照
        return true;
    }

    /**
     * 获取新版本
     * @param oldVersion
     * @returns
     */
    public static async getNewVersion(oldVersion: string){
        if (TextUtils.isEmpty(oldVersion)) {
            return null;
        }
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
     * 连接成功时的回调函数体
     * @param bleDevice
     * @param gatt
     * @param status
     */
    public static async onConnectSuccess(bleDevice: BleDevice, gatt: ble.GattClientDevice, status: number) {
        let service: ble.GattService | null = null;
        let isConnectSuccess = false;
        // if(gatt != null){
        //     (await gatt.getServices()).forEach((value) => {
        //         if(value.serviceUuid === QTBle.serviceUUID){
        //             service = value
        //         }
        //     })
        // }
        // let readCharacteristic: ble.BLECharacteristic | null = null;
        // if(service!=null) {
        //     readCharacteristic = QTBle.getCharacteristic(service, QTBle.readUUID);
        //
        // }

        BleManager.getInstance().getBluetoothGattServices(bleDevice, (err, services: ble.GattService[]) => {
            services.forEach((value) => {
                let serviceUUID = QTBle.serviceUUID
                if(value.serviceUuid === serviceUUID){
                    service = value
                    let readUUID = QTBle.readUUID
                        let readCharacteristic = QTBle.getCharacteristic(service, readUUID)

                    if(readCharacteristic !== null){
                        // 关于在异步的回调函数里对mDeviceGatt的赋值，由于fastble里对于异步回调的触发是没有await的所以我怀疑这部分会有线程安全问题
                        QTBle.mDeviceGatt = gatt;

                        if(QTBle.batteryMonitor!=null){
                            // 关闭老的监控
                            QTBle.batteryMonitor.stop();
                        }
                        QTBle.batteryMonitor = new BluetoothBatteryMonitor();
                        // 开启电量监控
                        QTBle.batteryMonitor.start(new IBluetoothBatteryCallbackImp())

                        // 开启特征值监控
                        BleManager.getInstance().notify(bleDevice, QTBle.serviceUUID, QTBle.readUUID, false, new TempBleNotifyCallback())

                        isConnectSuccess = true
                    }
                }
            })
        })

        if(isConnectSuccess){
            // 这里由于鸿蒙的书写规范要求，该函数体定义在了外部，内容是延迟将连接时间发送给设备
            //taskpool.execute(isSuccessTempFun)
            setTimeout(() => {
                isSuccessTempFun()
            })
            let bluetoothDevice = bleDevice
            // 发送连接成功事件
            EventManager.async(QTBle.TAG, new DeviceEvent(DeviceEventType.BluetoothConnectionSuccess, Level.Common,
                new Pair<string, string>(bleDevice.getName(),bluetoothDevice.getMac())));
        }
    }

    /**
     * 从GattService获取指定characteristicUUID的特征值数据体
     * @param service
     * @param characteristicUUID
     * @returns
     */
    private static getCharacteristic(service: ble.GattService , characteristicUUID: string){
        if(service != null){
            let characteristics: Array<ble.BLECharacteristic> =  service.characteristics
            if(characteristics != null && characteristics.length > 0){
                for (let characteristic of characteristics) {
                    if(characteristic.characteristicUuid === characteristicUUID){
                        return characteristic;
                    }
                }
            }
        }
        return null
    }

    /**
     * 从GattClientDevice中用serviceUUID和characteristicUUID获取指定特征值数据体
     * @param gatt GattClientDevice实例
     * @param serviceUUID
     * @param characteristicUUID
     * @returns
     */
    private static async getCharacteristic2(gatt: ble.GattClientDevice, serviceUUID: string, characteristicUUID: string): Promise<ble.BLECharacteristic | null> {
        if(gatt == null){
            return null;
        }
        let services = await gatt.getServices()
        let service: ble.GattService | null = null
        services.forEach((value) => {
            if(value.serviceUuid == serviceUUID){
                service = value
            }
        })
        if(service != null) {
            return QTBle.getCharacteristic(service, characteristicUUID);
        }
        return null
    }

    /********* getter & setter ********************/

    public static isTransferFile(){
        return systemDateTime.getTime() - QTBle.lastTransferFileTime < 2 * 60 * 1000;//最近2分钟有没在传文件
    }

    public static getIsBatteryLow() {
        return QTBle.isBatteryLow;
    }

    public static getBatteryValue() {
        return QTBle.batteryValue;
    }

    public static isSupportBle() {
        return BleManager.getInstance().isSupportBle() && BleManager.getInstance().isBlueEnable();
    }

    public static getDevice(){
        return QTBle.mDevice
    }

    public static setBluetoothFileReceiver(bluetoothFileReceiver: BluetoothFileReceiver | null){
        QTBle.bluetoothFileReceiver = bluetoothFileReceiver
    }

    public static getBluetoothFileReceiverSetting(){
        return QTBle.bluetoothFileReceiverSetting
    }

    public static setLastTransferFileTime(lastTransferFileTime: number){
        QTBle.lastTransferFileTime = lastTransferFileTime
    }

    public static getBluetoothFileReceiver(){
        return QTBle.bluetoothFileReceiver
    }

    public static setBluetoothFileReceiverSetting(bluetoothFileReceiverSetting: BluetoothFileReceiverSetting){
        QTBle.bluetoothFileReceiverSetting = bluetoothFileReceiverSetting
    }

    public static getBluetoothVersion(){
        return QTBle.bluetoothVersion
    }

    public static setBluetoothVersion(bluetoothVersion: string){
        QTBle.bluetoothVersion = bluetoothVersion
    }

    public static setIsBatteryLow(isBatteryLow: boolean){
        QTBle.isBatteryLow = isBatteryLow
    }

    public static setBatteryValue(batteryValue: number){
        QTBle.batteryValue = batteryValue
    }

    public static getBleReader(){
        return QTBle.bleReader
    }

    public static getBatteryMonitor() {
        return QTBle.batteryMonitor
    }

    public static getIsCancel() {
        return QTBle.isCancel
    }

    public static isIsTakePhoto() {
        return QTBle.isTakePhoto;
    }

}


