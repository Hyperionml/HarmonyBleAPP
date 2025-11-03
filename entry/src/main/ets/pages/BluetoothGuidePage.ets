import { preferences } from '@kit.ArkData';
import { EntryUtils } from '../common/EntryUtils';
import data from '@ohos.telephony.data';
import { router, Router } from '@kit.ArkUI';
import { initBlueToothGuidePage, PhotoPageData } from '../common/PhotosUtils';
import { AppSetting } from '../common/AppSetting';
import WindowUtil from '../utils/WindowUtil';


//定义蓝牙指导页数据结构
interface BluetoothGuidePageData {
  title: Resource | string;
  img?: Resource;
  content: Resource;
}
@Entry
@Component
struct BluetoothGuidePage {
@State themeColor: ResourceColor = ' ';
@State currentIndex :number = 0;
@State isFirstPage: boolean = true;
@State isLastPage: boolean = false;

  private swiperController: SwiperController = new SwiperController();
  private startX: number = 0;
  private startY: number = 0;
  private isSliding: boolean = false;
  private lastTapTime: number = 0;
  private lastPageChangeTime: number = 0;
  private bluetoothGuidePages: PhotoPageData[] = initBlueToothGuidePage();
  appSetting = new AppSetting(this.getUIContext().getHostContext()!)

  //初始化页面
  async aboutToAppear(): Promise<void> {
    this.themeColor =  await this.appSetting.getTheme();
    EntryUtils.setThemeColor(this.themeColor);
    this.updatePageState(this.currentIndex);
  }

  build() {
    Stack(){
      Column(){
        Row(){
          //标题
          Column(){
            Text(this.guidePages[this.currentIndex].title)
              .fontSize(23)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.Black)
              .margin({ left: 20  })
          }
          .alignItems(HorizontalAlign.Start)
          .width('70%')

          //关闭按钮
          Row(){
            Image($r('app.media.guideclose'))
              .width(30)
              .height(30)
              .objectFit(ImageFit.Contain)
              .fillColor(this.themeColor)
              .margin({ right: 20 })
              .responseRegion({ width: 50, height: 50 })
              .onClick(() => this.handleCloseClick())
          }
          .width('30%')
          .justifyContent(FlexAlign.End)
        }
        .width('100%')
        .height(10)
        .margin({ top:20 })

        //swiper内容
        Swiper(this.swiperController){
          ForEach(this.guidePages,(pageData: BluetoothGuidePageData,index: number) =>{
            Column({ space:16 }){
              //图片
              Image(pageData.img)
                .width(330)
                .height(300)
                .objectFit(ImageFit.Contain)
                .align(Alignment.Center)
                 .margin({ top: -150 })
              //文本
              Text(pageData.content)
                .width('75%')
                .fontSize(15)
                .fontColor(Color.Black)
                .textAlign(TextAlign.JUSTIFY)//两端对齐
                .lineHeight(25)
            }
            .width('100%')
            .height('93%')
            .justifyContent(FlexAlign.Center) // 垂直居中
            .alignItems(HorizontalAlign.Center) // 水平居中
            .onTouch((event: TouchEvent) => {
              switch (event.type) {
                case TouchType.Down:
                  this.startX = event.touches[0].x;
                  this.startY = event.touches[0].y;
                  this.isSliding = false;
                  break;
                  //横向超过20px才算滑动
                case TouchType.Move:
                  if (Math.abs(event.touches[0].x - this.startX) > 20) {
                    this.isSliding = true;
                  }
                  break;
                case TouchType.Up:
                  const deltaX = event.touches[0].x - this.startX;
                  const deltaY = event.touches[0].y - this.startY;

                  //单击逻辑
                  if (!this.isSliding && Math.abs(deltaX) < 20 && Math.abs(deltaY) < 20) {
                    this.handleSingleTap();
                    return;
                  }

                  //滑动翻页逻辑
                  if (Math.abs(deltaX) > 50) {
                    //首尾页滑动退出
                    if (this.isFirstPage && deltaX > 50) {
                      router.back();
                    } else if (this.isLastPage && deltaX < -50) {
                      this.handleSwipe(deltaX);
                    }
                    //手指向右滑上一页
                    if(deltaX > 0 && this.currentIndex > 0){
                      this.currentIndex--;
                      this.swiperController.showPrevious();//立即切换
                      //手指向左滑下一页
                    }else if(deltaX < 0 && this.currentIndex < this.guidePages.length - 1){
                      this.currentIndex++;
                      this.swiperController.showNext();
                    }
                    this.updatePageState(this.currentIndex)
                  }
                  break;
              }
              return true;
            })
          })
        }
        .onChange((index) =>{
          this.currentIndex = index;
        })
        .indicator(
          Indicator.dot()
            .color('#CCCCCC')
            .selectedColor(this.themeColor)
        )
      }
      .position({ bottom: 30 })
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Color.White)
    .padding({top:px2vp(WindowUtil.avoidArea.topRect.height)})
  }

  //蓝牙指导页数据
  private guidePages: BluetoothGuidePageData[] = [
    {
      title: $r('app.string.txt_bluetooth_guide_title1'),
      img: $r('app.media.bluetooth_guide1'),
      content: $r('app.string.txt_bluetooth_guide_content1'),
    },
    {
      title: $r('app.string.txt_bluetooth_guide_title2'),
      img: $r('app.media.bluetooth_guide2'),
      content: $r('app.string.txt_bluetooth_guide_content2'),
    },
    {
      title: $r('app.string.txt_bluetooth_guide_title3'),
      img: $r('app.media.bluetooth_guide3'),
      content: $r('app.string.txt_bluetooth_guide_content3'),
    },
    {
      title: $r('app.string.txt_bluetooth_guide_title4'),
      img: $r('app.media.bluetooth_guide4'),
      content: $r('app.string.txt_bluetooth_guide_content4'),
    }
  ];

  // 判断能不能点击
  private isCanClick(interval: number = 300): boolean {
    const now = new Date().getTime();
    if (now - this.lastTapTime < interval) {
      return false;
    }
    this.lastTapTime = now;
    return true;
  }

  //关闭按钮
  private handleCloseClick() {
    if (this.isCanClick()) {
      router.back();
    }
  }

  // 更新页面状态看是否是第一页或最后一页
  private updatePageState(index: number): void {
    this.isFirstPage = index === 0;
    this.isLastPage = index === this.guidePages.length - 1;
  }

  //处理单击事件
  private handleSingleTap(){
    if(!this.isCanClick(300)) return;
    //最后一页时返回上一页
    if(this.isLastPage){
      router.back()
    }else {
      this.currentIndex++;
      this.updatePageState(this.currentIndex);
      this.swiperController.showNext();
    }
  }

  //处理滑动事件
  private handleSwipe(deltaX: number){
    if (Date.now() - this.lastPageChangeTime < 500) return;

    if (deltaX > 50 && this.isFirstPage) {
      router.back();
    } else if (deltaX < -50 && this.isLastPage) {
      router.back();
    }
  }

}
