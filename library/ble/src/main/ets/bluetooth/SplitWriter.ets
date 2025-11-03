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
import BleWriteCallback from '../callback/BleWriteCallback';
import BleMsg from '../data/BleMsg';
import BleException from '../exception/BleException';
import OtherException from '../exception/OtherException';
import BleLog from '../utils/BleLog';
import { Handler, Message } from '../utils/Handler';
import { Queue } from '../utils/Queue'

type byte = number;

/**
 * 大数据分包写入器
 * 支持顺序传输和并发传输两种模式
 */
export default class SplitWriter {
  private mHandler: Handler | null = null;
  private mBleBluetooth: BleBluetooth | null = null;
  private mUuid_service: string = '';
  private mUuid_write: string = '';
  private mData: Uint8Array = new Uint8Array();
  private mCount: number = 0;
  private mSendNextWhenLastSuccess: boolean = false;
  private mIntervalBetweenTwoPackage: number = 0;
  private mCallback: BleWriteCallback | null = null;
  private mDataQueue: Queue<Uint8Array> = new Queue();
  private mTotalNum: number = 0;

  public constructor() {
    let _this = this;
    this.mHandler = new TempHandler(_this);
  }

  /**
   * 将大数据分解为多个小包逐个发送
   */
  public splitWrite(bleBluetooth: BleBluetooth,
                    uuid_service: string,
                    uuid_write: string,
                    data: Uint8Array,
                    sendNextWhenLastSuccess: boolean,
                    intervalBetweenTwoPackage: number,
                    callback: BleWriteCallback): void {
    this.mBleBluetooth = bleBluetooth;
    this.mUuid_service = uuid_service;
    this.mUuid_write = uuid_write;
    this.mData = data;
    this.mSendNextWhenLastSuccess = sendNextWhenLastSuccess;
    this.mIntervalBetweenTwoPackage = intervalBetweenTwoPackage;
    this.mCount = BleManager.getInstance().getSplitWriteNum();
    this.mCallback = callback;

    this.splitWriteInternal();
  }

  private splitWriteInternal(): void {
    if (this.mData == null) {
      throw new EvalError("data is Null!");
    }
    if (this.mCount < 1) {
      throw new EvalError("split count should higher than 0!");
    }
    this.mDataQueue = SplitWriter.splitByte(this.mData, this.mCount);
    this.mTotalNum = this.mDataQueue.size();
    this.write();
  }

  private write(): void {
    if (this.mDataQueue.peek() == null) {
      this.release();
      return;
    }

    let _this = this;
    let data: Uint8Array | undefined = this.mDataQueue.poll();
    if (data !== undefined) {
      this.mBleBluetooth?.newBleConnector()
        .withUUIDString(this.mUuid_service, this.mUuid_write)
        .writeCharacteristic(
          data,
          new TempBleWriteCallback(_this),
          _this.mUuid_write);
    }

    if (!_this.mSendNextWhenLastSuccess && _this.mHandler !== null) {
      let message = _this.mHandler.obtainMessage(BleMsg.MSG_SPLIT_WRITE_NEXT);
      _this.mHandler.sendMessageDelayed(message, _this.mIntervalBetweenTwoPackage);
    }
  }

  private release(): void {
    if (this.mHandler !== null) {
      this.mHandler.removeAllMessage();
    }
  }

  private static splitByte(data: Uint8Array, count: number): Queue<Uint8Array> {
    if (count > 20) {
      BleLog.w("Be careful: split count beyond 20! Ensure MTU higher than 23!");
    }
    let byteQueue: Queue<Uint8Array> = new Queue();
    let pkgCount: number;
    if (data.length % count == 0) {
      pkgCount = data.length / count;
    } else {
      pkgCount = Math.round(data.length / count + 1);
    }

    if (pkgCount > 0) {
      for (let i = 0; i < pkgCount; i++) {
        let dataPkg: Uint8Array = new Uint8Array();
        let j: number;
        if (pkgCount == 1 || i == pkgCount - 1) {
          j = data.length % count == 0 ? count : data.length % count;
          dataPkg = new Uint8Array(j);
          SplitWriter.arrayCopy(data, i * count, dataPkg, 0, j);
        } else {
          dataPkg = new Uint8Array(count);
          SplitWriter.arrayCopy(data, i * count, dataPkg, 0, count);
        }
        byteQueue.offer(dataPkg);
      }
    }
    return byteQueue;
  }

  static arrayCopy(src: Uint8Array, srcPos: number, dest: Uint8Array, destPos: number, length: number): void {
    for (let i = 0; i < length; i++) {
      dest[destPos + i] = src[srcPos + i];
    }
  }
}

class TempHandler extends Handler {
  root: ESObject

  constructor(root: ESObject) {
    super();
    this.root = root
  }

  public handleMessage(msg: Message): void {
    if (msg.what == BleMsg.MSG_SPLIT_WRITE_NEXT) {
      this.root.write();
    }
  }
}

class TempBleWriteCallback extends BleWriteCallback {
  root: ESObject

  constructor(root: ESObject) {
    super();
    this.root = root
  }

  public onWriteSuccess(current: number, total: number, justWrite: Uint8Array): void {
    let position = this.root.mTotalNum - this.root.mDataQueue.size();
    if (this.root.mCallback != null) {
      this.root.mCallback.onWriteSuccess(position, this.root.mTotalNum, justWrite);
    }
    if (this.root.mSendNextWhenLastSuccess) {
      let message: Message = this.root.mHandler.obtainMessage(BleMsg.MSG_SPLIT_WRITE_NEXT);
      this.root.mHandler.sendMessageDelayed(message, this.root.mIntervalBetweenTwoPackage);
    }
  }

  public onWriteFailure(exception: BleException): void {
    if (this.root.mCallback != null) {
      this.root.mCallback.onWriteFailure(new OtherException("exception occur while writing: " + exception.getDescription()));
    }
    if (this.root.mSendNextWhenLastSuccess) {
      let message: Message = this.root.mHandler.obtainMessage(BleMsg.MSG_SPLIT_WRITE_NEXT);
      this.root.mHandler.sendMessageDelayed(message, this.root.mIntervalBetweenTwoPackage);
    }
  }
}