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

export default abstract class BleException {

    private static readonly serialVersionUID = 8004414918500865564;

    public static readonly ERROR_CODE_TIMEOUT = 100;
    public static readonly ERROR_CODE_GATT = 101;
    public static readonly ERROR_CODE_OTHER = 102;

    private code: number;
    private description: string;

    public constructor(code: number, description: string) {
        this.code = code;
        this.description = description;
    }

    public getCode(): number {
        return this.code;
    }

    public setCode(code: number): BleException {
        this.code = code;
        return this;
    }

    public getDescription(): string {
        return this.description;
    }

    public setDescription(description: string): BleException {
        this.description = description;
        return this;
    }

    public toString(): string {
        return "BleException { " +
               "code=" + this.code +
               ", description='" + this.description + '\'' +
               '}';
    }
}
