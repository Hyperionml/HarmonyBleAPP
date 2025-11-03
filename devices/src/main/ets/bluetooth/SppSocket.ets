import { socket } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

interface IBRSppSocket {
  connect(address: string, uuid: string): Promise<void>;
  isConnected(): boolean;
  read(maxLen: number): Promise<Uint8Array | null>;
  write(data: Uint8Array): Promise<void>;
  close(): Promise<void>;
}

export abstract class BluetoothSocketCallback{
  public abstract onStartConnect: () => void

  public abstract onConnectFail: () => void

  public abstract onConnectSuccess: () => void

  public abstract onDisConnected: () => void

  public abstract onRead :(data: Uint8Array) => void
}

export class SppSocket implements IBRSppSocket {
  private clientNumber: number = -1;
  private connected = false;

  // 简单的事件缓冲队列，read() 可 await 拿到下一段数据
  private queue: Uint8Array[] = [];
  private pendingResolve: ((d: Uint8Array) => void) | null = null;
  private pendingResolves: Array<(d: Uint8Array) => void> = [];//todo 是否需要实现队列模式

  //监听
  private listenerMode = true;
  // private readListener: ((data: Uint8Array) => void) | null = null;
  // public setReadListener(callback: ((data: Uint8Array) => void) | null): void {
  //   this.readListener = callback; // 传null可移除监听
  // }
  //回调
  private callback: BluetoothSocketCallback | null = null;
  public setCallback(callback: BluetoothSocketCallback | null): void {
    this.callback = callback;
  }


  private onRead = (dataBuffer: ArrayBuffer) => {
    const data = new Uint8Array(dataBuffer);

    //优先走监听模式
    if(this.listenerMode && this.callback){
      try { this.callback.onRead(data); } catch (_) {}
      return;
    }

    if (this.pendingResolve) {
      const r = this.pendingResolve;
      this.pendingResolve = null;
      r(data);
    } else {
      this.queue.push(data);
    }
  };

  /**
   * 连接设备
   * @param address
   * @param uuid
   * @param listenerMode
   * @returns
   * */
  async connect(address: string, uuid: string, listenerMode?:boolean): Promise<void> {
    const option: socket.SppOptions = { uuid, secure: false, type: socket.SppType.SPP_RFCOMM };
    this.clientNumber = -1;
    this.connected = false;
    if(listenerMode!=undefined) this.listenerMode = listenerMode
    await new Promise<void>((resolve, reject) => {
      socket.sppConnect(address, option, (err, num: number) => {
        //连接失败
        if (err) {
          const e = err as BusinessError;
          return reject(new Error(`sppConnect failed: ${e.code} ${e.message}`));
        }
        //连接成功
        this.clientNumber = num;
        try {
          socket.on('sppRead', this.clientNumber, this.onRead);
        } catch (err2) {
          const e2 = err2 as BusinessError;
          return reject(new Error(`sppRead on failed: ${e2.code} ${e2.message}`));
        }
        this.connected = true;
        resolve();
      });
    });
  }

  /**
   * getDeviceId方法API17+可用，不一定能用
  */
  // getDeviceId():string | null{
  //   try {
  //     let deviceAddr: string = socket.getDeviceId(this.clientNumber);
  //     return deviceAddr
  //   } catch (err) {
  //     console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
  //     return null
  //   }
  // }

  isConnected(): boolean {
    return this.connected && this.clientNumber !== -1;
  }

  /**
   * 模拟读（并非socket.sppReadAsync，socket.sppReadAsync在BluetoothReader）
   * read()正常情况下会返回一个 Promise<Uint8Array>
   * 但是当this.queue没有数据时，会先缓存resolve到pendingResolve，await被挂起
   * 直到onRead有数据写入时，发现pendingResolve有缓存，会优先把数据写入被挂起的pendingResolve(resolve),await会继续执行
   * */
  async read(maxLen: number): Promise<Uint8Array | null> {
    if (this.listenerMode) return null;
    if (!this.isConnected()) return null;
    // 先用队列，若没有则等待下一帧
    const chunk = await new Promise<Uint8Array>((resolve) => {
      if (this.queue.length > 0) {
        resolve(this.queue.shift()!);//加上!若this.queue.shift()为undefined会抛异常
      } else {
        this.pendingResolve = resolve;
      }
    });
    if (maxLen > 0 && chunk.length > maxLen) {
      return chunk.subarray(0, maxLen);
    }
    return chunk;
  }

  async write(data: Uint8Array): Promise<void> {
    if (!this.isConnected()) throw new Error('spp not connected');
    const buf = data.buffer as ArrayBuffer;
    try {
      socket.sppWrite(this.clientNumber, buf);
    } catch (err) {
      const e = err as BusinessError;
      throw new Error(`sppWrite failed: ${e.code} ${e.message}`);
    }
  }

  /**
   * 关闭连接
   * @returns
   * */
  async close(): Promise<void> {
    if (this.clientNumber === -1) return;
    try {
      socket.off('sppRead', this.clientNumber, this.onRead);
    } catch (_) {}
    try {
      socket.sppCloseClientSocket(this.clientNumber);
    } catch (_) {}
    this.connected = false;
    this.clientNumber = -1;
    this.queue = [];
    this.pendingResolve = null;
    //this.readListener = null;
    this.callback = null;
  }
}