import { Log } from 'common';
import { socket } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = "BluetoothReader";
/**
 * 蓝牙数据读取器：在蓝牙连接中被动接收并解析特定协议格式的数据包［QTBT帧头］［数据长度］［实际数据］
 * 调用open()注册蓝牙数据接收事件监听，启动数据解析流程
 * 通过监听sppRead事件获取蓝牙数据，所有接收的数据会被拼接到缓冲区中
 * 在缓冲区中循环查找QTBT帧头，找到后读取后续4字节数据长度字段组成8字节完整帧头
 * 解析出数据包总长度totalCount后，从缓冲区读取实际数据（长度=totalCount-8）
 * 当获取完整数据包后，通过回调接口将数据发送给应用层
 * 支持超时控制（帧头解析超时1000ms、数据帧等待超时10000ms），超时后自动清理缓冲区
 */
export class BluetoothReader {
  private static readonly FLAG : Uint8Array = new Uint8Array([81, 84, 66, 84]); //QTBT {'Q','T','B','T'}
  private static readonly SHORT_TIMEOUT : number = 1000; //读取过程中，小的超时
  private static readonly LONG_TIMEOUT : number = 10000; //读取过程中，大的超时
  private static readonly SHORT_SLEEP : number = 10; //短暂休眠时间

  private callback: IReadCallback;
  private isWorking: boolean = false;
  private socketNumber: number | null = null;
  private dataBuffer: Uint8Array = new Uint8Array(0); //用于拼接不完整数据包的缓冲区
  private sppReadListener: ((dataBuffer: ArrayBuffer) => void) | null = null; //用于取消事件监听的引用
  private frameStartTime: number = 0; //记录当前帧的开始解析时间（用于超时控制）

  constructor(socketNumber: number, response: IReadCallback) {
    if (!response) {
      throw new Error('IReadCallback不能为空');
    }
    this.socketNumber = socketNumber;
    this.callback = response;
  }

  public getIsWorking(): boolean {
    return this.isWorking;
  }

  //调用open时，注册事件监听开始接收数据
  public open(): void {
    if (!this.isWorking) {
      this.isWorking = true;
      this.dataBuffer = new Uint8Array(0); //清空缓冲区
      this.registerSppReadListener(); //注册sppRead事件监听
    }
  }

  //关闭读取器并清理资源
  public close(): void {
    try {
      if (this.isWorking) {
        this.isWorking = false;
        this.unregisterSppReadListener(); //取消事件监听
        this.dataBuffer = new Uint8Array(0); //清空缓冲区
      }
    } catch (error) {
      Log.e(TAG, `关闭读取器异常: ${error.message}`);
    }
  }

  //注册sppRead事件监听：数据到达时触发回调
  private registerSppReadListener(): void {
    if (this.socketNumber === null || this.socketNumber === -1) return;

    //确保之前监听器已注销
    this.unregisterSppReadListener();

    //定义数据接收回调函数
    this.sppReadListener = (dataBuffer: ArrayBuffer) => {
      try {
        const newData = new Uint8Array(dataBuffer);
        //将新接收的数据拼接到缓冲区
        this.dataBuffer = this.concatUint8Array(this.dataBuffer, newData);
        //解析缓冲区中的完整数据包
        this.processDataBuffer();
      } catch (error) {
        Log.e(TAG, `sppRead监听回调异常: ${error.message}`);
        this.notifyError(new Error(`数据接收异常: ${error.message}`));
      }
    };

    try {
      //注册事件监听
      socket.on('sppRead', this.socketNumber, this.sppReadListener);
    } catch (err) {
      const error = err as BusinessError;
      Log.e(TAG, `注册sppRead监听失败: code=${error.code}, message=${error.message}`);
      this.notifyError(new Error(`注册监听失败: ${error.message}`));
    }
  }

  //取消sppRead事件监听，避免内存泄漏
  private unregisterSppReadListener(): void {
    if (this.socketNumber === null || this.socketNumber === -1 || !this.sppReadListener) return;

    try {
      socket.off('sppRead', this.socketNumber, this.sppReadListener);
    } catch (err) {
      const error = err as BusinessError;
      Log.e(TAG, `取消sppRead监听失败: code=${error.code}, message=${error.message}`);
    } finally {
      this.sppReadListener = null;
    }
  }

  //处理缓冲区数据：解析完整的数据包
  private processDataBuffer(): void {
    try {
      while (this.isWorking && this.dataBuffer.length > 0) {
        // 1. 查找FLAG标志位（QTBT）
        let fixedCount = 0;　　//当前已成功匹配的字节数（0-4）
        const headStartTime = Date.now(); //记录帧头解析开始时间

        // 循环查找帧头
        while (fixedCount < BluetoothReader.FLAG.length && this.dataBuffer.length > 0) {
          // 检查帧头解析是否超时
          if (Date.now() - headStartTime > BluetoothReader.SHORT_TIMEOUT) {
            Log.w(TAG, "帧头解析超时，重置缓冲区");
            Log.d(TAG, `超时时缓冲区长度: ${this.dataBuffer.length}`);
            if (this.dataBuffer.length > 0) {
              let timeoutBufferStr = "";
              const displayLength = Math.min(this.dataBuffer.length, 30);
              for (let i = 0; i < displayLength; i++) {
                timeoutBufferStr += this.dataBuffer[i].toString(16).padStart(2, '0').toUpperCase() + " ";
              }
              Log.d(TAG, `超时时缓冲区前${displayLength}字节数据: ${timeoutBufferStr}`);
            }
            this.dataBuffer = new Uint8Array(0);
            return;
          }

          const b = this.dataBuffer[0];
          if (b === BluetoothReader.FLAG[fixedCount]) {
            fixedCount++;
            this.dataBuffer = this.dataBuffer.slice(1); //移除已匹配的字节
          } else {
            //如果当前字节匹配新的帧头起始，保留1位，否则清零
            fixedCount = (fixedCount > 0 && b === BluetoothReader.FLAG[0]) ? 1 : 0;
            if (fixedCount === 0) {
              this.dataBuffer = this.dataBuffer.slice(1); //移除不匹配的字节
            }
          }
        }

        //如果未找到完整帧头，退出本轮解析
        if (fixedCount < BluetoothReader.FLAG.length) {
          Log.d(TAG, `未找到完整帧头，当前匹配字节数: ${fixedCount}，缓冲区剩余长度: ${this.dataBuffer.length}`);
          break;
        }

        // 2. 获取数据长度（4字节）
        if (this.dataBuffer.length < 4) {
          Log.d(TAG, `长度字段不足，当前缓冲区长度: ${this.dataBuffer.length}`);
          // 将已匹配的帧头重新放回缓冲区开头
          const tempBuffer = new Uint8Array(fixedCount + this.dataBuffer.length);
          for (let i = 0; i < fixedCount; i++) {
            tempBuffer[i] = BluetoothReader.FLAG[i];
          }
          tempBuffer.set(this.dataBuffer, fixedCount);
          this.dataBuffer = tempBuffer;
          break; // 长度字段不足，等待后续数据
        }

        const lengthBuffer = this.dataBuffer.slice(0, 4); // 提取4字节长度数据
        this.dataBuffer = this.dataBuffer.slice(4); // 从缓冲区移除已读取的长度字段
        const totalCount = this.uint8ToInt(lengthBuffer, 0, 4); // 转换为整数

        Log.d(TAG, `解析到数据包长度: ${totalCount}`);

        //校验总长度合法性
        if (totalCount < BluetoothReader.FLAG.length + 4) { // 至少包含帧头(4)+长度(4)
          Log.w(TAG, `无效的数据包长度: ${totalCount}`);
          continue;
        }

        // 校验长度是否合理
        if (totalCount > 1024 * 1024) { // 限制最大1MB
          Log.w(TAG, `数据包长度过大: ${totalCount}，可能为无效数据`);
          continue;
        }

        // 3. 读取完整数据帧（总长度 - 帧头(4) - 长度(4) = 实际数据长度）
        const dataLength = totalCount - (BluetoothReader.FLAG.length + 4);
        this.frameStartTime = Date.now(); //记录数据帧解析开始时间

        // 如果数据不足，等待后续数据（下次回调时继续解析）
        if (this.dataBuffer.length < dataLength) {
          Log.d(TAG, `数据不足，需要${dataLength}字节，当前只有${this.dataBuffer.length}字节`);
          // 将帧头和长度字段重新放回缓冲区开头
          const tempBuffer = new Uint8Array(BluetoothReader.FLAG.length + 4 + this.dataBuffer.length);
          tempBuffer.set(BluetoothReader.FLAG, 0);
          tempBuffer.set(lengthBuffer, BluetoothReader.FLAG.length);
          tempBuffer.set(this.dataBuffer, BluetoothReader.FLAG.length + 4);
          this.dataBuffer = tempBuffer;

          // 检查是否超时
          if (Date.now() - this.frameStartTime > BluetoothReader.LONG_TIMEOUT) {
            Log.e(TAG, "数据帧解析超时，重置缓冲区");
            Log.d(TAG, `超时时数据帧缓冲区长度: ${this.dataBuffer.length}`);
            this.dataBuffer = new Uint8Array(0);
          }
          break;
        }

        //拼接完整数据包（帧头 + 长度 + 实际数据）
        const block = new Uint8Array(totalCount);
        block.set(BluetoothReader.FLAG, 0); // 填充帧头
        block.set(lengthBuffer, BluetoothReader.FLAG.length); // 填充长度字段
        block.set(this.dataBuffer.slice(0, dataLength), BluetoothReader.FLAG.length + 4); // 填充实际数据

        //完整数据包
        let blockStr = "";
        const blockDisplayLength = Math.min(block.length, 30);
        for (let i = 0; i < blockDisplayLength; i++) {
          blockStr += block[i].toString(16).padStart(2, '0').toUpperCase() + " ";
        }
        Log.d(TAG, `完整数据包前${blockDisplayLength}字节: ${blockStr}`);

        // 从缓冲区移除已解析的数据
        this.dataBuffer = this.dataBuffer.slice(dataLength);

        //通知应用层收到完整数据
        this.notifyRead(block);
      }
    } catch (error) {
      Log.e(TAG, `处理数据缓冲区异常: ${error.message}`);
      //异常时缓冲区内容
      if (this.dataBuffer.length > 0) {
        let errorBufferStr = "";
        const displayLength = Math.min(this.dataBuffer.length, 30);
        for (let i = 0; i < displayLength; i++) {
          errorBufferStr += this.dataBuffer[i].toString(16).padStart(2, '0').toUpperCase() + " ";
        }
        Log.d(TAG, `异常时缓冲区前${displayLength}字节数据: ${errorBufferStr}`);
      }
      this.dataBuffer = new Uint8Array(0); // 出现异常时清空缓冲区
      this.notifyError(new Error(`数据处理异常: ${error.message}`));
    }
  }

  //拼接两个Uint8Array
  private concatUint8Array(a: Uint8Array, b: Uint8Array): Uint8Array {
    const result = new Uint8Array(a.length + b.length);
    result.set(a);
    result.set(b, a.length);
    return result;
  }

  public notifyErrorPublic(err: Error): void {
    this.notifyError(err);
  }

  private notifyRead(block: Uint8Array): void {
    if (this.callback && this.isWorking) {
      this.callback.read(block);  //应用在这里收到数据
    }
  }

  private notifyError(err: Error) {
    if (this.callback && this.isWorking) {
      this.callback.error(err);
    }
  }

  //将字节数组转换成整数，解析数据包的长度：告诉程序接下来还有多少数据要读取
  private uint8ToInt(buffer: Uint8Array, offset: number, length: number): number {
    if (offset + length > buffer.length) {
      return 0;//越界返回0
    }
    let result = 0;
    for (let i = 0; i < length; i++) {
      //已有的数据左移8位（*256） 用合并符号|将新数据拼接到右边，直到将4个单独字节拼成一个完整32位整数
      result = (result << 8) | buffer[offset + i];
    }
    return result;
  }
}

export interface IReadCallback {
  read(buff: Uint8Array): void;
  error(error: Error): void;
}