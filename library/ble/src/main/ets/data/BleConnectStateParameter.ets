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

export default class BleConnectStateParameter {
    private status: number = 0;
    private isActive_: boolean = false;

    public constructor(status: number) {
        this.status = status;
    }

    public getStatus(): number {
        return this.status;
    }

    public setStatus(status: number) {
        this.status = status;
    }

    public isActive(): boolean  {
        return this.isActive_;
    }

    public setActive(active: boolean) {
        this.isActive_ = active;
    }
}
