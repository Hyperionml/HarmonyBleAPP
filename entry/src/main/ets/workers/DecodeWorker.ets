/**
 * DecodeWorker相当于安卓里 Decoder.java 的“常驻解码线程部分”即：
 * startThread() 启动的 decodeThread
 * while 循环里反复 decode()
 * 以及 getBitmap() 从 AbsCameraReader 取帧
 * */
import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS';
import { AbsCameraReader} from 'cameralib'
import {ImageDataMsg,InitMsg, IsQTMsg, SetParamsMsg, DecodeWorkerMsg, WorkerPostMessageType,WorkerOnMessageType } from '../decoder/DecodeWorkerModel';
import { ZXingDecoder } from '../decoder/ZXingDecoder';
import { sendableImage } from '@kit.ImageKit';
import { Size } from '@kit.ArkUI';
import { Logger } from 'common';
import { TestNapi, Utils } from 'decoder';
import { BaoshenDecoder } from '../decoder/BaoshenDecoder';
import { DecodeResultBean } from '../bean/DecodeResultBean';

const TAG = 'DecodeWorker';
const workerPort: ThreadWorkerGlobalScope = worker.workerPort;
/**
 * 共享内存，实际解码数据
 * */
let sab: SharedArrayBuffer | undefined
let width=0, height=0
let imageSize: Size | undefined
/**
 * decodeLoop循环标记（Stop 置 false）
 * */
let decodeLoopWorking = false
// 添加运行标志,防止 Worker 重复启动decodeLoop()
let decodeLoopRunning = false
/**
 * 是否正在解码（避免并发）
 * */
let isDecoding = false
/**
 * 解码成功后休眠
 * */
let nextAllowedTime = 0
let successSleepTime = 1000

let isQT:boolean = true

//BaoshenDecoder与ZXingDecoder应该写在Worker
const DECODE_INTERVAL_BAOSHEN :number = 0;//宝绅的解码器，尽可能高频率
const DECODE_INTERVAL_ZXING:number = 1000;//ZXing解码，不小那么高的频率

let zxingDecoder: ZXingDecoder;
let baoshenDecoder: BaoshenDecoder;

async function decodeLoop(){
  Logger.warn(TAG, `decodeLoop() 开始运行，isWorking: ${decodeLoopWorking}`);
  let loopCount = 0;
  
  while (decodeLoopWorking) {
    loopCount++;
    
    // 解码成功后暂停一段时间
    if (Date.now() < nextAllowedTime) {
      if (loopCount % 100 === 0) { // 每100次循环打印一次，避免日志过多
        Logger.warn(TAG, `等待解码冷却时间，剩余: ${nextAllowedTime - Date.now()}ms`);
      }
      await new Promise<void>(r => setTimeout(r, 20)); 
      continue;
    }
    
    // 已在解码，稍等
    if (isDecoding) {
      if (loopCount % 50 === 0) { // 每50次循环打印一次
        Logger.warn(TAG, `正在解码中，等待完成...`);
      }
      await new Promise<void>(r => setTimeout(r, 10)); 
      continue;
    }

    //只读处理最新帧
    const frameHandler = AbsCameraReader.readLatestForWorker(sab)
    // 未读到数据暂停一段时间，相当于Thread.yield();
    if (!frameHandler) {
      if (loopCount % 200 === 0) { // 每200次循环打印一次
        Logger.warn(TAG, `未读取到帧数据，继续等待...`);
      }
      await new Promise<void>(r => setTimeout(r, 20));
      continue;
    }

    //----------解码中----------
    isDecoding = true;
    const decodeStartTime = Date.now();

    //图片数据
    const frame = frameHandler.buffer;
    Logger.warn(TAG, `读取到帧数据，大小: ${frame.byteLength} 字节，开始解码...`);

    // ljj 测试代码，直接返回到主界面显示图片，（2025年9月16日 10:44:51测试界面显示正常）
    // workerPort?.postMessage({ type: WorkerOnMessageType.Frame,frame });

    //解码
    let result:DecodeResultBean | null =null;
    try{
      if(isQT) {
        Logger.warn(TAG, `使用 QT 解码器，图像尺寸: ${width}x${height}`);
        const uint8Array = new Uint8Array(frame.buffer, frame.byteOffset, frame.byteLength)
        result = baoshenDecoder.decode(uint8Array, width, height)
      }
      else{
        Logger.warn(TAG, `使用 ZXing 解码器，图像尺寸: ${width}x${height}`);
        const pixels32 = new Int32Array(frame.buffer, frame.byteOffset, frame.byteLength >>> 2)
        result = zxingDecoder.decode(pixels32, width, height)
      }

      const decodeTime = Date.now() - decodeStartTime;

      if(result){
        const success = result.IsSuccess();
        const code = success ? result.getCode() : 'N/A';
        Logger.warn(TAG, `Baoshen/ZXing 解码完成: ${success} ${success ? '成功' : '失败'}, 耗时: ${decodeTime}ms${success ? `, 内容: ${code}` : ''}`);

        if (result.IsSuccess()) {
          //成功才发消息到主线程
          workerPort?.postMessage({
            type: WorkerOnMessageType.DecodeResult,
            ok: result.IsSuccess(),
            data: result.toPlainObject()
          })
          nextAllowedTime = Date.now() + successSleepTime;
          Logger.warn(TAG, `Baoshen/ZXing 解码成功，设置冷却时间: ${successSleepTime}ms`);
        }
      } else {
        Logger.warn(TAG, `Baoshen/ZXing 解码失败返回: ${result}，耗时: ${decodeTime}ms`);
      }
    }
    catch (error) {
      const decodeTime = Date.now() - decodeStartTime;
      Logger.error(TAG, `解码过程中发生异常，耗时: ${decodeTime}ms, 错误: ${error}`);
    }
    finally {
      //frameHandler处理完成
      frameHandler.commit();
      isDecoding = false;
    }
    //----------解码结束----------
  }
  
  Logger.warn(TAG, `decodeLoop() 结束，总循环次数: ${loopCount}`);
}

function runDecodeLoop(){
  //直接启动解码循环
  decodeLoopWorking = true;
  decodeLoopRunning = true;
  Logger.warn(TAG, `启动解码循环，isWorking: ${decodeLoopWorking}`);
  decodeLoop().finally(() => {
    decodeLoopRunning = false;
  });
  //向主线程报告状态是否decodeLoopWorking=true
  workerPort.postMessage({
    type: WorkerOnMessageType.StateChanged,
    isWorking: decodeLoopWorking
  });
}

workerPort.onmessage = (event: MessageEvents) => {
  const msg : DecodeWorkerMsg = event.data
  Logger.warn(TAG, `收到消息: ${msg?.type}`);
  
  switch (msg?.type){
    case WorkerPostMessageType.Init:{
      Logger.warn(TAG, `收到初始化消息`);
      let m = msg as InitMsg
      sab = m.sab as SharedArrayBuffer; 
      width = m.width; 
      height = m.height;
      successSleepTime = m.successSleepTime;
      
      Logger.warn(TAG, `初始化参数: width=${width}, height=${height}, successSleepTime=${successSleepTime}`);
      Logger.warn(TAG, `SharedArrayBuffer 大小: ${sab?.byteLength} 字节`);

      // 清空SharedArrayBuffer中的旧数据
      AbsCameraReader.clearAllSlotsForWorker(sab);
      Logger.warn(TAG, `Worker初始化时清空AbsCameraReader的SharedArrayBuffer中的旧数据 clearAllSlotsForWorker()`);
      
      if (!baoshenDecoder) {
        baoshenDecoder = new BaoshenDecoder(DECODE_INTERVAL_BAOSHEN);
        baoshenDecoder.setDecodeImageSize({ width:width,height:height })
      }
      
      //Zxing
      if (!zxingDecoder) {
        Logger.warn(TAG, `创建 ZXing 解码器，间隔: ${DECODE_INTERVAL_ZXING}ms`);
        zxingDecoder = new ZXingDecoder(DECODE_INTERVAL_ZXING);
      } else {
        Logger.warn(TAG, `ZXing 解码器已存在，跳过创建`);
      }
      
      Logger.warn(TAG, `Worker 初始化完成，发送 WorkerReady 消息`);
      workerPort?.postMessage({ type: WorkerOnMessageType.WorkerReady });

      //开启循环解码
      runDecodeLoop()
      break;
    }
    case WorkerPostMessageType.Start:{
      Logger.warn(TAG, `收到启动解码消息，当前 isWorking: ${decodeLoopWorking}`);
      if (!decodeLoopWorking && !decodeLoopRunning) {
        //开启循环解码
        runDecodeLoop()
      } else {
        Logger.warn(TAG, `解码循环已在运行，跳过重复启动`);
      }
      break;
    }
    case WorkerPostMessageType.Stop:{
      Logger.warn(TAG, `收到停止解码消息，当前 isWorking: ${decodeLoopWorking}`);
      decodeLoopWorking = false;
      // 向主线程报告状态是否decodeLoopWorking=false
      workerPort.postMessage({
        type: WorkerOnMessageType.StateChanged,
        isWorking: decodeLoopWorking
      });

      // 在重新启动时也清空一次数据，确保没有旧数据
      AbsCameraReader.clearAllSlotsForWorker(sab);
      Logger.warn(TAG, `Worker停止时清空AbsCameraReader的SharedArrayBuffer中的旧数据 clearAllSlotsForWorker()`);

      Logger.warn(TAG, `解码循环已停止，isWorking: ${decodeLoopWorking}`);
      break;
    }
    case WorkerPostMessageType.IsQT:{
      Logger.warn(TAG, `收到解码器切换消息`);
      let m = msg as IsQTMsg
      const oldIsQT = isQT;
      isQT = m.isQT;
      Logger.warn(TAG, `解码器切换: ${oldIsQT ? 'QT' : 'ZXing'} -> ${isQT ? 'QT' : 'ZXing'}`);
      break;
    }
    case WorkerPostMessageType.SetParams:{
      Logger.warn(TAG, `收到参数设置消息`);
      let m = msg as SetParamsMsg
      imageSize = m.imageSize;
      const orientation = m.screenOrientation;
      Logger.warn(TAG, `设置参数: imageSize=${imageSize.width}x${imageSize.height}, orientation=${orientation}`);
      baoshenDecoder.setDecodeImageSize({ width:imageSize.width,height:imageSize.height })
      break;
    }
    //测试直接解码sendableImage.PixelMap
    case WorkerPostMessageType.ImageData:{
      Logger.warn(TAG, `收到 sendableImage.PixelMap 解码消息`);
      let m = msg as ImageDataMsg
      QRCodeDecode(m.data);
      break;
    }
    default:
      Logger.error(TAG, `收到未知消息类型`);
      break;
  }
};

//测试直接解码sendableImage.PixelMap
async function QRCodeDecode(pixelMap: sendableImage.PixelMap){
  Logger.warn(TAG, `QRCodeDecode() 开始处理 sendableImage.PixelMap`);

  try {
    const startTime = Date.now();
    
    let num = pixelMap.getPixelBytesNumber();
    Logger.warn(TAG, `PixelMap 字节数: ${num}`);
    
    let arrayBuffer: ArrayBuffer = new ArrayBuffer(num);
    await pixelMap.readPixelsToBuffer(arrayBuffer);
    
    const readTime = Date.now();
    Logger.warn(TAG, `读取像素数据耗时: ${readTime - startTime}ms`);
    
    const int32Array = new Int32Array(arrayBuffer);
    Logger.warn(TAG, `转换为 Int32Array，长度: ${int32Array.length}`);
    
    Logger.warn(TAG, `开始 ZXing 解码，图像尺寸: ${width}x${height}`);

    const result = zxingDecoder.decode(int32Array, width, height);

    const decodeTime = Date.now();
    const totalTime = decodeTime - startTime;
    const success = result?.IsSuccess() || false;
    const code = success ? result!.getCode() : 'N/A';

    Logger.warn(TAG, `sendableImage.PixelMap 解码完成: ${success ? '成功' : '失败'}, 总耗时: ${totalTime}ms${success ? `, 内容: ${code}` : ''}`);

    workerPort?.postMessage({
      type: WorkerOnMessageType.DecodeResult,
      ok: success,
      data: result?.toPlainObject()
    });

  } catch (error) {
    Logger.error(TAG, `QRCodeDecode() 发生异常: ${error}`);
    workerPort?.postMessage({ 
      type: WorkerOnMessageType.DecodeResult, 
      ok: false, 
      data: null 
    });
  }
}

workerPort.onmessageerror = (event: MessageEvents) => {
  Logger.error(TAG, `Worker 消息错误: ${JSON.stringify(event)}`);
};

workerPort.onerror = (event: ErrorEvent) => {
  Logger.error(TAG, `Worker 运行时错误: ${event.message}, 文件: ${event.filename}, 行: ${event.lineno}`);
};