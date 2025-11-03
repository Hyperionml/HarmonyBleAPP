//官方推荐使用worker，需根据真机情况看是否需要使用worker，现在无法判断
import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS';
import { CameraService, CameraState } from 'cameralib';
import { DecodeBusiness } from '../decoder/DecodeBusiness';
import { image } from '@kit.ImageKit';

let cameraService = new CameraService();
const workerPort: ThreadWorkerGlobalScope = worker.workerPort;

let imageReceiver: image.ImageReceiver;

// 自定义消息格式。
interface MessageInfo {
  hasResolve: boolean;
  type: string;
  context: Context; // 注意worker线程中无法使用getContext()直接获取宿主线程context，需要通过消息从宿主线程通信到worker线程使用。
  surfaceId: string;
  data:PixelMap
}

workerPort.onmessage = async (e: MessageEvents) => {
  const messageInfo: MessageInfo = e.data;
  console.info(`worker onmessage type:${messageInfo.type}`)

  if ('initCamera' === messageInfo.type) {
    // 在worker线程中收到宿主线程初始化相机的消息。
    console.info(`worker initCamera surfaceId:${messageInfo.surfaceId}`)
    // 在worker线程中初始化相机。
    await cameraService.initCamera(messageInfo.context, messageInfo.surfaceId);
  } else if ('releaseCamera' === messageInfo.type) {
    // 在worker线程中收到宿主线程释放相机的消息。
    console.info('worker releaseCamera.');
    // 在worker线程中释放相机。
    await cameraService.releaseCamera();
  } else {
    let size: image.Size = { width: 1080, height: 1980 };
    imageReceiver = image.createImageReceiver(size, image.ImageFormat.JPEG, 8);

    //worker同步调用主线程方法
    let res: string = workerPort.callGlobalCallObjectMethod("DecodeBusiness", "setStatus", 0 ,'CameraState.Init') as string;
    console.info("worker: ", res);
    workerPort.postMessage("run function success.");
  }
};

workerPort.onmessageerror = (event: MessageEvents) => {
};

workerPort.onerror = (event: ErrorEvent) => {
};