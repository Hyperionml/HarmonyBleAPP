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
import BleBluetooth from '../bluetooth/BleBluetooth';
import BleDevice from '../data/BleDevice';
import BleLruHashMap from '../utils/BleLruHashMap';
import TextUtils from '../utils/TextUtils';
import ArrayUtils from '../utils/ArrayUtils'

export default class MultipleBluetoothController {

    private bleLruHashMap: BleLruHashMap<String, BleBluetooth>;
    private bleTempHashMap: Map<String, BleBluetooth>;

    public constructor() {
        this.bleLruHashMap = new BleLruHashMap(BleManager.getInstance().getMaxConnectCount());
        this.bleTempHashMap = new Map();
    }

    public buildConnectingBle(bleDevice: BleDevice): BleBluetooth {
        let bleBluetooth = new BleBluetooth(bleDevice);
        if (!this.bleTempHashMap.has(bleBluetooth.getDeviceKey())) {
            this.bleTempHashMap.set(bleBluetooth.getDeviceKey(), bleBluetooth);
        }
        return bleBluetooth;
    }

    public removeConnectingBle(bleBluetooth: BleBluetooth): void {
        if (bleBluetooth == null) {
            return;
        }
        if (this.bleTempHashMap.has(bleBluetooth.getDeviceKey())) {
            this.bleTempHashMap.delete(bleBluetooth.getDeviceKey());
        }
    }

    public addBleBluetooth(bleBluetooth: BleBluetooth): void {
        if (bleBluetooth == null) {
            return;
        }
        if (!this.bleLruHashMap.has(bleBluetooth.getDeviceKey())) {
            this.bleLruHashMap.set(bleBluetooth.getDeviceKey(), bleBluetooth);
        }
    }

    public removeBleBluetooth(bleBluetooth: BleBluetooth): void {
        if (bleBluetooth == null) {
            return;
        }
        if (this.bleLruHashMap.has(bleBluetooth.getDeviceKey())) {
            this.bleLruHashMap.delete(bleBluetooth.getDeviceKey());
        }
    }

    public isContainDevice(bleDevice: BleDevice): boolean {
        return bleDevice != null && this.bleLruHashMap.has(bleDevice.getKey());
    }

//    public isContainDevice(bluetoothDevice: BluetoothDevice): boolean {
//        return bluetoothDevice != null && this.bleLruHashMap.has(bluetoothDevice.getName() + bluetoothDevice.getAddress());
//    }

    public getBleBluetooth(bleDevice: BleDevice): BleBluetooth |null{
        if (bleDevice != null) {
            if (this.bleLruHashMap.has(bleDevice.getKey())) {
                let key:BleBluetooth |undefined = this.bleLruHashMap.get(bleDevice.getKey());
                if(key !==undefined){
                    return key
                }
            }
        }
        return null;
    }

    public disconnect(bleDevice: BleDevice): void {
        if (this.isContainDevice(bleDevice)) {
            this.getBleBluetooth(bleDevice)?.disconnect();
        }
    }

    public disconnectAllDevice(): void {
        this.bleLruHashMap.forEach((value, key, map)=>{
          value.disconnect();
        })
        this.bleLruHashMap.clear();
    }

    public destroy(): void {
        this.bleLruHashMap.forEach((value, key, map)=>{
            value.destroy();
        });
        this.bleLruHashMap.clear();


        this.bleTempHashMap.forEach((value, key, map)=>{
            value.destroy();
        });
        this.bleTempHashMap.clear();
    }

    public getBleBluetoothList(): Array<BleBluetooth> {
        let bleBluetoothList = ArrayUtils.getAll(this.bleLruHashMap.values());
        bleBluetoothList.sort((lhs, rhs) => {
            return TextUtils.compareToIgnoreCase(lhs.getDeviceKey(), rhs.getDeviceKey());
        });
        return bleBluetoothList;
    }

    public getDeviceList(): Array<BleDevice> {
        this.refreshConnectedDevice();
        let deviceList = new Array<BleDevice>();
        for (let bleBluetooth of this.getBleBluetoothList()){
            if (bleBluetooth != null) {
                deviceList.push(bleBluetooth.getDevice());
            }
        }
        return deviceList;
    }

    public refreshConnectedDevice(): void {
        let bluetoothList: Array<BleBluetooth> = this.getBleBluetoothList();
        for (let i = 0; bluetoothList != null && i < bluetoothList.length; i++) {
            let bleBluetooth: BleBluetooth = bluetoothList[i];
            if (!BleManager.getInstance().isConnected(bleBluetooth.getDevice())) {
                this.removeBleBluetooth(bleBluetooth);
            }
        }
    }
}
