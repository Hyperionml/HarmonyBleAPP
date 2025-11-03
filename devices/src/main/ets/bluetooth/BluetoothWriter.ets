import { Log } from "common";
import { BusinessError } from "@kit.BasicServicesKit";
import { socket } from '@kit.ConnectivityKit';
const TAG = "DeviceManager";
// const TAG = "BluetoothWriter";
/**
 * 蓝牙数据写入器：通过socket向设备发送数据，是数据输出的通道
 */
export class BluetoothWriter {
  private isWorking : boolean = false;
  private socketNumber : number = -1;
  private callback : IWriteCallback  | null = null;

  constructor(socketNumber: number, callback: IWriteCallback) {
    this.socketNumber = socketNumber;
    this.callback = callback;
  }

  public open():boolean {
    if(!this.isWorking){
      this.isWorking = true;
    }
    return true;
  }

  public close(): boolean{
    if(!this.isWorking){
      this.isWorking = false;
      this.socketNumber = -1;
    }
    return true;
  }

  public async write(block:Uint8Array): Promise<boolean> {
    //代替安卓的Assert断言，使用日志输出错误信息
    if(!block){  //数据不能为空
      Log.e(TAG, 'Data block cannot be null');
      return false;
    }
    if(block.length === 0){  //数据不能为空数组
      Log.e(TAG,'Data block cannot to be empty');
      return false;
    }
    if(!this.isWorking){  //写入器必须启动
      Log.w(TAG,'Writer is not working,cannot write data');
      return false;
    }
    if (this.socketNumber === -1) {  //socket必须有效
      Log.e(TAG, 'Invalid socket number');
      return false;
    }
    //使用socket.sppWrite发送数据
    try {
      await socket.sppWrite(this.socketNumber, block.buffer);
      Log.d(TAG, `Successfully wrote ${block.length} bytes via socket ${this.socketNumber}`);
      this.notifyFinish(block);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      Log.e(TAG, `Write failed: code=${err.code}, message=${err.message}`);
      if(this.isWorking){
        this.notifyError(err)
      }
    }
    return false;
  }

  //发送成功的回调
  private notifyFinish(buff: Uint8Array): void {
    if (this.callback) {
      this.callback.finish(buff);
    }
  }

  //发送失败的回调
  private notifyError(err: BusinessError): void {
    if (this.callback) {
      this.callback.error(err);
    }
  }
}

export interface IWriteCallback {
  finish(buff: Uint8Array): void;
  error(error: BusinessError): void;
}
