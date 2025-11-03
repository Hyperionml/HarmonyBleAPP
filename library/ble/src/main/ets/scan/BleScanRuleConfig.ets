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

import BleManager from '../BleManager'

type UUID = string;

class BleScanRuleConfigBuilder {
  private mDeviceNames: string[] = [];
  private mDeviceMac: string = '';
  private mAutoConnect: boolean = false;
  private mFuzzy: boolean = false;
  private mTimeOut: number = 10000;
  private mServiceUuids: UUID[] = [];

  public constructor() {
  }

  public setServiceUuids(uuids: UUID[]) {
    this.mServiceUuids = uuids;
    return this;
  }

  public setDeviceName(fuzzy: boolean, name: string[]) {
    this.mFuzzy = fuzzy;
    this.mDeviceNames = name;
    return this;
  }

  public setDeviceMac(mac: string) {
    this.mDeviceMac = mac;
    return this;
  }

  public setAutoConnect(autoConnect: boolean) {
    this.mAutoConnect = autoConnect;
    return this;
  }

  public setScanTimeOut(timeOut: number) {
    this.mTimeOut = timeOut;
    return this;
  }

  applyConfig(config: BleScanRuleConfig) {
    config.mServiceUuids = this.mServiceUuids;
    config.mDeviceNames = this.mDeviceNames;
    config.mDeviceMac = this.mDeviceMac;
    config.mAutoConnect = this.mAutoConnect;
    config.mFuzzy = this.mFuzzy;
    config.mScanTimeOut = this.mTimeOut;
  }

  public build(): BleScanRuleConfig {
    let config = new BleScanRuleConfig();
    this.applyConfig(config);
    return config;
  }
}

export default class BleScanRuleConfig {
  public mServiceUuids: UUID[] = [];
  public mDeviceNames: string[] = [];
  public mDeviceMac: string = '';
  public mAutoConnect: boolean = false;
  public mFuzzy: boolean = false;
  public mScanTimeOut: number = 10000;

  public getServiceUuids(): UUID[] {
    return this.mServiceUuids;
  }

  public getDeviceNames(): string[] {
    return this.mDeviceNames;
  }

  public getDeviceMac(): string {
    return this.mDeviceMac;
  }

  public isAutoConnect(): boolean {
    return this.mAutoConnect;
  }

  public isFuzzy(): boolean {
    return this.mFuzzy;
  }

  public getScanTimeOut(): number {
    return this.mScanTimeOut;
  }

  public static Builder = new BleScanRuleConfigBuilder()
}


