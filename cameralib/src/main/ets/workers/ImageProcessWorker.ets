import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS';
import { AbsCameraReader } from '../AbsCameraReader';
import { PixelMapFrameProducer } from '../PixelMapFrameProducer';
import { sendableImage } from '@kit.ImageKit';
import { ImageProcessMessageType, ImageProcessMsg, ImageProcessStatus, InitMsg } from '../ImageProcessWorkerModel';

const workerPort: ThreadWorkerGlobalScope = worker.workerPort;
let mReader: AbsCameraReader ;
let mFrameProducer: PixelMapFrameProducer ;
let status :ImageProcessStatus= ImageProcessStatus.None;

async function initializeReader(imageData:sendableImage.PixelMap,maxImageCount:number, cameraOrientation:number,  isFront:boolean) {
  const info = imageData.getImageInfoSync()
  let imageWidth:number = info.size.width,  imageHeight:number =info.size.height,  format = info.pixelFormat,
  // 在ImageProcessWorker中创建AbsCameraReader
  mReader = AbsCameraReader.getInstance(imageWidth,imageHeight,format,maxImageCount,cameraOrientation,isFront);
  if(!mFrameProducer || mReader.consumeChanged()){
    mFrameProducer = new PixelMapFrameProducer(mReader);
  }
  // 返回SharedArrayBuffer给主线程，再转发给DecodeWorker
  workerPort.postMessage({
    type: 'SAB_READY',
    sab: mReader.exportSharedBuffer()
  })
  status = ImageProcessStatus.Initted
  write(imageData);
}

// ljj 参数配置可以用同步方式在主线程获取

// 向SharedBuffer写入数据，供解码Worker使用，该数据为处理完的buffer（现在暂时直接用图片数据）
async function write(pixelMap:sendableImage.PixelMap) {
  mFrameProducer?.onFrame(pixelMap)
  status = ImageProcessStatus.Initted
}

workerPort.onmessage = (event: MessageEvents) => {
  const msg : ImageProcessMsg = event.data
  //
  switch (msg?.type){
    //初始化
    case ImageProcessMessageType.Init:{
      let m = msg as InitMsg
      initializeReader(m.imageData, m.maxImageCount, m.cameraOrientation, m.isFront)
      break;
    }
  }
};
workerPort.onmessageerror = (event: MessageEvents) => {
};
workerPort.onerror = (event: ErrorEvent) => {
};