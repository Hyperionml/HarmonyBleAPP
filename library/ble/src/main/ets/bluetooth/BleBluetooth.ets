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


import BleManager from '../BleManager';
import BleConnector from '../bluetooth/BleConnector';
import BleGattCallback from '../callback/BleGattCallback';
import BleIndicateCallback from '../callback/BleIndicateCallback';
import BleMtuChangedCallback from '../callback/BleMtuChangedCallback';
import BleNotifyCallback from '../callback/BleNotifyCallback';
import BleReadCallback from '../callback/BleReadCallback';
import BleRssiCallback from '../callback/BleRssiCallback';
import BleWriteCallback from '../callback/BleWriteCallback';
import BleConnectStateParameter from '../data/BleConnectStateParameter';
import BleDevice from '../data/BleDevice';
import BleMsg from '../data/BleMsg';
import ConnectException from '../exception/ConnectException';
import OtherException from '../exception/OtherException';
import TimeoutException from '../exception/TimeoutException';
import BleLog from '../utils/BleLog';
import TextUtils from '../utils/TextUtils';
import { Handler, Message } from '../utils/Handler';
import ble from '@ohos.bluetooth.ble';
import constant from '@ohos.bluetooth.constant';
import { BusinessError } from '@ohos.base';

enum LastState {
  CONNECT_IDLE,
  CONNECT_CONNECTING,
  CONNECT_CONNECTED,
  CONNECT_FAILURE,
  CONNECT_DISCONNECT
};

/**
 * 表示“一个已连接设备”的GATT会话，
 * 封装单个 GATT 会话与回调分发，负责连接、服务发现、读写、MTU、RSSI、通知等，向上层通过 BleGattCallback、BleNotifyCallback 等回调上报。
 * newBleConnector() 进行供特征级操作notify/indicate/read/write/rssi/mtu
 * */
export default class BleBluetooth {
  private bleGattCallback: BleGattCallback | null = null;
  private bleRssiCallback: BleRssiCallback | null = null;
  private bleMtuChangedCallback: BleMtuChangedCallback | null = null;
  private bleNotifyCallbackHashMap = new Map<String, BleNotifyCallback>();
  private bleIndicateCallbackHashMap = new Map<String, BleIndicateCallback>();
  private bleWriteCallbackHashMap = new Map<String, BleWriteCallback>();
  private bleReadCallbackHashMap = new Map<String, BleReadCallback>();
  private lastState: LastState = LastState.CONNECT_IDLE;
  private isActiveDisconnect: boolean = false;
  private bleDevice: BleDevice;
  private gattClientDevice: ble.GattClientDevice | null = null;
  private mainHandler: Handler | null = null;
  private connectRetryCount: number = 0;
  private services: ble.GattService[] = [];

  public constructor(bleDevice: BleDevice) {
    this.bleDevice = bleDevice;
    this.initHandler();
  }

  public newBleConnector(): BleConnector {
    return new BleConnector(this);
  }

  public addConnectGattCallback(callback: BleGattCallback): void {
    this.bleGattCallback = callback;
  }

  public removeConnectGattCallback(): void {
    this.bleGattCallback = null;
  }

  public addNotifyCallback(uuid: string, bleNotifyCallback: BleNotifyCallback): void {
    this.bleNotifyCallbackHashMap.set(uuid, bleNotifyCallback);
  }

  public addIndicateCallback(uuid: string, bleIndicateCallback: BleIndicateCallback): void {
    this.bleIndicateCallbackHashMap.set(uuid, bleIndicateCallback);
  }

  public addWriteCallback(uuid: string, bleWriteCallback: BleWriteCallback): void {
    this.bleWriteCallbackHashMap.set(uuid, bleWriteCallback);
  }

  public addReadCallback(uuid: string, bleReadCallback: BleReadCallback): void {
    this.bleReadCallbackHashMap.set(uuid, bleReadCallback);
  }

  public removeNotifyCallback(uuid: string): void {
    if (this.bleNotifyCallbackHashMap.has(uuid))
      this.bleNotifyCallbackHashMap.delete(uuid);
  }

  public removeIndicateCallback(uuid: string): void {
    if (this.bleIndicateCallbackHashMap.has(uuid))
      this.bleIndicateCallbackHashMap.delete(uuid);
  }

  public removeWriteCallback(uuid: string): void {
    if (this.bleWriteCallbackHashMap.has(uuid))
      this.bleWriteCallbackHashMap.delete(uuid);
  }

  public removeReadCallback(uuid: string): void {
    if (this.bleReadCallbackHashMap.has(uuid))
      this.bleReadCallbackHashMap.delete(uuid);
  }

  public clearCharacterCallback(): void {
    this.bleNotifyCallbackHashMap.clear();
    this.bleIndicateCallbackHashMap.clear();
    this.bleWriteCallbackHashMap.clear();
    this.bleReadCallbackHashMap.clear();
  }

  public addRssiCallback(callback: BleRssiCallback): void {
    this.bleRssiCallback = callback;
  }

  public removeRssiCallback(): void {
    this.bleRssiCallback = null;
  }

  public addMtuChangedCallback(callback: BleMtuChangedCallback): void {
    this.bleMtuChangedCallback = callback;
  }

  public removeMtuChangedCallback(): void {
    this.bleMtuChangedCallback = null;
  }


  public getDeviceKey(): string {
    return this.bleDevice.getKey();
  }

  public getDevice(): BleDevice {
    return this.bleDevice;
  }

  public getBluetoothGatt(): ble.GattClientDevice | null {
    return this.gattClientDevice;
  }

  public setServices(services: ble.GattService[]) {
    this.services = services;
  }

  public getServices(): ble.GattService[] {
    return this.services;
  }

  // GATT连接的最后一层封装方法
  public connect(bleDevice: BleDevice, autoConnect: boolean, callback: BleGattCallback, connectRetryCount: number = 0): ble.GattClientDevice | null {
    BleLog.i("BleBluetooth.connect device: " + bleDevice.getName()
      + ", mac: " + bleDevice.getMac()
      + ", autoConnect: " + autoConnect
      + ", connectCount:" + (connectRetryCount + 1));
    if (connectRetryCount == 0) {
      this.connectRetryCount = 0;
    }

    // 注册连接回调并更新连接状态
    this.addConnectGattCallback(callback);
    this.lastState = LastState.CONNECT_CONNECTING;

    if (BleManager.MOCK_DEVICE) {
      setTimeout(() => {
        // 自定义的子类回调事件
        this.bleGattCallback?.onStartConnect();
      }, 500);
      if (this.mainHandler !== null) {
        let message = this.mainHandler.obtainMessage();
        message.what = BleMsg.MSG_DISCOVER_SERVICES;
        this.mainHandler.sendMessageDelayed(message, 1000);
      }
      return null;
    }

    try {
      // 通过MAC地址创建GATT客户端实例
      this.gattClientDevice = ble.createGattClientDevice(bleDevice.getMac());
    } catch (e) {
      BleLog.i("createGattClientDevice err: " +JSON.stringify(e));
    }

    try {
      // 订阅GATT profile协议的连接状态变化事件
      this.gattClientDevice?.on('BLEConnectionStateChange', this.connectStateChangeCallback);
    } catch (err) {
      BleLog.i("on BLEConnectionStateChange err: " +JSON.stringify(err));
    }

    try {
      // 连接，连接实例在成功连接后就能直接操控蓝牙设备和通信
      this.gattClientDevice?.connect()
      if (this.bleGattCallback != null) {
        // 通知上层连接开始
        this.bleGattCallback.onStartConnect();
      }

      if (this.mainHandler !== null) {
        let message = this.mainHandler.obtainMessage();
        message.what = BleMsg.MSG_CONNECT_OVER_TIME;
        this.mainHandler.sendMessageDelayed(message, BleManager.getInstance().getConnectOverTime());
      }
    } catch (e) {
      this.disconnectGatt();
      this.refreshDeviceCache();
      this.closeBluetoothGatt();
      this.lastState = LastState.CONNECT_FAILURE;
      BleManager.getInstance().getMultipleBluetoothController()?.removeConnectingBle(this);
      if (this.bleGattCallback != null) {
        this.bleGattCallback.onConnectFail(bleDevice, new OtherException("GATT connect exception occurred!"));
      }
    }

    return this.gattClientDevice;
  }

  public disconnect(): void {
    this.isActiveDisconnect = true;
    this.disconnectGatt();
  }

  public destroy(): void {
    this.lastState = LastState.CONNECT_IDLE;
    this.disconnectGatt();
    this.refreshDeviceCache();
    this.closeBluetoothGatt();
    this.removeConnectGattCallback();
    this.removeRssiCallback();
    this.removeMtuChangedCallback();
    this.clearCharacterCallback();
    if (this.mainHandler !== null) {
      this.mainHandler.removeAllMessage();
    }
  }

  private disconnectGatt(): void {
    if (BleManager.MOCK_DEVICE && this.mainHandler !== null) {
      let message: Message = this.mainHandler.obtainMessage();
      message.what = BleMsg.MSG_DISCONNECTED;
      message.obj = new BleConnectStateParameter(0);
      this.mainHandler.sendMessage(message);
      return;
    }
    if (this.gattClientDevice !== null) {
      try {
        this.gattClientDevice.disconnect();
      } catch (e) {
        BleLog.i("disconnect err: " +JSON.stringify(e));
      }
    }
  }

  private refreshDeviceCache(): void {
    //        try {
    //            final Method refresh = gattClientDevice.class.getMethod("refresh");
    //            if (!refresh && !this.gattClientDevice) {
    //                boolean success = (Boolean) refresh.invoke(this.gattClientDevice);
    //                BleLog.i("refreshDeviceCache, is success:  " + success);
    //            }
    //        } catch (e: Error) {
    //            BleLog.i("exception occur while refreshing device: " + e.getMessage());
    //            e.printStackTrace();
    //        }
  }

  private closeBluetoothGatt(): void {
    if (this.gattClientDevice != null) {
      try {
        this.gattClientDevice.close();
      } catch (e) {
        BleLog.i("closeBluetoothGatt err: " +JSON.stringify(e));
      }
    }
  }

  private handleMessage(msg: Message): void {
    let _this = this;
    if (_this.mainHandler === null) {
      return
    }
    switch (msg.what) {
      case BleMsg.MSG_CONNECT_FAIL: {
        console.info("handleMessage MSG_CONNECT_FAIL");
        _this.disconnectGatt();
        _this.refreshDeviceCache();
        _this.closeBluetoothGatt();

        if (_this.connectRetryCount < BleManager.getInstance().getReConnectCount()) {
          BleLog.e("Connect fail, try reconnect " + BleManager.getInstance()
            .getReConnectInterval() + " millisecond later");
          ++_this.connectRetryCount;

          let message: Message = _this.mainHandler.obtainMessage();
          message.what = BleMsg.MSG_RECONNECT;
          _this.mainHandler.sendMessageDelayed(message, BleManager.getInstance().getReConnectInterval());
        } else {
          _this.lastState = LastState.CONNECT_FAILURE;
          BleManager.getInstance().getMultipleBluetoothController()?.removeConnectingBle(_this);

          let para: BleConnectStateParameter = msg.obj as BleConnectStateParameter;
          let status: number = para.getStatus();
          if (_this.bleGattCallback != null && _this.gattClientDevice !== null) {
            _this.bleGattCallback.onConnectFail(_this.bleDevice, new ConnectException(_this.gattClientDevice, status));
          }
        }
      }
        break;

      case BleMsg.MSG_DISCONNECTED: {
        console.info("handleMessage MSG_DISCONNECTED");
        _this.lastState = LastState.CONNECT_DISCONNECT;
        BleManager.getInstance().getMultipleBluetoothController()?.removeBleBluetooth(_this);

        _this.disconnect();
        _this.refreshDeviceCache();
        _this.closeBluetoothGatt();
        _this.removeRssiCallback();
        _this.removeMtuChangedCallback();
        _this.clearCharacterCallback();
        _this.mainHandler.removeAllMessage();

        let para: BleConnectStateParameter = msg.obj as BleConnectStateParameter;
        let isActive: boolean = para.isActive();
        let status: number = para.getStatus();
        if (_this.bleGattCallback != null && _this.gattClientDevice !== null) {
          _this.bleGattCallback.onDisConnected(isActive, _this.bleDevice, _this.gattClientDevice, status);
        }
      }
        break;

      case BleMsg.MSG_RECONNECT: {
        if (_this.bleGattCallback != null) {
          console.info("handleMessage MSG_RECONNECT");
          _this.connect(_this.bleDevice, false, _this.bleGattCallback, _this.connectRetryCount);
        }

      }
        break;

      case BleMsg.MSG_CONNECT_OVER_TIME: {
        console.info("handleMessage MSG_CONNECT_OVER_TIME");
        _this.disconnectGatt();
        _this.refreshDeviceCache();
        _this.closeBluetoothGatt();

        _this.lastState = LastState.CONNECT_FAILURE;
        BleManager.getInstance().getMultipleBluetoothController()?.removeConnectingBle(_this);

        if (_this.bleGattCallback != null) {
          _this.bleGattCallback.onConnectFail(_this.bleDevice, new TimeoutException());
        }
      }
        break;

      case BleMsg.MSG_DISCOVER_SERVICES: {
        console.info("handleMessage MSG_DISCOVER_SERVICES");
        if (BleManager.MOCK_DEVICE) {
          let message = _this.mainHandler.obtainMessage();
          message.what = BleMsg.MSG_DISCOVER_SUCCESS;
          message.obj = new BleConnectStateParameter(0);
          _this.mainHandler.sendMessageDelayed(message, 1000);
          return;
        }

        if (_this.gattClientDevice != null) {
          _this.gattClientDevice.getServices(this.serviceDiscoverCallback);
        } else {
          let message: Message = _this.mainHandler.obtainMessage();
          message.what = BleMsg.MSG_DISCOVER_FAIL;
          _this.mainHandler.sendMessage(message);
        }
      }
        break;

      case BleMsg.MSG_DISCOVER_FAIL: {
        console.info("handleMessage MSG_DISCOVER_FAIL");
        _this.disconnectGatt();
        _this.refreshDeviceCache();
        _this.closeBluetoothGatt();

        _this.lastState = LastState.CONNECT_FAILURE;
        BleManager.getInstance().getMultipleBluetoothController()?.removeConnectingBle(_this);

        if (_this.bleGattCallback != null) {
          _this.bleGattCallback.onConnectFail(_this.bleDevice,
            new OtherException("GATT discover services exception occurred!"));
        }
      }
        break;

      case BleMsg.MSG_DISCOVER_SUCCESS: {
        console.info("handleMessage MSG_DISCOVER_SUCCESS");
        _this.lastState = LastState.CONNECT_CONNECTED;
        _this.isActiveDisconnect = false;
        BleManager.getInstance().getMultipleBluetoothController()?.removeConnectingBle(_this);
        BleManager.getInstance().getMultipleBluetoothController()?.addBleBluetooth(_this);

        let para: BleConnectStateParameter = msg.obj as BleConnectStateParameter;
        let status: number = para.getStatus();
        console.info("_this.bleGattCallback:" + _this.bleGattCallback);

        if (_this.bleGattCallback != null && _this.gattClientDevice !== null) {
          _this.bleGattCallback.onConnectSuccess(_this.bleDevice, _this.gattClientDevice, status);
        }
      }
        break;
      default:
        break;
    }
  }

  private initHandler(): void {
    let _this = this;

    class TempHandler extends Handler {
      public handleMessage(msg: Message): void {
        _this.handleMessage(msg);
      }
    }

    this.mainHandler = new TempHandler()
  }

  // GATT连接状态变化回调处理
  private connectStateChangeCallback = (newStatus: ble.BLEConnectionChangeState) => {

    BleLog.i("onConnectionStateChange "
      + "newStatus: " + newStatus.state);

    if (this.mainHandler === null) {
      return
    }

    if (newStatus.state == constant.ProfileConnectionState.STATE_CONNECTED) {
      // 连接成功：移除超时并开始服务发现
      this.mainHandler.removeMessages(BleMsg.MSG_CONNECT_OVER_TIME);
      let message: Message = this.mainHandler.obtainMessage();
      message.what = BleMsg.MSG_DISCOVER_SERVICES;
      this.mainHandler.sendMessageDelayed(message, 500);// 发送服务发现消息

    } else if (newStatus.state == constant.ProfileConnectionState.STATE_DISCONNECTED) {
      // 连接断开：根据当前状态判断是连接失败还是正常断开
      if (this.lastState == LastState.CONNECT_CONNECTING) {

        let message: Message = this.mainHandler.obtainMessage();
        message.what = BleMsg.MSG_CONNECT_FAIL;
        message.obj = new BleConnectStateParameter(0);
        this.mainHandler.sendMessage(message);

      } else if (this.lastState == LastState.CONNECT_CONNECTED) {

        let message: Message = this.mainHandler.obtainMessage();
        message.what = BleMsg.MSG_DISCONNECTED;
        let para: BleConnectStateParameter = new BleConnectStateParameter(0);
        para.setActive(this.isActiveDisconnect);
        message.obj = para;
        this.mainHandler.sendMessage(message);
      }
    }
  }

  private serviceDiscoverCallback = (err: BusinessError, services: Array<ble.GattService>) => { //AsyncCallback<Array<GattService>>
    BleLog.i("onServicesDiscovered "
      + "err: " + err
      /*+ '\n' + "currentThread: " + Thread.currentThread().getId()*/);

    if (this.mainHandler !== null) {
      if (err == null) {
        let message: Message = this.mainHandler.obtainMessage();
        message.what = BleMsg.MSG_DISCOVER_SUCCESS;
        message.obj = new BleConnectStateParameter(0);
        this.mainHandler.sendMessage(message);
      } else {
        let message: Message = this.mainHandler.obtainMessage();
        message.what = BleMsg.MSG_DISCOVER_FAIL;
        this.mainHandler.sendMessage(message);
      }
    }


  }
  private characteristicChangedCallback = (err: ESObject, characteristic: ESObject) => { //Callback<BLECharacteristic>
    BleLog.i("onCharacteristicChanged "
      + "err: " + err.code
      /*+ '\n' + "currentThread: " + Thread.currentThread().getId()*/);

    for (let callback of this.bleNotifyCallbackHashMap.values()) {
      if (callback instanceof BleNotifyCallback) {
        let bleNotifyCallback: BleNotifyCallback = callback as BleNotifyCallback;
        if (TextUtils.equalsIgnoreCase(characteristic.characteristicUuid, bleNotifyCallback.getKey())) {
          let handler: Handler | null = bleNotifyCallback.getHandler();
          if (handler != null) {
            let message: Message = handler.obtainMessage();
            message.what = BleMsg.MSG_CHA_NOTIFY_DATA_CHANGE;
            message.obj = bleNotifyCallback;
            let bundle: Map<ESObject, ESObject> = new Map();
            bundle.set(BleMsg.KEY_NOTIFY_BUNDLE_VALUE, characteristic.characteristicValue);
            message.setData(bundle);
            handler.sendMessage(message);
          }
        }
      }
    }

    for (let callback of this.bleIndicateCallbackHashMap.values()) {
      if (callback instanceof BleIndicateCallback) {
        let bleIndicateCallback: BleIndicateCallback = callback as BleIndicateCallback;
        if (TextUtils.equalsIgnoreCase(characteristic.characteristicUuid, bleIndicateCallback.getKey())) {
          let handler: Handler | null = bleIndicateCallback.getHandler();
          if (handler != null) {
            let message: Message = handler.obtainMessage();
            message.what = BleMsg.MSG_CHA_INDICATE_DATA_CHANGE;
            message.obj = bleIndicateCallback;
            let bundle: Map<ESObject, ESObject> = new Map();
            bundle.set(BleMsg.KEY_INDICATE_BUNDLE_VALUE, characteristic.characteristicValue);
            message.setData(bundle);
            handler.sendMessage(message);
          }
        }
      }
    }
  }
  private descriptorWriteCallback = (err: ESObject, descriptor: ESObject) => {

    for (let callback of this.bleNotifyCallbackHashMap.values()) {
      if (callback instanceof BleNotifyCallback) {
        let bleNotifyCallback: BleNotifyCallback = callback as BleNotifyCallback;
        if (TextUtils.equalsIgnoreCase(descriptor.characteristicUuid, bleNotifyCallback.getKey())) {
          let handler: Handler | null = bleNotifyCallback.getHandler();
          if (handler != null) {
            let message: Message = handler.obtainMessage();
            message.what = BleMsg.MSG_CHA_NOTIFY_RESULT;
            message.obj = bleNotifyCallback;
            let bundle: Map<ESObject, ESObject> = new Map();
            bundle.set(BleMsg.KEY_NOTIFY_BUNDLE_STATUS, err);
            message.setData(bundle);
            handler.sendMessage(message);
          }
        }
      }
    }

    for (let callback of this.bleIndicateCallbackHashMap.values()) {
      if (callback instanceof BleIndicateCallback) {
        let bleIndicateCallback: BleIndicateCallback = callback as BleIndicateCallback;
        if (TextUtils.equalsIgnoreCase(descriptor.characteristicUuid, bleIndicateCallback.getKey())) {
          let handler: Handler | null = bleIndicateCallback.getHandler();
          if (handler != null) {
            let message: Message = handler.obtainMessage();
            message.what = BleMsg.MSG_CHA_INDICATE_RESULT;
            message.obj = bleIndicateCallback;
            let bundle: Map<ESObject, ESObject> = new Map();
            bundle.set(BleMsg.KEY_INDICATE_BUNDLE_STATUS, err);
            message.setData(bundle);
            handler.sendMessage(message);
          }
        }
      }
    }
  }
  private characteristicWriteCallback = (err: ESObject, characteristic: ESObject) => {
    for (let callback of this.bleWriteCallbackHashMap.values()) {
      if (callback instanceof BleWriteCallback) {
        let bleWriteCallback: BleWriteCallback = callback as BleWriteCallback;
        if (TextUtils.equalsIgnoreCase(characteristic.characteristicUuid, bleWriteCallback.getKey())) {
          let handler: Handler | null = bleWriteCallback.getHandler();
          if (handler != null) {
            let message: Message = handler.obtainMessage();
            message.what = BleMsg.MSG_CHA_WRITE_RESULT;
            message.obj = bleWriteCallback;
            let bundle: Map<ESObject, ESObject> = new Map();
            bundle.set(BleMsg.KEY_WRITE_BUNDLE_STATUS, err);
            bundle.set(BleMsg.KEY_WRITE_BUNDLE_VALUE, characteristic.characteristicValue);
            message.setData(bundle);
            handler.sendMessage(message);
          }
        }
      }
    }
  }
  private characteristicReadCallback = (err: ESObject, characteristic: ESObject) => { //AsyncCallback<BLECharacteristic>
    for (let callback of this.bleReadCallbackHashMap.values()) {
      if (callback instanceof BleReadCallback) {
        let bleReadCallback: BleReadCallback = callback as BleReadCallback;
        if (TextUtils.equalsIgnoreCase(characteristic.characteristicUuid, bleReadCallback.getKey())) {
          let handler = bleReadCallback.getHandler();
          if (handler != null) {
            let message = handler.obtainMessage();
            message.what = BleMsg.MSG_CHA_READ_RESULT;
            message.obj = bleReadCallback;
            let bundle: Map<ESObject, ESObject> = new Map();
            bundle.set(BleMsg.KEY_READ_BUNDLE_STATUS, err);
            bundle.set(BleMsg.KEY_READ_BUNDLE_VALUE, characteristic.characteristicValue);
            message.setData(bundle);
            handler.sendMessage(message);
          }
        }
      }
    }
  }
  private readRemoteRssiCallback = (err: ESObject, rssi: number) => { //AsyncCallback<number>
    if (this.bleRssiCallback != null) {
      let handler = this.bleRssiCallback.getHandler();
      if (handler != null) {
        let message = handler.obtainMessage();
        message.what = BleMsg.MSG_READ_RSSI_RESULT;
        message.obj = this.bleRssiCallback;
        let bundle: Map<ESObject, ESObject> = new Map();
        bundle.set(BleMsg.KEY_READ_RSSI_BUNDLE_STATUS, err);
        bundle.set(BleMsg.KEY_READ_RSSI_BUNDLE_VALUE, rssi);
        message.setData(bundle);
        handler.sendMessage(message);
      }
    }
  }
  private setMtuCallback = (err: ESObject, mtu: number) => {
    if (this.bleMtuChangedCallback != null) {
      let handler = this.bleMtuChangedCallback.getHandler();
      if (handler != null) {
        let message = handler.obtainMessage();
        message.what = BleMsg.MSG_SET_MTU_RESULT;
        message.obj = this.bleMtuChangedCallback;
        let bundle: Map<ESObject, ESObject> = new Map();
        bundle.set(BleMsg.KEY_SET_MTU_BUNDLE_STATUS, err);
        bundle.set(BleMsg.KEY_SET_MTU_BUNDLE_VALUE, mtu);
        message.setData(bundle);
        handler.sendMessage(message);
      }
    }
  }
}

