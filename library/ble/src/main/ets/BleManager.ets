/*
 * Copyright (c) 2021 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
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

import BleBluetooth from './bluetooth/BleBluetooth';
import MultipleBluetoothController from './bluetooth/MultipleBluetoothController';
import SplitWriter from './bluetooth/SplitWriter';
import BleGattCallback from './callback/BleGattCallback'
import BleIndicateCallback from './callback/BleIndicateCallback';
import BleMtuChangedCallback from './callback/BleMtuChangedCallback'
import BleNotifyCallback from './callback/BleNotifyCallback'
import BleReadCallback from './callback/BleReadCallback';
import BleRssiCallback from './callback/BleRssiCallback'
import BleScanAndConnectCallback from './callback/BleScanAndConnectCallback'
import BleScanCallback from './callback/BleScanCallback';
import BleWriteCallback from './callback/BleWriteCallback';
import BleDevice from './data/BleDevice';
import BleScanState from './data/BleScanState';
import ConnectException from './exception/ConnectException'
import OtherException from './exception/OtherException'
import BleScanRuleConfig from './scan/BleScanRuleConfig'
import BleScanner from './scan/BleScanner';
import BleLog from './utils/BleLog'
import MockBluetooth from './bluetooth/MockBluetooth'
import { AsyncCallback, Callback } from '@ohos.base';
import ble from '@ohos.bluetooth.ble';
import access from '@ohos.bluetooth.access';
import connection from '@ohos.bluetooth.connection';

type UUID = string;
type byte = number;

export default class BleManager {
  public static readonly MOCK_DEVICE: boolean = false;
  public static readonly mockBluetooth: MockBluetooth = new MockBluetooth();
  private bleScanRuleConfig: BleScanRuleConfig = BleScanRuleConfig.Builder.build();
  // 这个对象用来存储已经连接的所有BleBluetooth对象，用id作为key，方便在使用时获取
  private multipleBluetoothController: MultipleBluetoothController | null = null;
  public static readonly DEFAULT_SCAN_TIME = 10000;
  private static readonly DEFAULT_MAX_MULTIPLE_DEVICE = 7;
  private static readonly DEFAULT_OPERATE_TIME = 5000;
  private static readonly DEFAULT_CONNECT_RETRY_COUNT = 0;
  private static readonly DEFAULT_CONNECT_RETRY_INTERVAL = 5000;
  private static readonly DEFAULT_MTU = 23;
  private static readonly DEFAULT_MAX_MTU = 512;
  private static readonly DEFAULT_WRITE_DATA_SPLIT_COUNT = 20;
  private static readonly DEFAULT_CONNECT_OVER_TIME = 10000;
  private maxConnectCount = BleManager.DEFAULT_MAX_MULTIPLE_DEVICE;
  private operateTimeout = BleManager.DEFAULT_OPERATE_TIME;
  private reConnectCount = BleManager.DEFAULT_CONNECT_RETRY_COUNT;
  private reConnectInterval = BleManager.DEFAULT_CONNECT_RETRY_INTERVAL;
  private splitWriteNum = BleManager.DEFAULT_WRITE_DATA_SPLIT_COUNT;
  private connectOverTime = BleManager.DEFAULT_CONNECT_OVER_TIME;
  private static instance: BleManager = new BleManager();

  private constructor() {
  }

  public static getInstance(): BleManager {
    return BleManager.instance
  }

  public init(): void {
    this.multipleBluetoothController = new MultipleBluetoothController();
    this.bleScanRuleConfig = new BleScanRuleConfig();
  }

  /**
   * get the ScanRuleConfig
   *
   * @return
   */
  public getScanRuleConfig(): BleScanRuleConfig {
    return this.bleScanRuleConfig;
  }

  /**
   * Get the multiple Bluetooth Controller
   *
   * @return
   */
  public getMultipleBluetoothController(): MultipleBluetoothController | null {
    return this.multipleBluetoothController;
  }

  /**
   * Configure scan and connection properties
   *
   * @param config
   */
  public initScanRule(config: BleScanRuleConfig) {
    this.bleScanRuleConfig = config;
  }

  /**
   * Get the maximum number of connections
   *
   * @return
   */
  public getMaxConnectCount(): number {
    return this.maxConnectCount;
  }

  /**
   * Set the maximum number of connections
   *
   * @param count
   * @return BleManager
   */
  public setMaxConnectCount(count: number): BleManager {
    if (count > BleManager.DEFAULT_MAX_MULTIPLE_DEVICE)
      count = BleManager.DEFAULT_MAX_MULTIPLE_DEVICE;
    this.maxConnectCount = count;
    return this;
  }

  /**
   * Get operate timeout
   *
   * @return
   */
  public getOperateTimeout(): number {
    return this.operateTimeout;
  }

  /**
   * Set operate timeout
   *
   * @param count
   * @return BleManager
   */
  public setOperateTimeout(count: number): BleManager {
    this.operateTimeout = count;
    return this;
  }

  /**
   * Get connect retry count
   *
   * @return
   */
  public getReConnectCount(): number {
    return this.reConnectCount;
  }

  /**
   * Get connect retry interval
   *
   * @return
   */
  public getReConnectInterval(): number {
    return this.reConnectInterval;
  }

  /**
   * Set connect retry count and interval
   *
   * @param count
   * @return BleManager
   */
  public setReConnectCount(count: number, interval: number = BleManager.DEFAULT_CONNECT_RETRY_INTERVAL): BleManager {
    if (count > 10)
      count = 10;
    if (interval < 0)
      interval = 0;
    this.reConnectCount = count;
    this.reConnectInterval = interval;
    return this;
  }


  /**
   * Get operate split Write Num
   *
   * @return
   */
  public getSplitWriteNum(): number {
    return this.splitWriteNum;
  }

  /**
   * Set split Writ eNum
   *
   * @param num
   * @return BleManager
   */
  public setSplitWriteNum(num: number): BleManager {
    if (num > 0) {
      this.splitWriteNum = num;
    }
    return this;
  }

  /**
   * Get operate connect Over Time
   *
   * @return
   */
  public getConnectOverTime(): number {
    return this.connectOverTime;
  }

  /**
   * Set connect Over Time
   *
   * @param time
   * @return BleManager
   */
  public setConnectOverTime(time: number): BleManager {
    if (time <= 0) {
      time = 100;
    }
    this.connectOverTime = time;
    return this;
  }

  /**
   * print log?
   *
   * @param enable
   * @return BleManager
   */
  public enableLog(enable: boolean): BleManager {
    BleLog.isPrint = enable;
    return this;
  }


  /**
   * 扫描周围BLE设备
   * 这是进入蓝牙界面时开始扫描周围蓝牙设备的入口
   * @param callback 扫描结果的回调
   */
  public scan(callback: BleScanCallback) {
    if (callback == null) {
      throw new Error("BleScanCallback can not be Null!");
    }

    if (!this.isBlueEnable()) {
      BleLog.e("Bluetooth not enable!");
      callback.onScanStarted(false);
      return;
    }

    let serviceUuids: UUID[] = this.bleScanRuleConfig.getServiceUuids();
    let deviceNames: string[] = this.bleScanRuleConfig.getDeviceNames();
    let deviceMac: string = this.bleScanRuleConfig.getDeviceMac();
    let fuzzy: boolean = this.bleScanRuleConfig.isFuzzy();
    let timeOut: number = this.bleScanRuleConfig.getScanTimeOut();

    //这里进入扫描器的内部方法
    BleScanner.getInstance().scan(serviceUuids, deviceNames, deviceMac, fuzzy, timeOut, callback);
  }

  /**
   * scan device then connect
   *
   * @param callback
   */
  public scanAndConnect(callback: BleScanAndConnectCallback) {
    if (callback == null) {
      throw new Error("BleScanAndConnectCallback can not be Null!");
    }

    if (!this.isBlueEnable()) {
      BleLog.e("Bluetooth not enable!");
      callback.onScanStarted(false);
      return;
    }

    let serviceUuids: UUID[] = this.bleScanRuleConfig.getServiceUuids();
    let deviceNames: string[] = this.bleScanRuleConfig.getDeviceNames();
    let deviceMac: string = this.bleScanRuleConfig.getDeviceMac();
    let fuzzy: boolean = this.bleScanRuleConfig.isFuzzy();
    let timeOut: number = this.bleScanRuleConfig.getScanTimeOut();

    BleScanner.getInstance().scanAndConnect(serviceUuids, deviceNames, deviceMac, fuzzy, timeOut, callback);
  }

  /**
   * 连接BLE设备：通过MAC地址连接设备，无需先扫描
   * 连接完成后不会直接返回连接实例，而是将可操作对象保存在bleBluetooth类中
   * @param device BleDevice对象或MAC地址字符串
   * @param bleGattCallback 连接状态回调
   */
  public connect(device: BleDevice | string, bleGattCallback: BleGattCallback): void {
    let bleDevice: BleDevice;
    if (device instanceof BleDevice) {
      bleDevice = device;
    } else {
      bleDevice = new BleDevice(device, '', 0, undefined, 0);  //从MAC地址创建Ble设备对象
    }
    console.info("BleManager.connect device:" + bleDevice.getMac());
    if (bleGattCallback == null) {
      throw new EvalError("BleGattCallback can not be Null!");
    }

    if (!this.isBlueEnable()) {
      BleLog.e("Bluetooth not enable!");
      bleGattCallback.onConnectFail(bleDevice, new OtherException("Bluetooth not enable!"));
      return;
    }

    if (bleDevice == null) {
      bleGattCallback.onConnectFail(bleDevice, new OtherException("Not Found Device Exception Occurred!"));
    } else {
      if (this.multipleBluetoothController !== null) {
        let bleBluetooth: BleBluetooth = this.multipleBluetoothController.buildConnectingBle(bleDevice);
        let autoConnect: boolean = this.bleScanRuleConfig.isAutoConnect();
        // 连接，连接虽然会返回可操作的GattClientDevice对象，但此处并不接受，对象存储在bleBluetooth中
        bleBluetooth.connect(bleDevice, autoConnect, bleGattCallback);
      }
    }
  }


  /**
   * Cancel scan
   */
  public cancelScan() {
    BleScanner.getInstance().stopLeScan();
  }

  /**
   * 启用通知模式：订阅设备的数据推送
   * 应用必须先调用此方法才能接收设备的响应数据
   */
  public notify(bleDevice: BleDevice, uuid_service: string, uuid_notify: string, useCharacteristicDescriptor: boolean = false, callback: BleNotifyCallback) {
    if (callback == null) {
      throw new Error("BleNotifyCallback can not be Null!");
    }
    if (this.multipleBluetoothController !== null) {
      let bleBluetooth: BleBluetooth | null = this.multipleBluetoothController.getBleBluetooth(bleDevice);
      if (bleBluetooth == null) {
        callback.onNotifyFailure(new OtherException("This device not connect!"));
      } else {
        bleBluetooth.newBleConnector()
          .withUUIDString(uuid_service, uuid_notify)
          .enableCharacteristicNotify(callback, uuid_notify, useCharacteristicDescriptor);
      }
    }
  }

  /**
   * indicate
   *
   * @param bleDevice
   * @param uuid_service
   * @param uuid_indicate
   * @param useCharacteristicDescriptor
   * @param callback
   */
  public indicate(bleDevice: BleDevice, uuid_service: string, uuid_indicate: string, useCharacteristicDescriptor: boolean = false, callback: BleIndicateCallback) {
    if (callback == null) {
      throw new EvalError("BleIndicateCallback can not be Null!");
    }
    if (this.multipleBluetoothController !== null) {
      let bleBluetooth: BleBluetooth | null = this.multipleBluetoothController.getBleBluetooth(bleDevice);
      if (bleBluetooth == null) {
        callback.onIndicateFailure(new OtherException("This device not connect!"));
      } else {
        bleBluetooth.newBleConnector()
          .withUUIDString(uuid_service, uuid_indicate)
          .enableCharacteristicIndicate(callback, uuid_indicate, useCharacteristicDescriptor);
      }
    }
  }

  /**
   * stop notify, remove callback
   *
   * @param bleDevice
   * @param uuid_service
   * @param uuid_notify
   * @param useCharacteristicDescriptor
   * @return
   */
  public stopNotify(bleDevice: BleDevice, uuid_service: string, uuid_notify: string, useCharacteristicDescriptor: boolean = false): boolean {
    if (this.multipleBluetoothController === null) {
      return false
    }

    let bleBluetooth: BleBluetooth | null = this.multipleBluetoothController.getBleBluetooth(bleDevice);
    if (bleBluetooth == null) {
      return false;
    }
    let success: boolean = bleBluetooth.newBleConnector()
      .withUUIDString(uuid_service, uuid_notify)
      .disableCharacteristicNotify(useCharacteristicDescriptor);
    if (success) {
      bleBluetooth.removeNotifyCallback(uuid_notify);
    }
    return success;
  }

  /**
   * stop indicate, remove callback
   *
   * @param bleDevice
   * @param uuid_service
   * @param uuid_indicate
   * @param useCharacteristicDescriptor
   * @return
   */
  public stopIndicate(bleDevice: BleDevice, uuid_service: string, uuid_indicate: string, useCharacteristicDescriptor: boolean = false): boolean {
    if (this.multipleBluetoothController === null) {
      return false
    }

    let bleBluetooth: BleBluetooth | null = this.multipleBluetoothController.getBleBluetooth(bleDevice);
    if (bleBluetooth == null) {
      return false;
    }
    let success: boolean = bleBluetooth.newBleConnector()
      .withUUIDString(uuid_service, uuid_indicate)
      .disableCharacteristicIndicate(useCharacteristicDescriptor);
    if (success) {
      bleBluetooth.removeIndicateCallback(uuid_indicate);
    }
    return success;
  }

  /**
   * write
   *
   * @param bleDevice
   * @param uuid_service
   * @param uuid_write
   * @param data
   * @param split
   * @param sendNextWhenLastSuccess
   * @param intervalBetweenTwoPackage
   * @param callback
   */
  public write(bleDevice: BleDevice, uuid_service: string, uuid_write: string, data: Uint8Array | null, split: boolean = true, sendNextWhenLastSuccess: boolean = true, intervalBetweenTwoPackage: number = 0, callback: BleWriteCallback) {
    if (callback == null) {
      throw new Error("BleWriteCallback can not be Null!");
    }

    if (data == null) {
      BleLog.e("data is Null!");
      callback.onWriteFailure(new OtherException("data is Null!"));
      return;
    }

    if (data.length > 20 && !split) {
      BleLog.w("Be careful: data's length beyond 20! Ensure MTU higher than 23, or use spilt write!");
    }
    if (this.multipleBluetoothController !== null) {
      let bleBluetooth: BleBluetooth | null = this.multipleBluetoothController.getBleBluetooth(bleDevice);
      if (bleBluetooth == null) {
        callback.onWriteFailure(new OtherException("This device not connect!"));
      } else {
        if (split && data.length > this.getSplitWriteNum()) {
          new SplitWriter().splitWrite(bleBluetooth, uuid_service, uuid_write, data,
            sendNextWhenLastSuccess, intervalBetweenTwoPackage, callback);
        } else {
          bleBluetooth.newBleConnector()
            .withUUIDString(uuid_service, uuid_write)
            .writeCharacteristic(data, callback, uuid_write);
        }
      }
    }
  }

  /**
   * read
   *
   * @param bleDevice
   * @param uuid_service
   * @param uuid_read
   * @param callback
   */
  public read(bleDevice: BleDevice, uuid_service: string, uuid_read: string, callback: BleReadCallback) {
    if (callback == null) {
      throw new EvalError("BleReadCallback can not be Null!");
    }
    if (this.multipleBluetoothController !== null) {
      let bleBluetooth: BleBluetooth | null = this.multipleBluetoothController.getBleBluetooth(bleDevice);
      if (bleBluetooth == null) {
        callback.onReadFailure(new OtherException("This device is not connected!"));
      } else {
        bleBluetooth.newBleConnector()
          .withUUIDString(uuid_service, uuid_read)
          .readCharacteristic(callback, uuid_read);
      }
    }
  }

  /**
   * read Rssi
   *
   * @param bleDevice
   * @param callback
   */
  public readRssi(bleDevice: BleDevice, callback: BleRssiCallback) {
    if (callback == null) {
      throw new Error("BleRssiCallback can not be Null!");
    }

    if (this.multipleBluetoothController !== null) {
      let bleBluetooth: BleBluetooth | null = this.multipleBluetoothController.getBleBluetooth(bleDevice);
      if (bleBluetooth == null) {
        callback.onRssiFailure(new OtherException("This device is not connected!"));
      } else {
        bleBluetooth.newBleConnector().readRemoteRssi(callback);
      }
    }


  }

  /**
   * set Mtu
   *
   * @param bleDevice
   * @param mtu
   * @param callback
   */
  public setMtu(bleDevice: BleDevice, mtu: number, callback: BleMtuChangedCallback) {
    if (callback == null) {
      throw new Error("BleMtuChangedCallback can not be Null!");
    }

    if (mtu > BleManager.DEFAULT_MAX_MTU) {
      BleLog.e("requiredMtu should lower than 512 !");
      callback.onSetMTUFailure(new OtherException("requiredMtu should lower than 512 !"));
      return;
    }

    if (mtu < BleManager.DEFAULT_MTU) {
      BleLog.e("requiredMtu should higher than 23 !");
      callback.onSetMTUFailure(new OtherException("requiredMtu should higher than 23 !"));
      return;
    }

    if (this.multipleBluetoothController !== null) {
      let bleBluetooth: BleBluetooth | null = this.multipleBluetoothController.getBleBluetooth(bleDevice);
      if (bleBluetooth == null) {
        callback.onSetMTUFailure(new OtherException("This device is not connected!"));
      } else {
        bleBluetooth.newBleConnector().setMtu(mtu, callback);
      }
    }


  }

  /**
   * requestConnectionPriority
   *
   * @param connectionPriority Request a specific connection priority. Must be one of
   *                           {@link BluetoothGatt#CONNECTION_PRIORITY_BALANCED},
   *                           {@link BluetoothGatt#CONNECTION_PRIORITY_HIGH}
   *                           or {@link BluetoothGatt#CONNECTION_PRIORITY_LOW_POWER}.
   * @throws IllegalArgumentException If the parameters are outside of their
   *                                  specified range.
   */
  public requestConnectionPriority(bleDevice: BleDevice, connectionPriority: number): boolean {
    //        let bleBluetooth: BleBluetooth = this.multipleBluetoothController.getBleBluetooth(bleDevice);
    //        if (bleBluetooth == null) {
    //            return false;
    //        } else {
    //            return bleBluetooth.newBleConnector().requestConnectionPriority(connectionPriority);
    //        }
    return false; // not supported
  }

  /**
   * is support ble?
   *
   * @return
   */
  public isSupportBle(): boolean {
    return true; //TODO
  }

  /**
   * Open bluetooth
   */
  public enableBluetooth() {
    //TODO
  }

  /**
   * Disable bluetooth
   */
  public disableBluetooth() {
    //TODO
  }

  /**
   * judge Bluetooth is enable
   *
   * @return
   */
  public isBlueEnable(): boolean {
    if (BleManager.MOCK_DEVICE) {
      return true;
    }
    return access.getState() == access.BluetoothState.STATE_ON;
  }

  public convertBleDevice(scanResult: ble.ScanResult): BleDevice {
    if (scanResult == null) {
      throw new Error("scanResult can not be Null!");
    }
    let deviceId: string = scanResult.deviceId;
    let rssi: number = scanResult.rssi;
    let scanRecord: ArrayBuffer = scanResult.data;
    let bytes: Uint8Array = new Uint8Array(scanRecord);
    let timestampNanos: number = 0;
    return new BleDevice(deviceId, '', rssi, bytes, timestampNanos);
  }

  public getBleBluetooth(bleDevice: BleDevice): BleBluetooth | null {
    if (this.multipleBluetoothController != null) {
      return this.multipleBluetoothController.getBleBluetooth(bleDevice);
    }
    return null;
  }

  private getBluetoothGatt(bleDevice: BleDevice): ble.GattClientDevice | null {
    let bleBluetooth: BleBluetooth | null = this.getBleBluetooth(bleDevice);
    if (bleBluetooth != null) {
      return bleBluetooth.getBluetoothGatt();
    }
    return null;
  }

  public getBluetoothGattServices(bleDevice: BleDevice, callback: AsyncCallback<Array<ble.GattService>>): void {
    let gattClientDevice = this.getBluetoothGatt(bleDevice);
    if (gattClientDevice != null) {
      return gattClientDevice.getServices((err, services) => {
        if (err == null) {
          this.getBleBluetooth(bleDevice)?.setServices(services);
        }
        callback(err, services);
      });
    }
    return;
  }

  public removeConnectGattCallback(bleDevice: BleDevice) {
    let bleBluetooth: BleBluetooth | null = this.getBleBluetooth(bleDevice);
    if (bleBluetooth != null) {
      bleBluetooth.removeConnectGattCallback();
    }
  }

  public removeRssiCallback(bleDevice: BleDevice) {
    let bleBluetooth: BleBluetooth | null = this.getBleBluetooth(bleDevice);
    if (bleBluetooth != null) {
      bleBluetooth.removeRssiCallback();
    }
  }

  public removeMtuChangedCallback(bleDevice: BleDevice) {
    let bleBluetooth: BleBluetooth | null = this.getBleBluetooth(bleDevice);
    if (bleBluetooth != null) {
      bleBluetooth.removeMtuChangedCallback();
    }
  }

  public removeNotifyCallback(bleDevice: BleDevice, uuid_notify: string) {
    let bleBluetooth: BleBluetooth | null = this.getBleBluetooth(bleDevice);
    if (bleBluetooth != null) {
      bleBluetooth.removeNotifyCallback(uuid_notify);
    }
  }

  public removeIndicateCallback(bleDevice: BleDevice, uuid_indicate: string) {
    let bleBluetooth: BleBluetooth | null = this.getBleBluetooth(bleDevice);
    if (bleBluetooth != null) {
      bleBluetooth.removeIndicateCallback(uuid_indicate);
    }
  }

  public removeWriteCallback(bleDevice: BleDevice, uuid_write: string) {
    let bleBluetooth: BleBluetooth | null = this.getBleBluetooth(bleDevice);
    if (bleBluetooth != null) {
      bleBluetooth.removeWriteCallback(uuid_write);
    }
  }

  public removeReadCallback(bleDevice: BleDevice, uuid_read: string) {
    let bleBluetooth: BleBluetooth | null = this.getBleBluetooth(bleDevice);
    if (bleBluetooth != null) {
      bleBluetooth.removeReadCallback(uuid_read);
    }
  }

  public clearCharacterCallback(bleDevice: BleDevice) {
    let bleBluetooth: BleBluetooth | null = this.getBleBluetooth(bleDevice);
    if (bleBluetooth != null) {
      bleBluetooth.clearCharacterCallback();
    }
  }

  public getScanSate(): BleScanState {
    return BleScanner.getInstance().getScanState();
  }

  public getAllConnectedDevice(): Array<string> {
    if (BleManager.MOCK_DEVICE) {
      return BleManager.mockBluetooth.getConnectedBLEDevices();
    }
    return connection.getPairedDevices();
  }

  /**
   * @param bleDevice
   * @return State of the profile connection. One of
   * {@link ProfileConnectionState#STATE_DISCONNECTED 0},
   * {@link ProfileConnectionState#STATE_CONNECTING 1},
   * {@link ProfileConnectionState#STATE_CONNECTED 2},
   * {@link ProfileConnectionState#STATE_DISCONNECTING 3}
   */
  public getConnectState(gattClientDevice: ble.GattClientDevice,
                         callback: Callback<ble.BLEConnectionChangeState>): void {
    return gattClientDevice.on('BLEConnectionStateChange', callback);
  }

  //这个方法返回的是已配对设备列表，不是实际连接状态列表。导致即使设备没有真正连接，也被误判为已连接。
  // public isConnected(device: BleDevice | string): boolean {
  //
  //   let list = this.getAllConnectedDevice();
  //   if (device instanceof BleDevice) {
  //     return list.indexOf(device.getMac()) >= 0;
  //   } else {
  //     return list.indexOf(device) >= 0;
  //   }
  // }

  public isConnected(device: BleDevice | string): boolean {
    // 检查multipleBluetoothController中是否有该设备的连接记录
    if (this.multipleBluetoothController != null) {
      if (device instanceof BleDevice) {
        return this.multipleBluetoothController.isContainDevice(device);
      } else {
        // 如果传入的是MAC地址字符串，需要查找对应的BleDevice
        let deviceList = this.multipleBluetoothController.getDeviceList();
        for (let i = 0; i < deviceList.length; i++) {
          if (deviceList[i].getMac() === device) {
            return true;
          }
        }
        return false;
      }
    }
    return false;
  }

  public disconnect(bleDevice: BleDevice) {
    if (this.multipleBluetoothController != null) {
      this.multipleBluetoothController.disconnect(bleDevice);
    }
  }

  public disconnectAllDevice() {
    if (this.multipleBluetoothController != null) {
      this.multipleBluetoothController.disconnectAllDevice();
    }
  }

  public destroy() {
    if (this.multipleBluetoothController != null) {
      this.multipleBluetoothController.destroy();
    }
  }
}