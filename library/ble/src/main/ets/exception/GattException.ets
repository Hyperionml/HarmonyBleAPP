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

import BleException from './BleException'

export default class GattException extends BleException {

    private gattStatus: number;

    public constructor(gattStatus: number) {
        super(BleException.ERROR_CODE_GATT, "Gatt Exception Occurred! ");
        this.gattStatus = gattStatus;
    }

    public getGattStatus(): number {
        return this.gattStatus;
    }

    public setGattStatus(gattStatus: number): GattException {
        this.gattStatus = gattStatus;
        return this;
    }

    public toString(): string {
        return "GattException{" +
               "gattStatus=" + this.gattStatus +
               "} " + super.toString();
    }
}
