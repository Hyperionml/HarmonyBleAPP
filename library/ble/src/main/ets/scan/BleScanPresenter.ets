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


import BleScanner from '../scan/BleScanner'
import BleDevice from '../data/BleDevice'
import BleScanPresenterImp from '../callback/BleScanPresenterImp'
import BleLog from '../utils/BleLog'
import HexUtil from '../utils/HexUtil'
import TextUtils from '../utils/TextUtils'
import ArrayUitls from '../utils/ArrayUtils'
import ble from '@ohos.bluetooth.ble'

abstract class BleScanPresenter {
  private mDeviceNames: string[] = [];
  private mDeviceMac: string = '';
  private mFuzzy: boolean = false;
  private mNeedConnect: boolean = false;
  private mScanTimeout: number = 0;
  private mBleScanPresenterImp: BleScanPresenterImp | null = null;
  private mBleDeviceList: BleDevice[] = [];

  public prepare(names: string[], mac: string, fuzzy: boolean, needConnect: boolean,
                 timeOut: number, bleScanPresenterImp: BleScanPresenterImp): void {
    BleLog.i('BleScanPresenter prepare');
    this.mDeviceNames = names;
    this.mDeviceMac = mac;
    this.mFuzzy = fuzzy;
    this.mNeedConnect = needConnect;
    this.mScanTimeout = timeOut;
    this.mBleScanPresenterImp = bleScanPresenterImp;
  }

  public isNeedConnect(): boolean {
    BleLog.i('BleScanPresenter isNeedConnect');
    return this.mNeedConnect;
  }

  public getBleScanPresenterImp(): BleScanPresenterImp | null {
    BleLog.i('BleScanPresenter getBleScanPresenterImp');
    return this.mBleScanPresenterImp;
  }

  // 封装单个被扫描到的设备
  private handleResult(bleDevice: BleDevice): void {
    BleLog.i('BleScanPresenter handleResult');
    // 这是需要子类实现的抽象方法
    this.onLeScan(bleDevice);
    try {
      // 用地址创建GattClientDevice实例
      let gattClient = ble.createGattClientDevice(bleDevice.getMac());
      let that = this
      // 这里是用GattClientDevice实例去获取对应蓝牙设备的名字，但是其实在扫描返回的结果集里已经包含了设备的名字，我觉得这一步是多余的
      gattClient.getDeviceName((err, data) => {
        // 获取到名字后又封装到BleDevice中
        bleDevice.setName(data);
        that.checkDevice(bleDevice);
      })
    } catch (e) {
      BleLog.e("BleScanPresenter getDeviceName err: " +JSON.stringify(e));
    }
  }

  // 扫描的结果是Array<ble.ScanResult>，包含mac地址、rssi、data、设备名称等
  public handleScanResults(data: Array<ble.ScanResult>): void {
    BleLog.i('BleScanPresenter handleScanResults');
    for (let i = 0; i < data.length; i++) {
      let item = data[i];
      // 将扫描结果封装为BleDevice对象
      let device: BleDevice = new BleDevice(item.deviceId, "", item.rssi, new Uint8Array(item.data), new Date().getTime());
      this.handleResult(device);
    }
  }

  /**
   * bleDevice中mac地址和名字是否符合要求
   * @param bleDevice
   */
  private checkDevice(bleDevice: BleDevice): void {
    BleLog.i('BleScanPresenter checkDevice');
    // 无过滤条件直接通过
    if (TextUtils.isEmpty(this.mDeviceMac) && ArrayUitls.isEmpty(this.mDeviceNames)) {
      this.correctDeviceAndNextStep(bleDevice);
      return;
    }

    // MAC地址过滤
    if (!TextUtils.isEmpty(this.mDeviceMac)) {
      if (this.mDeviceMac.toLowerCase() != bleDevice.getMac().toLowerCase())
        return;
    }

    // 设备名称过滤
    if (!ArrayUitls.isEmpty(this.mDeviceNames)) {
      let found = false;
      for (let i = 0; i < this.mDeviceNames.length; i++) {
        let remoteName: string = bleDevice.getName();
        if (remoteName == null || remoteName == undefined) {
          remoteName = "";
        }
        let name = this.mDeviceNames[i]
        // 模糊匹配或精确匹配
        if (this.mFuzzy ? (remoteName.indexOf(name) >= 0) : (remoteName == name)) {
          found = true;
        }
      }

      if (!found) {
        return;
      }
    }

    this.correctDeviceAndNextStep(bleDevice);
  }

  /**
   * 如果扫描到的设备mac地址和名字都是空的则会进入这里
   * @param bleDevice
   */
  private correctDeviceAndNextStep(bleDevice: BleDevice): void {
    BleLog.i('BleScanPresenter correctDeviceAndNextStep');
    if (this.mNeedConnect) {
      BleLog.i("devices detected  ------"
        + "  name:" + bleDevice.getName()
        + "  mac:" + bleDevice.getMac()
        + "  Rssi:" + bleDevice.getRssi()
        + "  scanRecord:" + HexUtil.formatHexString(bleDevice.getScanRecord()));

      this.mBleDeviceList.push(bleDevice);
      BleScanner.getInstance().stopLeScan();

    } else {

      // 这里检查到如果如果该设备没有被扫描到过就会被加入被扫描的列表中
      let hasFound: boolean = false;
      for (let i = 0; i < this.mBleDeviceList.length; i++) {
        if (this.mBleDeviceList[i].getMac() == bleDevice.getMac()) {
          hasFound = true;
          break;
        }
      }

      if (!hasFound) {
        BleLog.i("device detected  ------"
          + "  name: " + bleDevice.getName()
          + "  mac: " + bleDevice.getMac()
          + "  Rssi: " + bleDevice.getRssi()
          + "  scanRecord: " + HexUtil.formatHexString(bleDevice.getScanRecord(), true));

        this.mBleDeviceList.push(bleDevice);
        // 需要子类实现的抽象方法
        this.onScanning(bleDevice);
      }
    }
  }

  // 扫描完毕之后执行
  public notifyScanStarted(success: boolean): void {
    BleLog.i('BleScanPresenter notifyScanStarted');
    this.mBleDeviceList = [];

    if (success && this.mScanTimeout > 0) {
      setTimeout(() => {
        // 关闭扫描
        BleScanner.getInstance().stopLeScan();
      }, this.mScanTimeout);
    }

    this.onScanStarted(success);
  }

  public notifyScanStopped(): void {
    BleLog.i('BleScanPresenter notifyScanStopped');
    this.onScanFinished(this.mBleDeviceList);
  }

  public abstract onScanStarted(success: boolean): void;

  public abstract onLeScan(bleDevice: BleDevice): void;

  public abstract onScanning(bleDevice: BleDevice): void;

  public abstract onScanFinished(bleDeviceList: BleDevice[]): void;
}

export default BleScanPresenter;