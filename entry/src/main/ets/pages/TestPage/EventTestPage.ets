import { EventManager,Level,IEventReceiver,Event } from 'common';
import { AppEvent } from '../../common/event/AppEvent';
import { AppEventType } from '../../common/event/AppEventType';
import BuildProfile from "entry/BuildProfile"
import { data } from '@kit.TelephonyKit';
import image from '@ohos.multimedia.image';
import fileio from '@ohos.fileio';
//是否需要采用这种方式实现
//onEvent(sender: Object, event: Event, isAsync: boolean): void;
import { EventTestPageReceiver } from '../../receiver/EventTestPageReceiver';
import { MessageEvents, taskpool, worker } from '@kit.ArkTS';
import { ScanStateMachine } from '../../common/state/ScanStateMachine';
import { application,common } from '@kit.AbilityKit';
import { DecodeBusiness } from '../../decoder/DecodeBusiness';
import { sendableImage } from '@kit.ImageKit';
import { AbsCameraReader } from 'cameralib';
import { BasePage } from '../../component/Page/BasePage';
import { BarcodeFormat } from '@ohos/zxing';
import QRCode from '../../utils/zxing/QRCode';
import { promptAction, router } from '@kit.ArkUI';
import { AppProductManager } from '../../common/ProductManager/AppProductManager';
import { TestNapi, Utils as DUtils,CodeTypes,CodeTypesUtil } from 'decoder';
import { BusinessError } from '@kit.BasicServicesKit';
import { resourceManager } from '@kit.LocalizationKit';
import { fileIo as fs } from '@kit.CoreFileKit';

const context : Context = getContext(this);
const resourceMgr : resourceManager.ResourceManager = context.resourceManager;

@Concurrent
function dummyProcess(t : number){
  let processingTime = Date.now();
  while (Date.now() - processingTime < t) {
    // 模拟50ms的处理时间
  }
  console.log(`模拟处理时间${t}`);
}

//测试方法
function stringToUint8Array(str: string): Uint8Array {
  const view: Uint8Array = new Uint8Array(str.length);
  for (let i: number = 0; i < str.length; i++) {
    view[i] = str.charCodeAt(i) & 0xff;
  }
  return view;
}

@Entry
@Component
export struct EventTestPage {
  @State base64Img: string = '';
  @State message: string = 'EventManager测试页面';
  @State eventLog: string = '';
  @State testUrl:string = BuildProfile.MAIN_SERVER;

  @State timer: number = 0
  @State running: boolean = false
  private intervalId: number = 0

  @State mPixelMap:image.PixelMap|null = null;

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

  //后续有需要或者可以采用这种方式实现
  private eventReceiver: EventTestPageReceiver | null = null;

  private mReader: AbsCameraReader | null = null;

  //状态机
  private scanStateMachine : ScanStateMachine | null = null;

  private mDecodeBusiness : DecodeBusiness | null = null;
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private workerInstance: worker.ThreadWorker|null = null;

  private isJumpSucceed:boolean = false;

  async loadImageBuffer(imagePath: string): Promise<ArrayBuffer> {
    return new Promise((resolve, reject) => {
      resourceMgr.getRawFileContent(imagePath).then((fileData : Uint8Array) => {
        console.log("Succeeded in getting RawFileContent")
        // 获取图片的ArrayBuffer
        const buffer = fileData.buffer.slice(0);
        resolve(buffer);
      }).catch((err : BusinessError) => {
        reject('Failed to get RawFileContent');
      });
    });
  };


  private mReceiver: IEventReceiver = {
    onEvent: (sender: Object|null, event: Event, isAsync: boolean): void => {
      if (event instanceof AppEvent) {
        const appEvent = event as AppEvent;
        switch (appEvent.getAppType()) {
          case AppEventType.WaitingMask:
          case AppEventType.StartScan:
          case AppEventType.StopScan:
            this.handleEvent(sender, appEvent, isAsync);
            //可阻止事件传播
            //event.stop()
            break;
          case AppEventType.ActivityJumpSucceed:
            this.isJumpSucceed = true;
            console.log('EventTestPage isJumpSucceed:',this.isJumpSucceed)
            break;
        }
      }
    }
  };

  public handleEvent(sender: Object|null, event: Event, isAsync: boolean) {
    if (event instanceof AppEvent) {
      const appEvent = event as AppEvent;
      // 模拟一些处理时间
      let processingTime = Date.now();
      while (Date.now() - processingTime < 50) {
        // 模拟50ms的处理时间
      }
      console.log(`接收到事件: ${appEvent.getAppType()}, 异步: ${isAsync}`);
      this.eventLog += `接收到事件: ${appEvent.getAppType()}, 异步: ${isAsync}\n`;
    }
  }

  StateMachineTest(){
    console.log('状态机调用页面方法');
  }

  aboutToAppear() {
    this.rawfileZlibDecompress(context.filesDir + '/2.jpg')
    this.startTimer()
    // 初始化EventManager
    // EventManager.init();
    // 注册事件接收器
    EventManager.attach(this.mReceiver, Level.High);//先按照java代码实现
    //EventManager.attach(this.mReceiver,Level.Common);

    // 是否需要采用这种方式实现
    //this.eventReceiver = new EventTestPageReceiver(this);
    //EventManager.attach(this.eventReceiver, Level.High);

    // 状态机方式
    //this.scanStateMachine = new ScanStateMachine(this);
    //EventManager.attach(this.scanStateMachine, Level.High);

    this.mDecodeBusiness = new DecodeBusiness(this.context, 'this.mXComponentSurfaceId');
    this.mDecodeBusiness.set(this.mDecodeBusiness)
    let status = this.mDecodeBusiness?.getStatus()
    console.info("worker 修改前 mDecodeBusiness.Status: " + status);

    // 创建Worker对象
    this.workerInstance = new worker.ThreadWorker("entry/ets/workers/CameraWorker.ets");
    // 在Worker上注册需要调用的对象
    this.workerInstance.registerGlobalCallObject("DecodeBusiness", this.mDecodeBusiness);
    this.workerInstance.onmessage = (e: MessageEvents): void => {
      // 接收Worker子线程的结果
      console.info("mainthread: " + e.data);
      let status = this.mDecodeBusiness?.getStatus()
      console.info("worker 修改后 mDecodeBusiness.Status: " + status);
      // 销毁Worker
      // workerInstance.terminate();
    }

    this.mReader = new AbsCameraReader(200,200,image.PixelMapFormat.RGBA_8888,3,0,false)

    console.log('EventTestPage aboutToAppear');
  }

  onPageShow() {
    console.log('EventTestPage onPageShow');
  }

  onPageHide() {
    console.log('EventTestPage onPageHide');
  }

  aboutToDisappear() {
    this.stopTimer()
    EventManager.destroy();
    console.log('EventTestPage aboutToDisappear');

    //删掉
    fs.unlink(context.filesDir + '/2.jpg');
  }

  rawfileZlibDecompress(filePath:string) {
    resourceMgr.getRawFileContent('2.jpg', (_err, value) => {
      let myBuffer: ArrayBufferLike = value.buffer
      //将rawfile下的文件拷贝至沙箱下，沙箱路径：/data/storage/el2/base/haps/entry/files/6.png
      let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      let writeLen = fs.writeSync(file.fd, myBuffer);
      console.log(`write data to file succeed and size is:${writeLen}`);
      fs.closeSync(file);
    })
  }

  build() {
    Scroll() {
      Column({ space: 5 }) {
        BasePage()
        Row({ space: 5 }) {
          Button('CameraTestPage')
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/TestPage/CameraTestPage'
              });
            })
          Button('CameraWorkerTestPage')
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/TestPage/CameraWorkerTestPage'
              });
            })
        }
        .justifyContent(FlexAlign.Start)
        .width('100%')

        Row({ space: 5 }) {
          Button('ScanPage')
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/TestPage/ScanPage'
              });
            })
          Button('Test')
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/TestPage/Index'
              });
            })
          Button('taskpool')
            .onClick(() => {
              // 最终推荐代码
              Promise.resolve().then(async () => {
                try {
                  const task = new taskpool.Task(dummyProcess, 500);
                  await taskpool.execute(task);
                } catch (error) {
                  console.error('图像处理失败:', error);
                } finally {
                }
              });
            })
          Button('postMessage')
            .onClick(() => {
              this.workerInstance?.postMessage("setStatus");
            })
        }
        .justifyContent(FlexAlign.Start)
        .width('100%')

        Row(){
          Button('bailiml test')
            .onClick(() => {
              router.pushUrl({url: 'pages/TestPage/BailimlTestPage'})
            })
        }

        Row(){
          Button('FileTransfer test')
            .onClick(() => {
              router.pushUrl({url: 'pages/TestPage/DeviceManagerTestPage'})
            })

          Button('ImageSaver test')
            .onClick(() => {
              router.pushUrl({url: 'pages/TestPage/ImageSaverPage'})
            })
        }

        Row({ space: 5 }) {
          Button('ZXing测试')
            .onClick(async () => {
              try {
                const ctx = getContext(this) as common.UIAbilityContext;
                const resMgr = ctx.resourceManager;
                const rawFd = resMgr.getRawFdSync('baidu_qrcode.png'); // 返回 RawFileDescriptor
                const imageSource = image.createImageSource(rawFd);
                let pixelMap = imageSource.createPixelMapSync();
                console.log("裁剪前 readBuffer size:",pixelMap.getPixelBytesNumber())

                let size = imageSource.getImageInfoSync().size
                let qrcode = new QRCode()
                let message = await qrcode.decode(pixelMap , {
                  width: size.width,
                  height: size.height,
                  format: BarcodeFormat.QR_CODE
                })
                promptAction.showToast({
                  message: '调用ZXing解码成功:'+message,
                  duration: 2000
                });

                //裁剪
                pixelMap.cropSync({
                  size: {
                    width: 200,
                    height: 200
                  },
                  x: 200,
                  y: 200
                });
                const bufferSize = pixelMap.getPixelBytesNumber();
                const readBuffer = new ArrayBuffer(bufferSize);
                pixelMap.readPixelsToBufferSync(readBuffer);
                console.log("readBuffer size:",readBuffer.byteLength)
                this.mPixelMap = pixelMap;
                console.log("处理图片")

                if(!this.mReader) return
                const handle = this.mReader.acquireImageForWrite()
                if(!handle) return
                const dst = handle.buffer
              } catch (e) {
                console.error('出错了：', JSON.stringify(e));
              }
            })
          // Image($r('app.media.g2_bulge_vans_1'))
          Image(this.mPixelMap).width(200).height(200)
        }
        .justifyContent(FlexAlign.Start)
        .width('100%')

        Row(){
          Image(`data:image/png;base64,${this.base64Img}`).width(200)
          Button('decoder测试').onClick(async () => {
              let input: Uint8Array = stringToUint8Array("hello");
              let md5hex = DUtils.getMD5(input);
              if(md5hex)
                promptAction.showToast({
                  message: 'md5:'+ md5hex,
                  duration: 1000
                });
              // 先加载图片的buffer
              this.loadImageBuffer('g2_bulge_vans_1.jpg').then( buffer => {
                // 利用opencv进行灰度处理
                let base64 = new TestNapi().processImage(buffer);
                this.base64Img = base64;
                console.log('opencv 处理成功')
              }
              ).catch( (msg:string) =>  {
                console.error('出错了：', msg);
              }
              );
            })
        }

        Row({ space: 5 }) {
          Button('CameraReader测试')
            .onClick(() => {
              try {
                this.isJumpSucceed = false;
                console.log('ready to jump:',this.isJumpSucceed)

                this.getUIContext().getRouter().pushUrl({
                  url: 'pages/TestPage/CameraReaderTestPage'
                });
              } catch (e) {
                console.error('出错了：', JSON.stringify(e));
              }
            })
          Button('ble测试')
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/BleDemo/Index'
              });
            })
          Button('getMD5ofFile/getCrc').onClick(async () => {
            let filePath = context.filesDir + '/2.jpg';
            let file = fs.statSync(filePath);
            let isFile = file.isFile()
            let size = file.size
            console.log(filePath + ',size:' + size);
            if(!isFile){
              //复制到沙箱环境去测试getMD5ofFile
              this.rawfileZlibDecompress(filePath)
            }

            let fileMd5 = DUtils.getMD5ofFile(filePath)

            let data = new Uint8Array([1, 2, 3, 4, 5]);
            let data2 = new Uint8Array([1, 2, 3, 4, 5]);
            let crc = DUtils.getCrc(data, 0, data.length);
            let crc2 = DUtils.getCrc(data2, 0, data.length);

            promptAction.showToast({
              message: '调用getMD5ofFile成功:'+fileMd5+`，getCrc结果：${crc} / ${crc2}`,
              duration: 2000
            });

            let a:CodeTypes = CodeTypes.First
            let b:CodeTypes = CodeTypesUtil.get('1G')
            let c:CodeTypes = CodeTypesUtil.get(1)
            let d = CodeTypesUtil.values()
            let e = typeof a
            d.forEach((item: CodeTypes)=>{
              console.info(CodeTypesUtil.getName(item));
            })
            if(a == b && b == c && typeof a == typeof b && typeof b == typeof c)
            {
              console.info("testTag:BarcodeFormat通过");
            }
            else{
              console.info("testTag:BarcodeFormat不通过");
            }
          })
        }
        .justifyContent(FlexAlign.Start)
        .width('100%')

        Text(`计时器: ${this.timer}`)
          .fontSize(30)
          .fontWeight(FontWeight.Bold)

        Text('BuildProfile参数测试:' + this.testUrl)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Text(this.message)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Button('清空日志')
          .onClick(() => {
            this.eventLog = '';
          })
          .backgroundColor(Color.Orange)

        Button('发送同步事件')
          .onClick(() => {
            EventManager.sync(this, new AppEvent(AppEventType.StartScan, Level.Common, true));
          })

        Button('发送异步事件')
          .onClick(async () => {
            EventManager.async(this, new AppEvent(AppEventType.StopScan, Level.High));
          })

        Button('发送混合事件')
          .onClick(async () => {
            // for (let index = 0; index < 10; index++) {
            EventManager.async(this, new AppEvent(AppEventType.StartScan, Level.High));
            EventManager.async(this, new AppEvent(AppEventType.WaitingMask, Level.Common, true));
            // }
            // for (let index = 0; index < 10; index++) {
            EventManager.sync(this, new AppEvent(AppEventType.StopScan, Level.High));
            // }
          })

        Text('事件日志:')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)

        Text(this.eventLog)
          .fontSize(14)
          .backgroundColor(Color.Gray)
          .padding(10)
          .borderRadius(5)
          .width('100%')
          .height(200)
          .textAlign(TextAlign.Start)
      }
      .padding(20)

    }
    .width('100%')
    .height('100%')
    .scrollable(ScrollDirection.Vertical)
  }
}