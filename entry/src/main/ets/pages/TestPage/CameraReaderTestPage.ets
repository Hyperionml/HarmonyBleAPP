import { image, sendableImage } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { AbsCameraReader, PixelMapFrameProducer,WriteHandle} from 'cameralib';
import { ScanningEffectCanvasDynamic,ScanningEffectCanvasStatic,ScanBoxInfo} from '../../component/view/ScanningEffectCanvas';
import { ScanningRectEffect} from '../../component/view/ScanningRectEffect';
import { worker, MessageEvents, ErrorEvent } from '@kit.ArkTS';
import { DecoderCameraParameters } from '../../decoder/DecoderCameraParameters';
import { BasePage } from '../../component/Page/BasePage';
import { display, promptAction, window } from '@kit.ArkUI';

import { BleManager } from '@ohos/fastble';
import { ImageDataMsg, InitMsg, DecodeResultMsg, WorkerPostMessageType } from '../../decoder/DecodeWorkerModel';
import { DecodeResultBean } from '../../bean/DecodeResultBean';
import { Logger } from 'common';
import { Decoder, OnDecodeResult } from '../../decoder/Decoder';

const TAG = 'CameraReaderTestPage'

@Entry
@Component
struct CameraReaderTestPage {
  @State mPixelMap: image.PixelMap | null = null;
  @State testResults: string = '';
  @State decodeResults: string = '';
  private mReader: AbsCameraReader | null = null;
  private mFrameProducer: PixelMapFrameProducer | null = null;
  //private decodeWorker: worker.ThreadWorker | null = null;
  private isWorkerRunning: boolean = false;

  private mPixelMapSendAble: sendableImage.PixelMap | null = null;

  private imageWidth:number = 1920
  private imageHeight:number = 1080

  private screenWidth: number = 0;
  private screenHeight: number = 0;

  private mDecoder: Decoder | null = null;

  @State themeColor: ResourceColor = '#FF0000';
  @State isQT: boolean= true
  @State timer: number = 0
  @State running: boolean = false
  private intervalId: number = 0
  private startTimer() {
    this.running = true
    this.intervalId = setInterval(() => {
      if (this.running) {
        this.timer++
      }
    }, 100)
  }
  private stopTimer() {
    this.running = false
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = 0
    }
  }

  //处理解码结果
  private mDecodeResultListener: OnDecodeResult = {
    onDecoded: (data: DecodeResultBean, ok: boolean) => {
      const timestamp = new Date().toLocaleTimeString();
      if (ok && data.IsSuccess()) {
        this.decodeIndex++;
        this.decodeResults = `[${timestamp}] ✅ ${this.decodeIndex}解码成功${data.getCode()}\n` + this.decodeResults;
        promptAction.showToast({
          message: 'Worker调用ZXing解码成功，结果为:' + data.getCode(),
          duration: 2000
        });
      } else {
        this.decodeResults = `[${timestamp}] ❌ 解码失败\n` + this.decodeResults;
      }
    },
    onWorkerError: (error: ErrorEvent): void => {
      const timestamp = new Date().toLocaleTimeString();
      this.decodeResults = `[${timestamp}] ❌ worker异常:${error.message}\n` + this.decodeResults;
    },
    onWorkerInitted: (): void => {
      const timestamp = new Date().toLocaleTimeString();
      if (this.mReader) {
        this.mDecoder?.decode(this.mReader);
        this.decodeResults = `[${timestamp}] ✅ worker初始化完成\n` + this.decodeResults;
      }
    },
    onHandleFrame: (frame: Uint8Array): void => {
      throw new Error('Function not implemented.');
    }
  };

  aboutToAppear() {
    const ctx = getContext(this) as common.UIAbilityContext;
    const resMgr = ctx.resourceManager;
    const rawFd = resMgr.getRawFdSync('2.jpg'); // 返回 RawFileDescriptor
    const imageSource = image.createImageSource(rawFd);
    let pixelMap = imageSource.createPixelMapSync();
    let size = imageSource.getImageInfoSync().size
    this.imageWidth = size.width
    this.imageHeight = size.height
    this.mPixelMap = pixelMap

    const croppedSize = pixelMap.getPixelBytesNumber();
    const readBuffer = new ArrayBuffer(croppedSize);
    pixelMap.readPixelsToBufferSync(readBuffer);
    let pixelMapInfo = pixelMap.getImageInfoSync();
    this.mPixelMapSendAble = sendableImage.createPixelMapSync(readBuffer,{ editable: true, size: pixelMapInfo.size,
      srcPixelFormat: pixelMapInfo.pixelFormat });

    this.startTimer()
    // 初始化测试用的 AbsCameraReader
    this.initTestReader(size.width,size.height,image.PixelMapFormat.RGBA_8888);

    let displayClass: display.Display | null = null;
    displayClass = display.getDefaultDisplaySync();
    this.screenWidth = displayClass.width;//1260
    this.screenHeight = displayClass.height;//2720
    let availableWidth = displayClass.availableWidth
    let availableHeight= displayClass.availableHeight
    window.getLastWindow(getContext(this), (error, topWindow) => {
      if (topWindow) {
        let area = topWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        let statusBarHeight = area.topRect.height
      }
    })
    // 初始化解码 Worker
    this.initDecodeWorker();
  }

  testData:Uint8Array|null = null

  onPageHide(): void {
    clearTimeout(this.loopTimer);
    this.loopTimer = -1;
    // 清理资源
    if (this.mDecoder) {
      this.mDecoder.releaseWorker();
    }
  }

  aboutToDisappear() {
    if(this.loopTimer) clearTimeout(this.loopTimer);
    this.loopTimer = -1;
    // 清理资源
    if (this.mDecoder) {
      this.mDecoder.releaseWorker();
    }
  }

  private initTestReader(width:number,height:number,format:image.PixelMapFormat) {
    try {
      this.mReader = AbsCameraReader.getInstance(width, height, format, 3, 90, false);
      if(!this.mFrameProducer || this.mReader.consumeChanged()){
        this.mFrameProducer = new PixelMapFrameProducer(this.mReader);
      }
      this.appendResult('✅ AbsCameraReader 初始化成功');
    } catch (error) {
      this.appendResult(`❌ AbsCameraReader 初始化失败: ${error}`);
    }
  }

  private decodeIndex = 0

  private initDecodeWorker() {
    try {
      this.mDecoder = Decoder.getInstance();
      this.mDecoder.start(this.mDecodeResultListener);
      this.appendResult('✅ DecodeWorker 初始化成功');
    } catch (error) {
      this.appendResult(`❌ DecodeWorker 初始化失败: ${error}`);
    }
  }

  private appendResult(message: string) {
    const timestamp = new Date().toLocaleTimeString();
    this.testResults = `[${timestamp}] ${message}\n` + this.testResults;
  }

  // 启动解码 Worker
  private startDecodeWorker() {
    try {
      if (this.mDecoder) {
        this.mDecoder.start(this.mDecodeResultListener);
        this.appendResult('✅ DecodeWorker 已开启');
      }
    } catch (error) {
      this.appendResult(`❌ 启动 DecodeWorker 失败: ${error}`);
    }
  }

  // 停止解码 Worker
  private stopDecodeWorker() {
    if (this.mDecoder) {
      this.mDecoder.stop();
      this.appendResult('✅ DecodeWorker 已停止');
    }
  }

  private loopTimer?: number;
  // 测试FrameProducer
  private testPixelMap(){
    if (this.mFrameProducer && this.mPixelMapSendAble) {
      this.mFrameProducer.onFrame(this.mPixelMapSendAble);
      if(this.mReader)
        this.mDecoder?.decode(this.mReader)
    }
    this.loopTimer = setTimeout(() => { this.testPixelMap() },300)
  }

  // 测试1: 图片加载与处理
  private async testImageProcessing() {
    try {
      this.appendResult('🔄 开始图片处理测试...');

      const ctx = getContext(this) as common.UIAbilityContext;
      const resMgr = ctx.resourceManager;
      const rawFd = resMgr.getRawFdSync('baidu_qrcode.png');

      // 创建图片源
      const imageSource = image.createImageSource(rawFd);
      let pixelMap = imageSource.createPixelMapSync();

      const originalSize = pixelMap.getPixelBytesNumber();
      this.appendResult(`📏 原始图片大小: ${originalSize} bytes`);

      // 裁剪测试
      pixelMap.cropSync({
        size: { width: 200, height: 200 },
        x: 200,
        y: 200
      });

      const croppedSize = pixelMap.getPixelBytesNumber();
      this.appendResult(`✂️ 裁剪后大小: ${croppedSize} bytes`);

      // 读取像素数据
      const readBuffer = new ArrayBuffer(croppedSize);
      pixelMap.readPixelsToBufferSync(readBuffer);
      this.appendResult(`✅ 像素数据读取成功: ${readBuffer.byteLength} bytes`);

      if(this.mPixelMapSendAble){
        // 确保 Worker 已启动
        if (this.mReader) {
          this.mDecoder?.decode(this.mReader);
        }
        this.mDecoder?.postMessageWithSharedSendable(this.mPixelMapSendAble);
      }

      this.mPixelMap = pixelMap;
      return readBuffer;

    } catch (error) {
      this.appendResult(`❌ 图片处理测试失败: ${error}`);
      throw error as Error;
    }
  }

  /**
   * Y轴位置安卓为40%
   * */
  @State scanningEffectYPercent: number = 0.4;
  private scanBoxInfo :ScanBoxInfo |null = null;
  build() {
    Stack() {
      Column({ space: 20 }) {
        BasePage()

        Text('CameraReader + DecodeWorker 测试')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Text(`计时器: ${this.timer}`)
          .fontSize(30)
          .fontWeight(FontWeight.Bold)

        Row({ space: 10 }) {
          Button('直接Sendable解码')
            .onClick(() => this.testImageProcessing())

          Button('模拟相机写入(QR)')
            .onClick(() => this.testPixelMap())
        }

        Row({ space: 10 }) {
          Button(this.isQT ? 'QT' : 'QR')
            .onClick(() => {
              this.isQT = !this.isQT
              this.themeColor = this.isQT ? '#FFA500' :'#0A59F7'
              this.mDecoder?.setIsQTCode(this.isQT)
              BleManager.getInstance().init();
              BleManager.getInstance()
                .enableLog(true)
                .setReConnectCount(1, 5000)
                .setConnectOverTime(20000)
                .setOperateTimeout(5000);
            })

          Button('启动Worker解码')
            .backgroundColor(Color.Green)
            .onClick(() => this.startDecodeWorker())

          Button('停止Worker解码')
            .backgroundColor(Color.Red)
            .onClick(() => this.stopDecodeWorker())
        }

        Row({ space: 10 }) {
          Button('release')
            .backgroundColor(Color.Gray)
            .onClick(() => {
              this.aboutToDisappear()
            })
          Button('清空结果')
            .backgroundColor(Color.Gray)
            .onClick(() => {
              this.testResults = '';
              this.decodeResults = '';
            })
        }

        if (this.mPixelMap) {
          // Image(this.mPixelMap)
          //   .width(200)
          //   .height(200)
          //   .objectFit(ImageFit.Contain)
        }

        // 写入测试结果
        Text('写入测试结果:')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)

        Scroll() {
          Text(this.testResults)
            .fontSize(12)
            .fontFamily('monospace')
            .backgroundColor('#f0f8ff')
            .padding(10)
            .width('100%')
            .textAlign(TextAlign.Start)
        }
        .height(200)
        .width('100%')

        // 解码结果
        Text('解码结果:')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)

        Scroll() {
          Text(this.decodeResults)
            .fontSize(12)
            .fontFamily('monospace')
            .backgroundColor('#f5f5dc')
            .padding(10)
            .width('100%')
            .textAlign(TextAlign.Start)
        }
        .layoutWeight(1)
        .width('100%')
      }
      .padding(0)
      .height('100%')
      .width('100%')

      //ScanningRectEffectCanvas()
    }
  }
}