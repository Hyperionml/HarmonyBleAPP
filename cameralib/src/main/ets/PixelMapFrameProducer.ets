import { image, sendableImage } from '@kit.ImageKit';
import { Logger } from 'common';
import { AbsCameraReader, WriteHandle } from './AbsCameraReader';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'PixelMapFrameProducer'
/**
 * PixelMap 帧数据生产者
 * 负责将从相机获取的 PixelMap 数据写入 AbsCameraReader 的共享缓冲区，供Worker解码
 */
export class PixelMapFrameProducer {
  private reader: AbsCameraReader;

  constructor(reader: AbsCameraReader) {
    this.reader = reader;
  }

  /**
   * 当有新的 PixelMap 帧到达时调用此方法
   * @param pixelMap 从相机回调获取的 PixelMap 对象
   */
  public async onFrame(pixelMap: image.PixelMap| sendableImage.PixelMap): Promise<void> {
    // 1. 从环形缓冲区获取一个可写的槽位
    const handle: WriteHandle | undefined = this.reader.acquireImageForWrite();

    // 如果 handle 为 undefined，说明缓冲区已满，消费者来不及处理
    // 这种情况下，我们直接丢弃当前帧，以保证实时性
    if (!handle) {
      Logger.warn(TAG,'AbsCameraReader buffer is full, dropping frame.');
      return;
    }

    try {
      let time1 = Date.now();
      const requiredBytes = pixelMap.getPixelBytesNumber();
      const tempArrayBuffer = new ArrayBuffer(requiredBytes);
      await pixelMap.readPixelsToBuffer(tempArrayBuffer);//注意用同步
      handle.buffer.set(new Uint8Array(tempArrayBuffer));
      let time2 = Date.now();

      // todo sendableImage.PixelMap时是否能用readPixelsToBufferSync直接拷贝
      // 2. 将 PixelMap 的数据直接读入到共享内存的槽位中
      // handle.buffer 是一个 Uint8Array，它的 .buffer 属性就是底层的 ArrayBuffer(实际上为SharedArrayBuffer，无法直接写入)
      // 这是最高效的方式，避免了中间数据拷贝
      //pixelMap.readPixelsToBufferSync(handle.buffer.buffer);//readPixelsToBuffer无法写SharedArrayBuffer，直接写handle.buffer.buffer(SharedArrayBuffer)会报错，colors mismatch

      // 3. 提交写入操作
      // 这会更新槽位状态为 "Written"，并移动写指针，通知消费者有新数据
      handle.commit(pixelMap.getPixelBytesNumber());
      let time3 = Date.now();
      Logger.warn(TAG,'先用ArrayBuffer再写入SharedArrayBuffer耗时:' + (time2 - time1).toString());
      //Logger.warn(TAG,'直接写入SharedArrayBuffer耗时(不可行):' + (time3 - time2).toString());
      Logger.warn(TAG,'PixelMapFrameProducer写入成功');
    } catch (error) {
      // 如果发生任何错误（例如内存不足），取消本次写入
      handle.cancel();
      let err = error as BusinessError;
      Logger.error(TAG,'Failed to write PixelMap to shared buffer:'+err.message);
    }
  }
}