
import { ErrorEvent, MessageEvents, worker } from '@kit.ArkTS';
import { DecoderCameraParameters, RectLike } from './DecoderCameraParameters';
import { DecodeResultBean } from '../bean/DecodeResultBean';
import { AbsCameraReader } from 'cameralib';
import { InitMsg, IsQTMsg, DecodeResultMsg,
  SetParamsMsg,
  WorkerOnMessageType, WorkerPostMessageType,
  SwitchMsg,
  ImageDataMsg} from './DecodeWorkerModel';
import { sendableImage } from '@kit.ImageKit';
import { Logger } from 'common';

export interface OnDecodeResult {
  onDecoded:(result:DecodeResultBean, ok:boolean) => void;
  onWorkerError:(error:ErrorEvent)=> void;
  onWorkerInitted:() => void;
  onHandleFrame:(frame:Uint8Array) => void;
}
const TAG = 'Decoder'

// 状态名称映射，用于日志输出
const STATE_NAMES = ['STOP','WAIT','DECODING','IDLE']
/**
 *
 *  - 鸿蒙的Decoder与DecoderWorker是一体的，共同构成安卓的Decoder.java
 *
 │  - 管理BaoshenDecoder和ZXingDecoder
 │  - 控制解码线程的启动和停止
 │  - 处理图像数据并分发给具体解码器
 │  - 通过OnDecodeResult回调返回解码结果
 *
 * 现在的流程为:
 * 1.start(callback) - 设置回调
 * 2.decode(reader) - 第一次调用时创建Worker，后续调用直接解码
 * 3.Worker自动处理解码循环
 * 4.stop() - 停止解码
 */
export class Decoder {
  private static instance: Decoder;
  private IsQTCode:boolean = true;
  private callback :OnDecodeResult|null = null;

  static readonly STATE_STOP = 0;     //初始状态，未开启线程
  static readonly STATE_WAIT = 1;     //等待解码结果
  static readonly STATE_DECODING = 2; //解码中
  static readonly STATE_IDLE = 3;     //闲置状态，没有要解码的数据
  private state = Decoder.STATE_STOP;

  private workerInstance: worker.ThreadWorker|null = null;
  private isWorkerInitialized = false; //Worker是否已初始化
  private isStart = false
  public getIsStart():boolean { return this.isStart;}
  private params?: DecoderCameraParameters
  private successSleepTime: number;
  private mReader: AbsCameraReader|null = null;
  private parameters: DecoderCameraParameters| null = null;
  private mImageCrop:RectLike|null = null;
  private mScreenOrientation: number = -1;

  constructor(successSleepTime:number) {
    this.successSleepTime = successSleepTime;
    Logger.info(TAG, `构造函数调用，successSleepTime: ${successSleepTime}`);

    this.createWorker();
    Logger.info(TAG, `首次启动，初始化 Worker`);
  }

  // 状态变更日志方法
  private changeState(newState: number, reason: string = '') {
    const oldStateName = STATE_NAMES[this.state] || 'UNKNOWN';
    const newStateName = STATE_NAMES[newState] || 'UNKNOWN';
    Logger.info(TAG, `状态变更: ${oldStateName} -> ${newStateName}${reason ? ` (${reason})` : ''}`);
    this.state = newState;
  }

  public static getInstance():Decoder{
    if (Decoder.instance == null) {
      Logger.info(TAG, `创建新的 Decoder 实例`);
      Decoder.instance = new Decoder(1000);
    } else {
      Logger.debug(TAG, `返回已存在的 Decoder 实例`);
    }
    return Decoder.instance;
  }

  /**
   * 绑定解码结果回调 - 对应安卓的 start()
   * 只设置回调和启动标志
   */
  start(callback: OnDecodeResult) {
    Logger.info(TAG, `start() 调用开始`);
    this.callback = callback;
    this.isStart = true;
    this.changeState(Decoder.STATE_STOP, 'start() 调用，等待decode()触发');
    Logger.info(TAG, `start() 调用完成，isStart: ${this.isStart}`);
  }

  stop() {
    Logger.info(TAG, `stop() 调用开始`);
    const initMessage: SwitchMsg = { type: WorkerPostMessageType.Stop }
    this.workerInstance?.postMessage(initMessage);
    this.isStart = false;
    this.changeState(Decoder.STATE_STOP, 'stop() 调用');
    Logger.info(TAG, `stop() 调用完成，isStart: ${this.isStart}`);
  }

  releaseWorker(){
    this.isStart = false;
    Logger.info(TAG, `releaseWorker() 调用开始，isWorkerInitialized: ${this.isWorkerInitialized}`);
    this.isWorkerInitialized = false;
    this.changeState(Decoder.STATE_STOP, 'Worker错误');
    try {
      this.workerInstance?.terminate();
      Logger.info(TAG, `Worker terminate 成功`);
    } catch (e) {
      Logger.error(TAG, `Worker terminate 失败: ${e}`);
    }
    this.workerInstance = null;
    Logger.info(TAG, `releaseWorker() 调用完成`);
  }

  //不再需要reStartWorker，会在下次decode时重建worker
  reStartWorker(){}

  private createWorker() {
    Logger.info(TAG, `initWorker() 开始初始化 Worker`);
    this.workerInstance = new worker.ThreadWorker('entry/ets/workers/DecodeWorker.ets', { name: 'DecodeWorker' });

    // 设置消息处理
    this.workerInstance.onmessage = (e) => {
      this.handleWorkerMessage(e);
    };
    
    this.workerInstance.onerror = (err: ErrorEvent) =>{
      Logger.error(TAG, `Worker 错误: ${err.message}, 文件: ${err.filename}, 行: ${err.lineno}`);
      this.releaseWorker()
      this.callback?.onWorkerError(err)
    }
    Logger.info(TAG, `initWorker() Worker 初始化完成`);
  }

  /**
   * 处理Worker消息
   */
  private handleWorkerMessage(e: MessageEvents) {
    const message: DecodeResultMsg = e.data;
    Logger.debug(TAG, `收到 Worker 消息: ${message.type}`);

    switch (message.type) {
      case WorkerOnMessageType.DecodeResult:
        const success = message.ok;
        let result = DecodeResultBean.fromPlainObject(message.data)
        const code = success ? result.getCode() : 'N/A';
        Logger.info(TAG, `ZXing 解码结果: ${success ? '成功' : '失败'}${success ? `, 内容: ${code}` : ''}`);

        // 解码完成，转为空闲
        this.changeState(Decoder.STATE_DECODING, '解码完成');

        //解码结果回调
        this.callback?.onDecoded(result, message.ok);
        break;
      case WorkerOnMessageType.WorkerReady:
        this.isWorkerInitialized = true;
        Logger.info(TAG, `Worker 初始化完成，isWorkerInitialized: ${this.isWorkerInitialized}`);
        //初始化完成回调
        this.callback?.onWorkerInitted()
        break;
      case WorkerOnMessageType.StateChanged:
        // 在主线程监听状态变化
        if(this.isStart && message.isWorking){
          this.changeState(Decoder.STATE_DECODING, 'Worker状态同步');
        }
        else
        {
          this.changeState(Decoder.STATE_STOP, 'Worker状态同步');
        }
        Logger.info(TAG, `Worker 状态已变更，isWorking: ${message.isWorking}`);
        break;
      case WorkerOnMessageType.Frame:
        //测试代码，直接处理返回的视频帧数据，显示在界面上
        this.callback?.onHandleFrame(message.frame);
        Logger.info(TAG, `收到Worker的Frame`);
        break;
      default:
        Logger.error(TAG, `收到未知的 Worker 消息类型: ${message.type}`);
    }
  }

  /**
   * 确保Worker准备就绪
   */
  private ensureWorkerReady() :boolean{
    Logger.debug(TAG, `ensureWorkerReady() 检查Worker状态`);

    // 1. 如果Worker不存在，创建它
    if (!this.workerInstance) {
      Logger.info(TAG, `创建新的Worker实例`);
      this.createWorker();
    }

    // 2. 如果Worker未创建
    // if (!this.isWorkerCreated) {
    //   Logger.info(TAG, `Worker未创建，请Create`);
    //   return false
    // }

    if (!this.mReader) {
      Logger.error(TAG, `无法初始化Worker: mReader 为 null`);
      return false;
    }

    if (!this.parameters) {
      Logger.error(TAG, `无法初始化Worker: parameters 为 null，暂时跳过检查`);
      // 暂时跳过parameters检查，但记录警告
    }

    // 准备就绪，可以发送初始化消息
    Logger.info(TAG, `Worker初始化条件满足，准备发送初始化消息`);
    return true;
  }

  /**
   * 保存最新的 AbsCameraReader，若 Worker 未启动则启动解码线程
   * 对应安卓的 decode(AbsCameraReader reader)
   */
  decode(reader: AbsCameraReader): boolean {
    Logger.debug(TAG, `decode() 调用开始，当前状态: ${STATE_NAMES[this.state]}, isStart: ${this.isStart}`);

    // 检查是否允许解码
    if (!this.isStart) {
      Logger.error(TAG, `decode() 失败: isStart 为 false`);
      return false;
    }

    // 保存最新的 reader
    this.mReader = reader;
    Logger.debug(TAG, `decode() mReader 已更新`);

    if (this.state == Decoder.STATE_STOP || this.state == Decoder.STATE_IDLE) {
      // 懒加载：确保Worker准备就绪
      if(!this.ensureWorkerReady()) return false;
      // 发起解码请求
      this.requestDecode();
    }

    Logger.debug(TAG, `decode() 调用完成，返回 true`);
    return true;
  }

  /**
   * 发起解码请求
   */
  private requestDecode() {
    Logger.debug(TAG, `requestDecode() 发起解码请求`);

    if (!this.workerInstance) {
      Logger.error(TAG, `无法发起解码: Worker未创建`);
      return;
    }

    if (!this.mReader) {
      Logger.error(TAG, `无法发起解码: mReader为null`);
      return;
    }

    // 根据Worker状态发送不同消息
    if (!this.isWorkerInitialized) {
      // 发送初始化消息（会自动启动解码循环）
      this.sendInitMessage();
      //不主动改变状态，等待Worker同步
      //this.changeState(Decoder.STATE_WAIT, '发送初始化+解码请求');
    } else {
      // 发送启动消息
      this.workerInstance.postMessage({ type: WorkerPostMessageType.Start });
      //不主动改变状态，等待Worker同步
      //this.changeState(Decoder.STATE_WAIT, '发送解码请求');
    }
  }

  /**
   * 发送初始化消息
   */
  private sendInitMessage() {
    const sab = this.mReader!.exportSharedBuffer();
    const initMessage: InitMsg = {
      type: WorkerPostMessageType.Init,
      sab: sab,
      width: this.mReader!.getWidth(),
      height: this.mReader!.getHeight(),
      format: this.mReader!.getImageFormat(),
      imageSize: this.parameters?.getImageSize(),
      screenOrientation: this.parameters?.getScreenOrientation(),
      successSleepTime: this.successSleepTime
    };

    Logger.info(TAG, `发送初始化消息: width=${initMessage.width}, height=${initMessage.height}, format=${initMessage.format}`);
    this.workerInstance!.postMessage(initMessage);
  }

  public setIsQTCode(isQT:boolean) {
    Logger.info(TAG, `setIsQTCode() 调用: ${this.IsQTCode} -> ${isQT}`);
    this.IsQTCode = isQT;
    //发送到worker
    const msg: IsQTMsg = { type: WorkerPostMessageType.IsQT, isQT };
    this.workerInstance?.postMessage(msg);
    Logger.debug(TAG, `setIsQTCode() 消息已发送到 Worker`);
  }

  setDecoderCameraParameters(parameters: DecoderCameraParameters): void {
    Logger.info(TAG, `setDecoderCameraParameters() 调用`);
    this.parameters = parameters;
    this.mImageCrop = parameters.getImageCrop();
    this.mScreenOrientation = parameters.getScreenOrientation();

    const imageSize = parameters.getImageSize();
    const orientation = parameters.getScreenOrientation();
    Logger.debug(TAG, `参数设置: imageSize=${imageSize.width}x${imageSize.height}, orientation=${orientation}`);

    // 发送参数更新到 Worker
    if (this.isWorkerInitialized) {
      Logger.info(TAG, `Worker 已初始化，发送参数更新消息`);
      const msg: SetParamsMsg = {
        type: WorkerPostMessageType.SetParams,
        imageSize: parameters.getImageSize(),
        screenOrientation: parameters.getScreenOrientation()
      };
      this.workerInstance?.postMessage(msg);
      Logger.debug(TAG, `参数更新消息已发送到 Worker`);
    } else {
      Logger.debug(TAG, `Worker 未初始化，参数将在初始化时发送`);
    }
  }

  //测试方法
  postMessageWithSharedSendable(image: sendableImage.PixelMap){
    // 确保Worker准备就绪
    this.ensureWorkerReady()
    Logger.debug(TAG, `postMessageWithSharedSendable() 调用，发送 sendableImage.PixelMap 到 Worker`);
    const imageDataMessage:ImageDataMsg = {
      type: WorkerPostMessageType.ImageData,
      data: image
    };
    this.workerInstance?.postMessageWithSharedSendable(imageDataMessage);
    Logger.debug(TAG, `postMessageWithSharedSendable() sendableImage.PixelMap 消息已发送`);
  }
}