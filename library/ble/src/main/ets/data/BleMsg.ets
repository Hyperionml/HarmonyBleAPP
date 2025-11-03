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

export default class BleMsg {
    // Scan
    public static readonly MSG_SCAN_DEVICE: number = 0X00;

    // Connect
    public static readonly MSG_CONNECT_FAIL: number = 0x01;
    public static readonly MSG_DISCONNECTED: number = 0x02;
    public static readonly MSG_RECONNECT: number = 0x03;
    public static readonly MSG_DISCOVER_SERVICES: number = 0x04;
    public static readonly MSG_DISCOVER_FAIL: number = 0x05;
    public static readonly MSG_DISCOVER_SUCCESS: number = 0x06;
    public static readonly MSG_CONNECT_OVER_TIME: number = 0x07;

    // Notify
    public static readonly MSG_CHA_NOTIFY_START: number = 0x11;
    public static readonly MSG_CHA_NOTIFY_RESULT: number = 0x12;
    public static readonly MSG_CHA_NOTIFY_DATA_CHANGE: number = 0x13;
    public static readonly KEY_NOTIFY_BUNDLE_STATUS: string = "notify_status";
    public static readonly KEY_NOTIFY_BUNDLE_VALUE: string = "notify_value";

    // Indicate
    public static readonly MSG_CHA_INDICATE_START: number = 0x21;
    public static readonly MSG_CHA_INDICATE_RESULT: number = 0x22;
    public static readonly MSG_CHA_INDICATE_DATA_CHANGE: number = 0x23;
    public static readonly KEY_INDICATE_BUNDLE_STATUS: string = "indicate_status";
    public static readonly KEY_INDICATE_BUNDLE_VALUE: string = "indicate_value";

    // Write
    public static readonly MSG_CHA_WRITE_START: number = 0x31;
    public static readonly MSG_CHA_WRITE_RESULT: number = 0x32;
    public static readonly MSG_SPLIT_WRITE_NEXT: number = 0x33;
    public static readonly KEY_WRITE_BUNDLE_STATUS: string = "write_status";
    public static readonly KEY_WRITE_BUNDLE_VALUE: string = "write_value";

    // Read
    public static readonly MSG_CHA_READ_START: number = 0x41;
    public static readonly MSG_CHA_READ_RESULT: number = 0x42;
    public static readonly KEY_READ_BUNDLE_STATUS: string = "read_status";
    public static readonly KEY_READ_BUNDLE_VALUE: string = "read_value";

    // Rssi
    public static readonly MSG_READ_RSSI_START: number = 0x51;
    public static readonly MSG_READ_RSSI_RESULT: number = 0x52;
    public static readonly KEY_READ_RSSI_BUNDLE_STATUS: string = "rssi_status";
    public static readonly KEY_READ_RSSI_BUNDLE_VALUE: string = "rssi_value";

    // Mtu
    public static readonly MSG_SET_MTU_START: number = 0x61;
    public static readonly MSG_SET_MTU_RESULT: number = 0x62;
    public static readonly KEY_SET_MTU_BUNDLE_STATUS: string = "mtu_status";
    public static readonly KEY_SET_MTU_BUNDLE_VALUE: string = "mtu_value";
}
