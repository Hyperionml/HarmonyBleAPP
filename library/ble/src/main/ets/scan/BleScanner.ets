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
import BleScanState from '../data/BleScanState';
import BleScanPresenterImp from '../callback/BleScanPresenterImp';
import BleScanCallback from '../callback/BleScanCallback';
import BleScanAndConnectCallback from '../callback/BleScanAndConnectCallback';
import BleScanPresenter from './BleScanPresenter';
import BleDevice from '../data/BleDevice';
import BleLog from '../utils/BleLog';
import ble from '@ohos.bluetooth.ble';

type UUID = string;

export default class BleScanner {
  private static instance: BleScanner;

  private constructor() {
  }

  public static getInstance(): BleScanner {
    BleLog.i('BleScanner getInstance');
    if (!BleScanner.instance) {
      BleScanner.instance = new BleScanner();
    }
    return BleScanner.instance;
  }

  private mBleScanState: BleScanState = BleScanState.STATE_IDLE;
  private readonly mBleScanPresenter: BleScanPresenter = new TempBleScanPresenter();

  /**
   * 从BleManager的scan方法进入开始正式扫描
   * @param serviceUuids
   * @param names
   * @param mac
   * @param fuzzy
   * @param timeOut
   * @param callback 扫描结果的封装回调
   */
  public scan(serviceUuids: UUID[], names: string[], mac: string, fuzzy: boolean,
              timeOut: number, callback: BleScanCallback): void {
    BleLog.i('BleScanner scan');
    this.startLeScan(serviceUuids, names, mac, fuzzy, false, timeOut, callback);
  }

  public scanAndConnect(serviceUuids: UUID[], names: string[], mac: string, fuzzy: boolean,
                        timeOut: number, callback: BleScanAndConnectCallback): void {
    BleLog.i('BleScanner scanAndConnect');
    this.startLeScan(serviceUuids, names, mac, fuzzy, true, timeOut, callback);
  }

  public mockStartLeScan(serviceUuids: UUID[], names: string[], mac: string, fuzzy: boolean, needConnect: boolean,
                         timeOut: number, imp: BleScanPresenterImp) {
    console.info("mockStartLeScan")
  }

  // 用于封装扫描结果的回调函数
  callback = (data: ESObject) => {
    this.mBleScanPresenter.handleScanResults(data);
  };

  /**
   * 开始正式扫描
   * @param serviceUuids
   * @param names
   * @param mac
   * @param fuzzy
   * @param needConnect
   * @param timeOut 超时时间
   * @param imp 这是扫描结果
   */
  public startLeScan(serviceUuids: UUID[], names: string[], mac: string, fuzzy: boolean,
                     needConnect: boolean, timeOut: number, imp: BleScanPresenterImp): void {
    console.info("startLeScan")

    // 状态检查：确保同时只有一个扫描任务运行
    if (this.mBleScanState != BleScanState.STATE_IDLE) {
      BleLog.w("scan action already exists, complete the previous scan action first");
      if (imp != null) {
        imp.onScanStarted(false);
      }
      return;
    }

    //用传入的参数初始化mBleScanPresenter
    this.mBleScanPresenter.prepare(names, mac, fuzzy, needConnect, timeOut, imp);
    console.info("before on")
    if (BleManager.MOCK_DEVICE) {
      //这一步在原本是没有的，似乎是模拟扫描
      BleManager.mockBluetooth.onScan(this.callback);
    } else {
      try {
       // 这里进入官方接口，去订阅蓝牙扫描时间，然后将扫描结果传回封装的回调
        // 这里的callback是一个函数
        ble.on('BLEDeviceFind', this.callback);
      } catch (e) {
        BleLog.e("on BLEDeviceFind err: " +JSON.stringify(e));
      }
    }
    console.info("after on")

    let filterArry: ble.ScanFilter[] = [];


    for (let i = 0; i < serviceUuids.length; i++) {
      let filter: ble.ScanFilter = {
        serviceUuid: serviceUuids[i]
      };
      filterArry.push(filter);
    }

    let scanOption: ble.ScanOptions = {
      dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,      // 低功耗扫描模式
      matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE,   // 积极匹配模式
      interval: 0
    };
    if (BleManager.MOCK_DEVICE) {
      BleManager.mockBluetooth.startBLEScan();
    } else {
      // 启动系统BLE扫描
      try {
        if (filterArry.length == 0) {
          ble.startBLEScan(null, scanOption);        // 无过滤条件扫描
        } else {
          ble.startBLEScan(filterArry, scanOption);  // 带过滤条件扫描
        }
      } catch (e) {
        BleLog.e("startBLEScan err: " +JSON.stringify(e));
      }
    }

    // 修改状态为扫描中
    this.mBleScanState = BleScanState.STATE_SCANNING;
    this.mBleScanPresenter.notifyScanStarted(true);
  }

  /**
   * 关闭扫描
   */
  public stopLeScan(): void {
    BleLog.i('BleScanner stopLeScan');
    if (BleManager.MOCK_DEVICE) {
      BleManager.mockBluetooth.stopBLEScan();
    } else {
      try {
        ble.stopBLEScan();
      } catch (e) {
        BleLog.e("stopBLEScan err: " +JSON.stringify(e));
      }
    }
    this.mBleScanState = BleScanState.STATE_IDLE;
    try {
      // 取消订阅
      ble.off('BLEDeviceFind', this.callback)
    } catch (e) {
      BleLog.e("off BLEDeviceFind err: " +JSON.stringify(e));
    }
    this.mBleScanPresenter.notifyScanStopped();
  }

  public getScanState(): BleScanState {
    BleLog.i('BleScanner getInstance');
    return this.mBleScanState;
  }
}

// 此处是扫描结果集的内部实现
class TempBleScanPresenter extends BleScanPresenter {
  public onScanStarted(success: boolean): void {
    BleLog.i('TempBleScanPresenter onScanStarted');
    try {
      let callback: BleScanPresenterImp | null = this.getBleScanPresenterImp();
      if (callback != null) {
        callback.onScanStarted(success);
      }
    } catch (e) {
      BleLog.e('TempBleScanPresenter onScanStarted err: ' + JSON.stringify(e));
    }
  }

  // 该方法会在封装单个被扫描到的设备到结果集时触发
  public onLeScan(bleDevice: BleDevice) {
    BleLog.i('TempBleScanPresenter onLeScan');
    try {
      if (this.isNeedConnect()) {
        let callback: BleScanAndConnectCallback = this.getBleScanPresenterImp() as BleScanAndConnectCallback;
        if (callback != null) {
          callback.onLeScan(bleDevice);
        }
      } else {
        let callback: BleScanCallback = this.getBleScanPresenterImp() as BleScanCallback;
        if (callback != null) {
          callback.onLeScan(bleDevice);
        }
      }
    } catch (e) {
      BleLog.e('TempBleScanPresenter onLeScan err: ' + JSON.stringify(e));
    }
  }

  public onScanning(result: BleDevice): void {
    BleLog.i('TempBleScanPresenter onScanning');
    try {
      let callback: BleScanPresenterImp | null = this.getBleScanPresenterImp();
      if (callback != null) {
        callback.onScanning(result);
      }
    } catch (e) {
      BleLog.e('TempBleScanPresenter onScanning err: ' + JSON.stringify(e));
    }
  }

  public onScanFinished(bleDeviceList: BleDevice[]): void {
    BleLog.i('TempBleScanPresenter onScanFinished');
    try {
      if (this.isNeedConnect()) {
        let callback: BleScanAndConnectCallback = this.getBleScanPresenterImp() as BleScanAndConnectCallback;
        if (bleDeviceList == null || bleDeviceList == undefined || bleDeviceList.length < 1) {
          if (callback != null) {
            callback.onScanFinished(null);
          }
        } else {
          if (callback != null) {
            callback.onScanFinished(bleDeviceList[0]);
          }
          let list: BleDevice[] = bleDeviceList;
          setTimeout(() => {
            BleManager.getInstance().connect(list[0], callback);
          }, 100)
        }
      } else {
        let callback: BleScanCallback = this.getBleScanPresenterImp() as BleScanCallback;
        if (callback != null) {
          callback.onScanFinished(bleDeviceList);
        }
      }
    } catch (e) {
      BleLog.e('TempBleScanPresenter onScanFinished err: ' + JSON.stringify(e));
    }
  }
}


