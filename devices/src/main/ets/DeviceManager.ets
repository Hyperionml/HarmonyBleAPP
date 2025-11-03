import { bluetooth  } from "@kit.ConnectivityKit";
import { socket } from '@kit.ConnectivityKit';
import { TextUtils } from "@ohos/fastble/Index";
import { BluetoothBatteryMonitor, IBluetoothBatteryCallback } from "./bluetooth/BluetoothBatteryMonitor";
import { BluetoothFileReceiver } from "./bluetooth/BluetoothFileReceiver";
import { BluetoothFileReceiverSetting } from "./bluetooth/BluetoothFileReceiverSetting";
import { BluetoothReader, IReadCallback } from "./bluetooth/BluetoothReader";
import { BluetoothWriter, IWriteCallback } from "./bluetooth/BluetoothWriter";
import { BTProtocol } from "./bluetooth/BTProtocol";
import { BTReport } from "./bluetooth/BTReport";
import { BTSection } from "./bluetooth/BTSection";
import { BTSectionType } from "./bluetooth/BTSectionType";
import { common } from '@kit.AbilityKit';
import { BTRequestFile } from "./model/BTRequestFile";
import { BusinessError, usb } from "@kit.BasicServicesKit";
import { EventManager, Level, Log,  Utils, FileUtils, KeyValuePair } from "common";
import { DeviceEventType } from "./DeviceEventType";
import { DeviceEvent } from "./DeviceEvent";
import { BTScanResult } from "./model/BTScanResult";
import { BuildConfig } from "./BuildConfig";
import { BTProtocolType } from "./bluetooth/BTProtocolType";
import { BTQCResult } from "./model/BTQCResult";
import { BTBattery } from "./model/BTBattery";
import { BTVersion } from "./model/BTVersion";
import { BTWaitForTransfer } from "./model/BTWaitForTransfer";
import { promptAction } from "@kit.ArkUI";
import { BTResponseFile } from "./model/BTResponseFile";
import { BTActionHelp } from "./bluetooth/BTActionHelp";
import { BTRequest } from "./model/BTRequest";
import { Utils as DUtils } from 'decoder';

const TAG = "DeviceManager";
/**
 * 蓝牙设备交互的管理：蓝牙的连接断开、协议解析、文件操作
 */
// 定义设备接口
export interface BluetoothDevice {
  deviceId: string;
  deviceName: string;
  address: string;
}
interface BluetoothConnectionInfo {
  name: string;
  address: string;
}
//USB设备接口
interface UsbDeviceInfo {
  deviceId: string;
  vendorId: number;
  productId: number;
  deviceName: string;
}

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
 * 蓝牙数据读取回调
 * 当BluetoothReader通过socket.on成功读取到蓝牙设备发送的字节流后就会调用这个方法
 */
class BluetoothReadCallback implements IReadCallback {
  async read(buff: Uint8Array): Promise<void> {
    console.log(TAG,"BluetoothReadCallback.read调用");
    Log.d(TAG, `读取到蓝牙数据，length: ${buff.length}`);
    if (!buff) return;

    try {
      const report: BTReport | null = BTProtocol.read(buff, 0, buff.length);
      if (!report || !report.getSection()) return;

      const sections: BTSection[] = report.getSection();
      if (sections.length === 0) return;

      const section: BTSection = sections[0];
      if (section.getSectionType() !== BTSectionType.Json) {
        Log.e(TAG, "不支持的协议类型");
        return;
      }

      const json: string | null = section.getJson();
      if (TextUtils.isEmpty(json)) return;
      //调用协议分发，将JSON数据分发到对应的业务逻辑
      await DeviceManager.dispatchProtocol(json!, section, buff, sections);

    } catch (error) {
      Log.e(TAG, `处理数据异常: ${(error as Error).message}`);
    }
    DeviceManager.handleFileReceiverLogic(); //触发文件处理
  }

  error(error: Error): void {
    console.log(TAG,"BluetoothReadCallback.error调用");
    Log.e(TAG, `读取错误: ${error.message}`);
    DeviceManager.disconnectDevice();
  }
}

/**
 * 蓝牙数据写入回调
 * 当BluetoothWriter通过socket.sppWrite成功将数据发送到蓝牙设备时就会调用这个方法
 */
class BluetoothWriteCallback implements IWriteCallback {
  finish(buff: Uint8Array): void {
    Log.d(TAG, `写流完成，length: ${buff.length}`);
  }
  error(err: Error): void {
    DeviceManager.disconnectDevice();
    Log.e(TAG, `数据写入错误: ${err.message}`);
  }
}


export class DeviceManager {

  public static readonly applicationUUID: string = "00001101-0000-1000-8000-00805F9B34FB";
  // 设备实例
  private static mDevice: BluetoothDevice | null = null;
  private static usbDevice: UsbDeviceInfo | null = null;

  private static clientNumber: number = -1;
  private static serverNumber: number = -1;
  private static isServerMode: boolean = false;
  private static readCallback: IReadCallback = new BluetoothReadCallback();
  private static writeCallback: IWriteCallback = new BluetoothWriteCallback();
  private static bluetoothReader: BluetoothReader | null = null;
  private static bluetoothWriter: BluetoothWriter | null = null;
  private static batteryMonitor: BluetoothBatteryMonitor | null = null;
  private static bluetoothSocketCache: Map<string, number> = new Map();
  private static isBatteryLow: boolean = false;
  private static batteryValue: number = 0;

  public static isTakePhoto: boolean = false;  //是否要拍照
  private static bluetoothFileReceiverSetting: BluetoothFileReceiverSetting | null = null;
  public static bluetoothFileReceiver: BluetoothFileReceiver | null = null;

  private static lastIsBatteryLow: boolean | null = null; // 记录上次低电量状态
  private static lastBatteryReceiveTime: number = 0; // 记录上次收到电量响应的时间

  private static lastTransferFileTime: number = 0;  //最近一次传输文件的时间
  private static bluetoothVersion: string | null = null;
  private static connectPromise: Promise<void> | null = null;
  private static connectedDevices = new Set<string>();
  private static bluetoothSocketMaps: Map<string, number> | null = null;

  private static _context: common.UIAbilityContext | null = null;
  private static isConnected: boolean = false; // 连接状态标志
  private static isConnecting: boolean = false;
  private static isWriting: boolean = false;
  static stateChangeListener: (state: number) => void;
  static currentBluetoothState: number;
  private static isUsbConnected: boolean = false;         // USB连接状态
  private static usbReadBufferSize: number = 4096;


  //初始化上下文
  public static init(context: common.UIAbilityContext): void {
    if (!context) { return;  }
    DeviceManager._context = context;

    // 确保EventManager已初始化
    try {
      EventManager.init();
      Log.d(TAG, "EventManager 初始化成功");
    } catch (error) {
      Log.e(TAG, `EventManager 初始化失败: ${error}`);
    }
  }

  public static getContext(): common.UIAbilityContext | null {
    return DeviceManager._context;
  }

  //  文件接收
  private static async handleFileReceive(content: Uint8Array, begin: number, length: number): Promise<number> {
    if (!DeviceManager.bluetoothFileReceiver) {
      return 100;
    }


    try {
      const success = await DeviceManager.bluetoothFileReceiver.receive(content, begin, length);
      console.log(TAG, `文件接收结果: ${success}`);

      if (success) {
        return DeviceManager.bluetoothFileReceiver.getProgress();
      } else {
        return 100;
      }
    } catch (error) {
      Log.e(TAG, `文件接收失败: ${(error as Error).message}`);
      return 100;
    }
  }

  //分发协议事件
  public static async dispatchProtocol(json: string, section: BTSection, buff: Uint8Array, sections: BTSection[]) {
    // 1. 扫描结果协议
    if (json.includes(BTProtocolType.ScanResult.getSymbol())) {
      // 调试日志：打印16进制数据
      if (BuildConfig.DEBUG) {
        let result = "";
        for (const b of buff) {
          let temp = b.toString(16).padStart(2, '0');
          result += `${temp.toUpperCase()}, `;
        }
        Log.d("ScanResult", result);
      }
      const fixedJson = DeviceManager.fixDeviceJson(json);
      Log.d("DeviceManager", `修正后的JSON: ${fixedJson}`);
      const scanResult: BTScanResult | null = Utils.jsonParse<BTScanResult>(fixedJson);
      if (!scanResult) {
        Log.e(TAG, "扫描结果解析为空");
        return;
      }
      EventManager.async(TAG, new DeviceEvent(
        DeviceEventType.BluetoothCode,
        Level.Common,
        scanResult
      ));
    }
    // 2. 质检结果协议
    else if (json.includes(BTProtocolType.QCResult.getSymbol())) {
      const fixedJson = DeviceManager.fixDeviceJson(json);
      const qcResult: BTQCResult | null = Utils.jsonParse<BTQCResult>(fixedJson);
      if (!qcResult) {
        Log.e(TAG, "质检结果解析为空");
        return;
      }
      EventManager.async(TAG, new DeviceEvent(
        DeviceEventType.BluetoothQC,
        Level.Common,
        qcResult
      ));
    }
    // 3. 电量信息协议
    else if (json.includes(BTProtocolType.BatteryResult.getSymbol())) {
      const fixedJson = DeviceManager.fixDeviceJson(json);
      const rawBatteryObj = Utils.jsonParse<TempBTBattery>(fixedJson);
      if (rawBatteryObj) {
        const batteryResult = new BTBattery();
        batteryResult.setBatteryPercent(rawBatteryObj.BatteryPercent);
        batteryResult.setBatteryLow(rawBatteryObj.IsBatteryLow);
        try {
          DeviceManager.lastBatteryReceiveTime = Date.now();
          const currentIsLow = batteryResult.IsBatteryLow();
          const historyIsLow = DeviceManager.lastIsBatteryLow;
          DeviceManager.batteryValue = batteryResult.getBatteryPercent();

          const isChangedToLow =
            (historyIsLow === null && currentIsLow) ||
              (historyIsLow !== null && !historyIsLow && currentIsLow);
          batteryResult.setChangedToLow(isChangedToLow);

          DeviceManager.batteryValue = batteryResult.getBatteryPercent();
          Log.d(TAG, `电池对象详情: ${JSON.stringify(batteryResult)}`);

          const batteryEvent = new DeviceEvent(
            DeviceEventType.BluetoothBattery,
            Level.Common,
            batteryResult
          );

          EventManager.async(TAG, batteryEvent);
          Log.d(TAG, "蓝牙电量事件已发送");
        } catch (error) {
          Log.e(TAG, `异常堆栈: ${error.stack}`);
        }
      } else {
        Log.e(TAG, "电量结果解析为空");
      }
    }
    // 4. 版本信息协议
    else if (json.includes(BTProtocolType.Version.getSymbol())) {
      const fixedJson = DeviceManager.fixDeviceJson(json);
      const rawVersionObj = Utils.jsonParse<TempBTVersion>(fixedJson);
      if (rawVersionObj) {
        const versionResult = new BTVersion();
        versionResult.setAppVersion(rawVersionObj.AppVersion); // 赋值App版本
        versionResult.setSysVersion(rawVersionObj.SysVersion); // 赋值系统版本
        const appVersion = versionResult.getAppVersion();

        EventManager.async(TAG, new DeviceEvent(
          DeviceEventType.BluetoothVersion,
          Level.Common,
          appVersion
        ));
        const newVersionPath = await DeviceManager.getNewVersion(appVersion);
        if (newVersionPath) {
          EventManager.async(null, new DeviceEvent(
            DeviceEventType.CheckBluetoothVersionEnd,
            Level.Common,
            appVersion
          ));
        } else {
          EventManager.async(null, new DeviceEvent(
            DeviceEventType.BluetoothCanUpdate,
            Level.Common,
            appVersion
          ));
        }
        DeviceManager.bluetoothVersion = appVersion;
      } else {
        Log.e(TAG, "版本信息解析为空");
      }
    }
    // 5. 文件传输等待协议
    else if (json.includes(BTProtocolType.WaitForTransfer.getSymbol())) {
      const fixedJson = DeviceManager.fixDeviceJson(json);
      const rawWaitObj = Utils.jsonParse<TempBTWaitForTransfer>(fixedJson);
      const context = DeviceManager.getContext();

      if (rawWaitObj && context) {
        console.log(TAG, "开始处理WaitForTransfer协议");

        const waitForTransfer = new BTWaitForTransfer();
        waitForTransfer.setFileName(rawWaitObj.FileName);
        waitForTransfer.setFileType(rawWaitObj.FileType);
        waitForTransfer.setMD5(rawWaitObj.MD5);
        waitForTransfer.setTotalLength(rawWaitObj.TotalLength);

        Log.d(TAG, `收到WaitForTransfer：FileType=${rawWaitObj.FileType}, FileName=${rawWaitObj.FileName}, MD5=${rawWaitObj.MD5}, TotalLength=${rawWaitObj.TotalLength}`);

        if (rawWaitObj.FileType === 'yuyv' && DeviceManager.isTakePhoto) {
          EventManager.async(null, new DeviceEvent(DeviceEventType.TakePhoto, Level.Common, null));
        }

        //如果有旧的未完成的文件，也放弃掉
        DeviceManager.bluetoothFileReceiver = null;
        DeviceManager.bluetoothFileReceiverSetting = null;

        try {
          const receiver = await BluetoothFileReceiver.createFromContext(
            context, // 直接用获取到的context，无需强制转换
            waitForTransfer.getFileName(),
            waitForTransfer.getFileType(),
            waitForTransfer.getMD5(),
            waitForTransfer.getTotalLength()
          );

          DeviceManager.bluetoothFileReceiver = receiver;
          DeviceManager.bluetoothFileReceiverSetting = BluetoothFileReceiverSetting.getInstance(context);
          console.log(TAG, "新的BluetoothFileReceiver创建成功");

        } catch (error) {
          Log.e(TAG, `文件接收器创建失败: ${(error as Error).message}`);
          DeviceManager.bluetoothFileReceiver = null;
        }
      }
    }
    // 6. 文件请求协议
    else if (json.includes(BTProtocolType.RequestFile.getSymbol())) {
      const fixedJson = DeviceManager.fixDeviceJson(json);
      const requestFile: BTRequestFile | null = Utils.jsonParse<BTRequestFile>(fixedJson);
      const responseFile = new BTResponseFile();
      if (!requestFile) {
        Log.e(TAG, "文件请求解析为空");
        return;
      }
      try {
        const block: Uint8Array | null = FileUtils.read(
          requestFile.getFileName(),
          requestFile.getBegin(),
          requestFile.getRequestLength()
        );

        if (block && block.length > 0) {
          responseFile.setBegin(requestFile.getBegin());
          responseFile.setFileName(requestFile.getFileName());
          responseFile.setResponseLength(block.length);

          DeviceManager.lastTransferFileTime = Date.now();
          const responseJson = Utils.stringify(responseFile);
          DeviceManager.write(BTProtocol.writeContent(responseJson, block));

          const fileTotalLength = FileUtils.getFileLength(requestFile.getFileName());
          let progress = 100;
          if (fileTotalLength > 0) {
            progress = ((block.length + requestFile.getBegin()) / fileTotalLength) * 100;
          } else {
            Log.w(TAG, "文件总长度异常，设为100%");
          }
          EventManager.async(null, new DeviceEvent(
            DeviceEventType.TransferProgress,
            Level.Common,
            progress
          ));
        } else {
          Log.e(TAG, "无法读取文件(蓝牙)：" + requestFile.getFileName());
          const context = DeviceManager.getContext();
          if (context) {
            promptAction.showToast({
              message: "文件读取失败",
              duration: 2000
            });
          }
        }
      } catch (error) {
        Log.e(TAG, "处理文件请求异常：" + (error as Error).message);
      }
    }
    // 7. 文件响应协议
    else if (json.includes(BTProtocolType.ResponseFile.getSymbol())) {
      const fixedJson = DeviceManager.fixDeviceJson(json);
      console.log(TAG, `ResponseFile JSON: ${fixedJson}`);

      const rawResponseObj = Utils.jsonParse<TempBTResponseFile>(fixedJson);
      if (rawResponseObj) {
        const responseFile = new BTResponseFile();
        responseFile.setFileName(rawResponseObj.FileName); // 赋值文件名
        responseFile.setBegin(rawResponseObj.Begin);       // 赋值起始位置
        responseFile.setResponseLength(rawResponseObj.ResponseLength); // 赋值响应长度

        if (sections.length > 1) {
          const contentSection: BTSection = sections[1];
          const content: Uint8Array = contentSection.getContent?.() || new Uint8Array(0);
          console.log(TAG, `数据块: Begin=${rawResponseObj.Begin}, 长度=${content.length}`);

          if (DeviceManager.bluetoothFileReceiver) {
            if (!DeviceManager.bluetoothFileReceiver.isComplete()) {
              const progress = await DeviceManager.handleFileReceive(
                content,
                responseFile.getBegin(),
                responseFile.getResponseLength()
              );
              EventManager.async(null, new DeviceEvent(
                DeviceEventType.TransferProgress,
                Level.Common,
                progress
              ));
            }
            if (DeviceManager.bluetoothFileReceiver.isComplete()) {
              DeviceManager.bluetoothFileReceiver.checkMd5().then((isValid: boolean) => {
                if (isValid) {
                  if (DeviceManager._context) {
                    promptAction.showToast({
                      message: "文件传输完成，要做特殊处理",
                      duration: 2000
                    });
                  }
                  if (DeviceManager.bluetoothFileReceiver) {
                    const msg: KeyValuePair<string, string> = new KeyValuePair(
                      DeviceManager.bluetoothFileReceiver.getLocalPath(),
                      DeviceManager.bluetoothFileReceiver.getFileType()
                    );
                    EventManager.async(null, new DeviceEvent(
                      DeviceEventType.ReceivedFile,
                      Level.Common,
                      msg
                    ));
                    DeviceManager.bluetoothFileReceiver = null;
                    // 重置拍照标志
                    DeviceManager.isTakePhoto = false;
                  } else {
                    Log.e(TAG, "bluetoothFileReceiver is null, cannot create KeyValuePair");
                  }
                }
              }).catch((error: Error) => {
                Log.e(TAG, `MD5校验异常: ${error.message}`);
              });
            }
          }
        }
      } else {
        Log.e(TAG, "文件响应信息解析为空");
      }
    }
  }

  //修复设备返回的非标准Json格式
  private static fixDeviceJson(rawJson: string): string {
    return rawJson
      .replace(/\bTRUE\b/g, 'true')
      .replace(/\bFALSE\b/g, 'false')
  }


  /**
   * 断点续传文件接收
   * 1.接收一个新的文件
   * 2.断点续传文件：从上次中断的位置开始
   */
   public static async handleFileReceiverLogic(): Promise<void> {
      if (DeviceManager.bluetoothFileReceiverSetting === null && DeviceManager._context) {
        DeviceManager.bluetoothFileReceiverSetting = BluetoothFileReceiverSetting.getInstance(DeviceManager._context);

        const remotePath = await DeviceManager.bluetoothFileReceiverSetting.getRemotePath();

        if (!TextUtils.isEmpty(remotePath)) {
          const retryTime = await DeviceManager.bluetoothFileReceiverSetting.getRetryTime();

          if (DeviceManager.bluetoothFileReceiver === null && retryTime < BluetoothFileReceiver.MaxRetryTime) {
            try {
              const receiver = await BluetoothFileReceiver.createFromSetting(DeviceManager.bluetoothFileReceiverSetting);
              DeviceManager.bluetoothFileReceiver = receiver;
              console.log(TAG, "断点续传接收器创建成功");
            } catch (error) {
              console.error(TAG, `断点续传接收器创建失败: ${error}`);
            }
          }
        }
      }
    if (DeviceManager.bluetoothFileReceiver != null) {
      const isComplete = DeviceManager.bluetoothFileReceiver.isComplete();
      console.log(TAG, `文件接收器完成状态: ${isComplete}`);

      if (!isComplete) {
        const requestBegin: number = DeviceManager.bluetoothFileReceiver.getBeginAndWait();
        console.log(TAG, `获取请求位置: ${requestBegin}`);

        if (requestBegin >= 0) {
          const requestFile = new BTRequestFile();
          const fileName = DeviceManager.bluetoothFileReceiver.getRemotePath();
          requestFile.setFileName(fileName);
          requestFile.setBegin(requestBegin);
          requestFile.setRequestLength(BluetoothFileReceiver.BlockLength);

          console.log(TAG, `准备发送RequestFile: FileName=${fileName}, Begin=${requestBegin}, Length=${BluetoothFileReceiver.BlockLength}`);

          const protocolData = BTProtocol.write(requestFile);
          console.log(TAG, `RequestFile协议数据长度: ${protocolData.length}`);

          DeviceManager.lastTransferFileTime = Date.now();
          const writeSuccess = DeviceManager.write(protocolData);
          console.log(TAG, `write方法返回值: ${writeSuccess}`);

          const requestJson = Utils.stringify(requestFile);
          console.log(TAG, `RequestFile完整JSON: ${requestJson}`);

          setTimeout(() => {
            if (DeviceManager.bluetoothFileReceiver &&
              !DeviceManager.bluetoothFileReceiver.isComplete() &&
              DeviceManager.bluetoothFileReceiver.getBeginAndWait() === requestBegin) {
              console.log(TAG, ` 请求超时，准备重试请求位置: ${requestBegin}`);
              DeviceManager.handleFileReceiverLogic(); // 触发文件处理
            }
          }, 5000);

        } else {
          console.log(TAG, "请求位置无效: " + requestBegin);
        }
      } else {
        console.log(TAG, "文件接收已完成，无需发送请求");
      }
    } else {
      console.log(TAG, "没有可用的bluetoothFileReceiver实例");
    }
  }


  //设置并连接指定蓝牙
  public static async setDevice(device: BluetoothDevice): Promise<void> {
    // 检查是否与当前设备相同
    if (DeviceManager.mDevice?.address === device.address) {
      return;
    }
    //状态初始化
    DeviceManager.mDevice = device;
    DeviceManager.isBatteryLow = false;
    DeviceManager.batteryValue = 0;

    // 发送连接开始事件
    EventManager.async(TAG, new DeviceEvent(
      DeviceEventType.BluetoothConnectionStarted,
      Level.Common,
      null
    ));

    try {
      // 调用connectBluetoothAsClient连接蓝牙设备
      const success = await DeviceManager.connectBluetoothAsClient(device);

      if (success) {
        // 创建连接信息对象
        const connectionInfo: BluetoothConnectionInfo = {
          name: device.deviceName,
          address: device.address
        };

        // 发送连接成功事件
        EventManager.async(TAG, new DeviceEvent(
          DeviceEventType.BluetoothConnectionSuccess,
          Level.Common,
          connectionInfo
        ));

        // 启动连接状态监控
        DeviceManager.startConnectionMonitor();
      }
    } catch (error) {
      if (!DeviceManager.isCancel) {
        // 发送连接失败事件
        EventManager.async(TAG, new DeviceEvent(
          DeviceEventType.BluetoothConnectionFailed,
          Level.Common,
          error
        ));
      }
    }
  }

  // 连接状态监控方法
  private static async startConnectionMonitor(): Promise<void> {
    while (DeviceManager.IsConnected() && !DeviceManager.isCancel) {
      await new Promise<void>(resolve => setTimeout(resolve, 200));
    }

    if (!DeviceManager.isCancel) {
      // 发送断开连接事件
      EventManager.async(TAG, new DeviceEvent(
        DeviceEventType.BluetoothDisconnected,
        Level.Common,
        null
      ));
    }
  }

  // 取消连接方法
  public static cancelConnection(): void {
    DeviceManager.isCancel = true;
    DeviceManager.disconnectDevice();
  }

  public static resetDevice(): void {
    DeviceManager.disconnectDevice();
    // 重置设备实例
    DeviceManager.mDevice = null;
    DeviceManager.mServerAddress = "";
    DeviceManager.mServerPort = -1;
    // // 清理USB设备
    // DeviceManager.usbDevice = null;
  }

  //蓝牙服务器端连接
  public static async startServer(context?: common.UIAbilityContext): Promise<boolean> {
    if (DeviceManager.isServerMode) {
      Log.w(TAG, '服务端已在运行，无需重复启动');
      return true;
    }

    const sppOption: socket.SppOptions = {
      uuid: DeviceManager.applicationUUID,
      secure: false,
      type: socket.SppType.SPP_RFCOMM
    };

    return new Promise<boolean>((resolve) => {
      socket.sppListen(
        'QTBluetoothServer',
        sppOption,
        (err: BusinessError, serverNum: number) => {
          if (err) {
            Log.e(TAG, `服务端监听失败: ${err.message}`);
            resolve(false);
            return;
          }
          DeviceManager.serverNumber = serverNum;
          DeviceManager.isServerMode = true;
          Log.d(TAG, `服务端启动成功，监听套接字: ${serverNum}`);
          DeviceManager.acceptClient();
          resolve(true);
        }
      );
    });
  }

  private static acceptClient(): void {
    if (!DeviceManager.isServerMode || DeviceManager.serverNumber === -1) return;

    socket.sppAccept(
      DeviceManager.serverNumber,
      (err: BusinessError, clientNum: number) => {
        if (err) {
          Log.w(TAG, `接受客户端失败，1秒后重试: ${err.message}`);
          setTimeout(DeviceManager.acceptClient.bind(DeviceManager), 1000);
          return;
        }
        DeviceManager.clientNumber = clientNum;
        DeviceManager.isConnected = true;
        Log.d(TAG, `客户端已连接，套接字: ${clientNum}`);

        DeviceManager.initReadWriter(clientNum);
      }
    );
  }

  // private static initReadWriter(socketNum: number): void {
  //   if (DeviceManager.bluetoothReader) DeviceManager.bluetoothReader.close();
  //   DeviceManager.bluetoothReader = new BluetoothReader(socketNum, DeviceManager.readCallback);
  //   DeviceManager.bluetoothReader.open();
  //
  //   if (DeviceManager.bluetoothWriter) DeviceManager.bluetoothWriter.close();
  //   DeviceManager.bluetoothWriter = new BluetoothWriter(socketNum,DeviceManager.writeCallback);
  //   DeviceManager.bluetoothWriter.open();
  // }

  private static initReadWriter(socketNum: number): void {
    if (DeviceManager.bluetoothReader) DeviceManager.bluetoothReader.close();
    DeviceManager.bluetoothReader = new BluetoothReader(socketNum, DeviceManager.readCallback);
    DeviceManager.bluetoothReader.open();

    if (DeviceManager.bluetoothWriter) DeviceManager.bluetoothWriter.close();
    DeviceManager.bluetoothWriter = new BluetoothWriter(socketNum, DeviceManager.writeCallback);
    DeviceManager.bluetoothWriter.open();
  }


  // 连接状态检查
  public static IsConnected(): boolean {
    return DeviceManager.isConnected && DeviceManager.clientNumber !== -1;
  }

  // //Socket缓存
  // private static getCacheBluetoothSocket(key: string): number {
  //   if (DeviceManager.bluetoothSocketMaps === null) {
  //     DeviceManager.bluetoothSocketMaps = new Map();
  //     return -1;
  //   }
  //   return DeviceManager.bluetoothSocketMaps.get(key) || -1;
  // }
  //
  // private static setCacheBluetoothSocket(key: string, clientNumber: number): boolean {
  //   if (DeviceManager.bluetoothSocketMaps === null) {
  //     DeviceManager.bluetoothSocketMaps = new Map();
  //   }
  //   const isNew = !DeviceManager.bluetoothSocketMaps.has(key);
  //   DeviceManager.bluetoothSocketMaps.set(key, clientNumber);
  //   return isNew;
  // }

  // 蓝牙客户端连接
  public static async connectBluetoothAsClient(device: BluetoothDevice): Promise<boolean> {
    console.log(TAG,`connectBluetoothAsClient called with device: ${JSON.stringify(device)}`);

    if (!device) {
      Log.e(TAG, "设备对象为空");
      return false;
    }

    if (!device.address) {
      Log.e(TAG, "设备地址为空");
      return false;
    }
    const deviceAddress = device.address; // 缓存key=设备地址
    DeviceManager.isConnected = false;

    if (DeviceManager.bluetoothReader) DeviceManager.bluetoothReader.close();
    if (DeviceManager.bluetoothWriter) DeviceManager.bluetoothWriter.close();

    // // 优先从缓存获取套接字
    // let clientSocket = DeviceManager.getCacheBluetoothSocket(deviceAddress);
    // if (clientSocket === -1) {
    //   const sppOption: socket.SppOptions = {
    //     uuid: DeviceManager.applicationUUID,
    //     secure: false,
    //     type: socket.SppType.SPP_RFCOMM
    //   };
    //   clientSocket = await new Promise<number>((resolve, reject) => {
    //     socket.sppConnect(deviceAddress, sppOption, (err: BusinessError, num: number) => {
    //       if (err) reject(err);
    //       else resolve(num);
    //     });
    //   });
    //   DeviceManager.setCacheBluetoothSocket(deviceAddress, clientSocket);
    // }

    //使用socket.sppConnect建立SPP连接
    try {
      const sppOption: socket.SppOptions = {
        uuid: DeviceManager.applicationUUID,  //服务UUID
        secure: false,  //是否加密连接
        type: socket.SppType.SPP_RFCOMM  //连接类型
      };

      console.log(TAG,`连接参数:`, sppOption);

      await new Promise<void>((resolve, reject) => {
        socket.sppConnect(device.address, sppOption, (err: BusinessError, clientSocket: number) => {
          if (err) {
            console.error(TAG,`连接失败: ${err.message}, 错误码: ${err.code}`);
            reject(err);
          } else {
            console.log(TAG,`连接成功，套接字: ${clientSocket}`);
            DeviceManager.clientNumber = clientSocket;
            resolve();
          }
        });
      });

      //初始化读写器
      DeviceManager.initReadWriter(DeviceManager.clientNumber);
      DeviceManager.mDevice = device;
      DeviceManager.isConnected = true;

      if (DeviceManager.batteryMonitor) {
        DeviceManager.batteryMonitor.stop(); // 停止旧的监测
        DeviceManager.batteryMonitor = null;
      }

      // 实现电量监测回调
      class BatteryCallback implements IBluetoothBatteryCallback {
        send(): void {
          //如果两分钟之内传输过文件就跳过电量请求
          if (DeviceManager.isTransferFile()) {
            Log.d(TAG, "文件传输中，暂不发送电量请求");
            return;
          }
          try {
            const request = BTActionHelp.makeRequestBatteryAction();//封装一个电量请求
            Log.d(TAG, "准备发送电量请求");
            //调用BluetoothWriter的write方法通过socket将字节流发送个设备
            const writeSuccess = DeviceManager.write(BTProtocol.write(request));
            Log.d(TAG, `电量请求发送结果: ${writeSuccess}`);
            if (!writeSuccess) {
              Log.e(TAG, "电量请求发送失败");
              DeviceManager.batteryMonitor?.stop();
            }
          } catch (error) {
            Log.e(TAG, `电量请求异常: ${(error as Error).message}`);
            DeviceManager.batteryMonitor?.stop();
          }
        }

        //监测是否收到响应
        checkReceive(currentTime: number): boolean {
          //return lastPingTime>time;
          return true;
        }

        //没有响应则离线处理
        offline(): void {
          Log.w(TAG, "电量监测超时");
          DeviceManager.batteryMonitor?.stop();
        }
      }

      // 启动电量监测
      DeviceManager.batteryMonitor = new BluetoothBatteryMonitor();
      DeviceManager.batteryMonitor.start(new BatteryCallback());

      Log.d(TAG, `设备连接成功: ${device.deviceName}`);
      return true;

    } catch (error) {
      Log.e(TAG, `客户端连接失败: ${(error as BusinessError).message}`);
      DeviceManager.disconnectDevice();
      return false;
    }
  }

  //监测两分钟内有没有文件传输过
  public static isTransferFile(): boolean {
    return Date.now() - DeviceManager.lastTransferFileTime < 2 * 60 * 1000;
  }


  // 断开连接
  public static disconnectDevice(): void {
    Log.i(TAG,'stopConnect');
    // 关闭读写器
    DeviceManager.bluetoothReader?.close();
    DeviceManager.bluetoothWriter?.close();
    DeviceManager.bluetoothReader = null;
    DeviceManager.bluetoothWriter = null;
    try {
      if (DeviceManager.clientNumber !== -1) {
        socket.sppCloseClientSocket(DeviceManager.clientNumber);
        Log.d(TAG, `已关闭客户端套接字 ${DeviceManager.clientNumber}`);
      }
    } catch (err) {
      Log.e(TAG, `errMessage: ${(err as BusinessError).message}`);
    }
    try {
      if (DeviceManager.isServerMode && DeviceManager.serverNumber !== -1) {
        socket.sppCloseServerSocket(DeviceManager.serverNumber);
        Log.d(TAG, `已关闭服务端监听套接字 ${DeviceManager.serverNumber}`);
      }
    } catch (err){
      Log.e(TAG, `errMessage: ${(err as BusinessError).message}`);
    }
    finally {
      DeviceManager.cleanupResources();
    }
  }

  // 清理资源
  private static cleanupResources(): void {
    DeviceManager.mDevice = null;
    DeviceManager.clientNumber = -1;
    DeviceManager.serverNumber = -1;
    DeviceManager.isConnected = false;
    DeviceManager.isServerMode = false;
    // 清理文件接收资源
    DeviceManager.bluetoothFileReceiverSetting = null;
    DeviceManager.bluetoothFileReceiver = null;
    // 重置拍照标志
    DeviceManager.isTakePhoto = false;
  }

  //蓝牙数据发送方法
  public static write(content: Uint8Array): boolean {
    if (DeviceManager.isWriting || !DeviceManager.IsConnected()) {
      return false;
    }
    DeviceManager.isWriting = true;  //避免重复调用write

    try {
      const arrayBuffer = content.buffer;  //将传入的Uint8Array转换为ArrayBuffer
      socket.sppWrite(DeviceManager.clientNumber, arrayBuffer);//通过socket.sppWrite向蓝牙设备发送数据
      return true;
    } catch (ex) {
      Log.e('DeviceManager', `write error: ${(ex as Error).message}`);
      return false;
    } finally {
      DeviceManager.isWriting = false;
    }
  }


  public static getDevice():  BluetoothDevice | null {
    return DeviceManager.mDevice;
  }

  private static mServerAddress: string = "";
  private static mServerPort: number = -1;
  private static typeDevice: string = "";
  private static watchdogEnabled: boolean = false;
  private static secureBluetoothMode: boolean = false;
  private static isCancel: boolean = false;



  //获取设备信息
  public static getDeviceModel(): string {
    let deviceName = "";
    const currentDevice = DeviceManager.getDevice();

    // 蓝牙设备处理
    if (currentDevice && typeof currentDevice === 'object') {
      const keys = Object.keys(currentDevice);
      for (const key of keys) {
        if (key === 'deviceName') {
          deviceName = currentDevice.deviceName || "";
          break;
        }
      }
    }
    // // TODO　USB设备处理
    // else if (DeviceManager.usbDevice) {
    //   deviceName = DeviceManager.usbDevice.deviceName || "";
    // }

    return deviceName;
  }

  public static getWatchdogEnabled(): boolean {
    return DeviceManager.watchdogEnabled;
  }


  public static setWatchdogEnabled(watchdogEnabled: boolean): void {
    DeviceManager.watchdogEnabled = watchdogEnabled;
  }

  //获取蓝牙安全模式状态
  public static getSecureBluetoothMode(): boolean {
    return DeviceManager.secureBluetoothMode;
  }

  //设置蓝牙安全模式状态
  public static setSecureBluetoothMode(secureBluetoothMode: boolean): void {
    DeviceManager.secureBluetoothMode = secureBluetoothMode;
  }

  // 检查是否正在连接
  public static IsConnecting(): boolean {
    return DeviceManager.mDevice !== null && !DeviceManager.IsConnected() && !DeviceManager.isCancel;
  }

  // 获取连接状态
  public static getConnectionState(): string {
    if (DeviceManager.IsConnected()) {
      return 'connected';
    } else if (DeviceManager.IsConnecting()) {
      return 'connecting';
    } else {
      return 'disconnected';
    }
  }

  //TODO　获取蓝牙适配器
  // private static getCachedClientNumber(address: string): number | null {
  //   return DeviceManager.bluetoothSocketCache.get(address) || null;
  // }
  //
  // private static cacheClientNumber(address: string, clientNumber: number): void {
  //   DeviceManager.bluetoothSocketCache.set(address, clientNumber);
  // }

  public static isIsTakePhoto(): boolean {
    return DeviceManager.isTakePhoto;
  }
  //拍照功能
  public static setIsTakePhoto(isTakePhoto: boolean) {
    if (DeviceManager.IsConnected()) {
      console.log("用户主动触发拍照，向设备发送拍照指令");
      let request = new BTRequest();
      request.setRequestType(BTRequest.TYPE_PHOTO);
      DeviceManager.write(BTProtocol.write(request)); // 仅此处发送拍照指令
      const writeSuccess = DeviceManager.write(BTProtocol.write(request));
      console.log(TAG, `拍照指令发送结果: ${writeSuccess}`);
      DeviceManager.isTakePhoto = false;
      return true;
    } else {
      DeviceManager.isTakePhoto = isTakePhoto;
      return false;
    }
  }

  // 获取最新版本升级文件方法
  private static async setBluetoothUpdate(): Promise<boolean> {
    //从特定目录找比版本新的固件文件
    const filePath: string | null = await DeviceManager.getNewVersion(DeviceManager.bluetoothVersion);
    if (!filePath || TextUtils.isEmpty(filePath)) {
      return false;
    }
    const request: BTWaitForTransfer = new BTWaitForTransfer();
    if (!filePath) {
      return false;
    }
    const fileType: string | null = FileUtils.getExtName(filePath);
    if (fileType === null) {
      return false;
    }
    try {
      const md5: string = DUtils.getMD5ofFile(filePath)!
      const fileLength: number = FileUtils.getFileLength(filePath as string);

      request.setFileName(filePath);
      request.setMD5(md5);
      request.setTotalLength(fileLength);
      request.setFileType(fileType);

      const writeSuccess: boolean = DeviceManager.write(BTProtocol.write(request));　　//发送升级指令
      if (writeSuccess) {
        return true;
      }
      return false;
    } catch (error) {
      return false;
    }
  }

  //版本检查
  private static async getNewVersion(oldVersion: string | null): Promise<string | null> {
    if (!oldVersion || oldVersion.trim() === "") {
      return null;
    }

    const fileType = ".zip";  //查找.zip格式的升级文件
    let dir: string | null;
    //调试模式使用下载目录，开发模式使用应用缓存目录
    if (BuildConfig.DEBUG) {
      dir = await FileUtils.getDownloadDir();
      if (!dir) {
        Log.e(TAG, "调试模式下，下载目录获取失败");
        return null;
      }
    } else {
      // 获取上下文
      const context = DeviceManager.getContext();
      if (!context) {
        Log.e(TAG, "上下文为空，无法获取应用缓存目录");
        return null;
      }
      dir = await FileUtils.getAppExternalDirectory(context, FileUtils.AppCacheDir);
      if (!dir) {
        Log.e(TAG, "正式模式下，应用缓存目录获取失败");
        return null;
      }
    }

    try {
      const files: string[] = await FileUtils.listFiles(dir) || [];
      if (files.length === 0) {
        return null;
      }

      let maxUpdateFile = -1;

      for (const fileName of files) {
        if (fileName.endsWith(fileType)) {
          const subName = fileName.substring(0, fileName.length - fileType.length);
          const versionNum = parseInt(subName, 10);

          if (!isNaN(versionNum) && versionNum > maxUpdateFile) {
            maxUpdateFile = versionNum;
          }
        }
      }

      const oldVersionNum = parseInt(oldVersion, 10);
      if (isNaN(oldVersionNum) || maxUpdateFile <= oldVersionNum) {
        return null;
      }

      const newFilePath = `${dir}/${maxUpdateFile}${fileType}`;
      const updateFilePath = `${dir}/update.zip`;  //将升级文件复制成update.zip

      // 使用文件句柄进行操作
      try {
        // 注意：在HarmonyOS中应该使用相应的文件API而不是Node.js的fs
        // 这里仍然使用FileUtils.copy来确保兼容性
        const copySuccess = FileUtils.copy(newFilePath, updateFilePath);
        if (!copySuccess) {
          return null;
        }
      } catch (error) {
        Log.e(TAG, `文件复制失败: ${(error as Error).message}`);
        return null;
      }

      return updateFilePath;

    } catch (error) {
      return null;
    }
  }

  //设备信息获取方法
  public static getServerAddress(): string {
    return DeviceManager.mServerAddress;
  }

  public static setServerAddress(address: string): void {
    DeviceManager.mServerAddress = address;
  }

  public static getServerPort(): number {
    return DeviceManager.mServerPort;
  }

  public static setServerPort(port: number): void {
    DeviceManager.mServerPort = port;
  }

  //电池状态获取
  public static getIsBatteryLow(): boolean {
    return DeviceManager.isBatteryLow;
  }

  public static getBatteryValue(): number {
    return DeviceManager.batteryValue;
  }


  //连接状态管理
  public static setNotConnected(): void {
    DeviceManager.isConnected = false;
  }

  //类型设备管理
  public static getTypeDevice(): string {
    return DeviceManager.typeDevice;
  }

  public static setTypeDevice(typeDevice: string): void {
    DeviceManager.typeDevice = typeDevice;
  }

}
