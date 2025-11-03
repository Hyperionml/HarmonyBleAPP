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

export class BluetoothGattCharacteristic {
    /**
     * Characteristic property: Characteristic is broadcastable.
     */
    public static readonly PROPERTY_BROADCAST = 0x01;

    /**
     * Characteristic property: Characteristic is readable.
     */
    public static readonly PROPERTY_READ = 0x02;

    /**
     * Characteristic property: Characteristic can be written without response.
     */
    public static readonly PROPERTY_WRITE_NO_RESPONSE = 0x04;

    /**
     * Characteristic property: Characteristic can be written.
     */
    public static readonly PROPERTY_WRITE = 0x08;

    /**
     * Characteristic property: Characteristic supports notification
     */
    public static readonly PROPERTY_NOTIFY = 0x10;

    /**
     * Characteristic property: Characteristic supports indication
     */
    public static readonly PROPERTY_INDICATE = 0x20;

    /**
     * Characteristic property: Characteristic supports write with signature
     */
    public static readonly PROPERTY_SIGNED_WRITE = 0x40;

    /**
     * Characteristic property: Characteristic has extended properties
     */
    public static readonly PROPERTY_EXTENDED_PROPS = 0x80;

    /**
     * Characteristic read permission
     */
    public static readonly PERMISSION_READ = 0x01;

    /**
     * Characteristic permission: Allow encrypted read operations
     */
    public static readonly PERMISSION_READ_ENCRYPTED = 0x02;

    /**
     * Characteristic permission: Allow reading with man-in-the-middle protection
     */
    public static readonly PERMISSION_READ_ENCRYPTED_MITM = 0x04;

    /**
     * Characteristic write permission
     */
    public static readonly PERMISSION_WRITE = 0x10;

    /**
     * Characteristic permission: Allow encrypted writes
     */
    public static readonly PERMISSION_WRITE_ENCRYPTED = 0x20;

    /**
     * Characteristic permission: Allow encrypted writes with man-in-the-middle
     * protection
     */
    public static readonly PERMISSION_WRITE_ENCRYPTED_MITM = 0x40;

    /**
     * Characteristic permission: Allow signed write operations
     */
    public static readonly PERMISSION_WRITE_SIGNED = 0x80;

    /**
     * Characteristic permission: Allow signed write operations with
     * man-in-the-middle protection
     */
    public static readonly PERMISSION_WRITE_SIGNED_MITM = 0x100;

    /**
     * Write characteristic, requesting acknowledgement by the remote device
     */
    public static readonly WRITE_TYPE_DEFAULT = 0x02;

    /**
     * Write characteristic without requiring a response by the remote device
     */
    public static readonly WRITE_TYPE_NO_RESPONSE = 0x01;

    /**
     * Write characteristic including authentication signature
     */
    public static readonly WRITE_TYPE_SIGNED = 0x04;

    /**
     * Characteristic value format type uint8
     */
    public static readonly FORMAT_UINT8 = 0x11;

    /**
     * Characteristic value format type uint16
     */
    public static readonly FORMAT_UINT16 = 0x12;

    /**
     * Characteristic value format type uint32
     */
    public static readonly FORMAT_UINT32 = 0x14;

    /**
     * Characteristic value format type sint8
     */
    public static readonly FORMAT_SINT8 = 0x21;

    /**
     * Characteristic value format type sint16
     */
    public static readonly FORMAT_SINT16 = 0x22;

    /**
     * Characteristic value format type sint32
     */
    public static readonly FORMAT_SINT32 = 0x24;

    /**
     * Characteristic value format type sfloat (16-bit float)
     */
    public static readonly FORMAT_SFLOAT = 0x32;

    /**
     * Characteristic value format type float (32-bit float)
     */
    public static readonly FORMAT_FLOAT = 0x34;
}