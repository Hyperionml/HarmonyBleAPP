import { PhotoPageData, initGuidePages } from '../common/PhotosUtils';
import { EntryUtils } from '../common/EntryUtils';
import { preferences } from '@kit.ArkData';
import { router } from '@kit.ArkUI';
import { AppSetting } from '../common/AppSetting';
import WindowUtil from '../utils/WindowUtil';

interface PageTitle {
  main: Resource | string;
  sub:  Resource | string;
}


@Entry
@Component
struct GuidePage {
  @State currentIndex: number = 0;
  @State themeColor: ResourceColor = '#559BE9';
  @State isFirstPage: boolean = true;
  @State isLastPage: boolean = false;
  @State showUserGuideCount: number = 0;
  private guidePages: PhotoPageData[] = initGuidePages();
  private swiperController: SwiperController = new SwiperController();
  private lastTapTime: number = 0;
  private lastPageChangeTime: number = 0;
  private startX: number = 0;
  private startY: number = 0;
  private isSliding: boolean = false; // 跟踪滑动状态
  private GuidePages: PhotoPageData[] = initGuidePages();

  appSetting = new AppSetting(this.getUIContext().getHostContext()!)

  async aboutToAppear(): Promise<void> {
    //主题颜色
    this.themeColor =  await this.appSetting.getTheme();    EntryUtils.setThemeColor(this.themeColor)
    // 获取显示引导页的次数
    this.showUserGuideCount = await this.appSetting.getShowUserGuideCount();
    // 初始化页面状态
    this.updatePageState(this.currentIndex);
  }

  build() {
    Column({ space: 0 }) {
      // 标题区域
      Row() {
        Column({ space: 4 }) {
          Text(this.pageTitles[this.currentIndex].main)
            .transition({ opacity: 100 })
            .fontSize(23)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.Black)
            .margin({ left: 20 })

          Text(this.pageTitles[this.currentIndex].sub)
            .transition({ opacity: 100 })
            .fontSize(15)
            .fontColor(Color.Black)
            .margin({ left: 20, top: 0 })

        }
        // .width('100%')
        .alignItems(HorizontalAlign.Start)
        .width('70%')

        if(this.showUserGuideCount > 0){
          Row() {
            Image($r('app.media.guideclose'))
              .id('backButton')
              .width(30)
              .height(30)
              .objectFit(ImageFit.Contain)
              .fillColor(this.themeColor)
              .margin({ right: 20, bottom: 50 })
              .onClick(() => this.handleCloseClick())
              .responseRegion({ width: 50, height: 50 })
          }
          .width('30%')
          .justifyContent(FlexAlign.End)
        }
      }
      .width('100%')
      .height(80)
      .margin({ top: 10 })

      // Swiper内容区
      Swiper(this.swiperController) {
        ForEach(this.guidePages, (pageData: PhotoPageData, index: number) => {
          Column({ space: 16 }) {
            Image(pageData.errorImg)
              .width('80%')
              .height('43%')
              .objectFit(ImageFit.Contain)
              .margin({ top: 10 })

            Image(pageData.rightImg)
              .width('80%')
              .height('43%')
              .objectFit(ImageFit.Contain)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .onTouch((event: TouchEvent) => {
            switch (event.type) {
              case TouchType.Down:
                this.startX = event.touches[0].x;
                this.startY = event.touches[0].y;
                this.isSliding = false;
                break;
              //横向移动超过20px才算滑动
              case TouchType.Move:
                if (Math.abs(event.touches[0].x - this.startX) > 20) {
                  this.isSliding = true;
                }
                break;
              case TouchType.Up:
                const deltaX = event.touches[0].x - this.startX;
                const deltaY = event.touches[0].y - this.startY;

                // 单击逻辑
                if (!this.isSliding && Math.abs(deltaX) < 20 && Math.abs(deltaY) < 20) {
                  this.handleSingleTap();
                  return;
                }

                // 滑动翻页逻辑
                if (Math.abs(deltaX) > 50) {

                  //先处理首尾页滑动退出
                  if (this.isFirstPage && deltaX > 50) {
                    if(this.showUserGuideCount > 0 ){
                      this.handleSwipe(deltaX);
                    }
                    return;
                  } else if (this.isLastPage && deltaX < -50) {
                    if(this.showUserGuideCount > 0 ){
                      this.handleSwipe(deltaX);
                    }
                    return;
                  }

                  if (deltaX > 0 && this.currentIndex > 0) {
                    this.currentIndex--;
                    this.swiperController.showPrevious(); // 立即切换Swiper
                  } else if (deltaX < 0 && this.currentIndex < this.guidePages.length - 1) {
                    this.currentIndex++;
                    this.swiperController.showNext();
                  }
                  this.updatePageState(this.currentIndex);
                }
                break;
            }
            return true;
          })
        })
      }
      .width('100%')
      .height('80%')
      .index(this.currentIndex)
      .onChange((index: number) => {
        this.currentIndex = index;
        this.updatePageState(index);
        this.lastPageChangeTime = Date.now(); // 更新页面切换时间
      })
      .loop(false) //关闭循环轮播
      .indicator(
        Indicator.dot()
          .color('#CCCCCC')
          .selectedColor(this.themeColor)
      )

      if (this.showUserGuideCount === 0 && this.isLastPage) {
        Row() {  //首次打开app时的进入按钮
          Button($r('app.string.btn_enter'), { type: ButtonType.Capsule } )
            .width(100)
            .height(40)
            .backgroundColor(Color.Transparent)
            .fontColor(this.themeColor)
            .border({
              width:1,
              color:this.themeColor,
            })
            .onClick(() => this.goToScanActivity())
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
        .margin({ right: 30, bottom: 100 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .padding({top:px2vp(WindowUtil.avoidArea.topRect.height)})
  }

  //标题文本数据
  private pageTitles: PageTitle[] = [
    { main: ($r('app.string.txt_header_guide1')), sub: ($r('app.string.txt_title_guide1')) },
    { main: ($r('app.string.txt_header_guide2')), sub: ($r('app.string.txt_title_guide2')) },
    { main: ($r('app.string.txt_header_guide3')), sub: ($r('app.string.txt_title_guide3')) },
    { main: ($r('app.string.txt_header_guide4')), sub: ($r('app.string.txt_title_guide4')) },
    { main: ($r('app.string.txt_header_guide5')), sub: ($r('app.string.txt_title_guide5')) }
  ];

  // 更新页面状态看是否是第一页或最后一页
  private updatePageState(index: number): void {
    this.isFirstPage = index === 0;
    this.isLastPage = index === this.guidePages.length -1 ;
  }

  // 判断能不能点击
  private isCanClick(interval: number = 300): boolean {
    const now = new Date().getTime();
    if (now - this.lastTapTime < interval) {
      return false;
    }
    this.lastTapTime = now;
    return true;
  }

  // 跳转到首页
  private async goToScanActivity(): Promise<void> {
    // 更新引导页显示次数
    this.showUserGuideCount++;
    if (this.appSetting) {
      await this.appSetting.setShowUserGuideCount(this.showUserGuideCount);
    }

    router.replaceUrl({ url: 'pages/IndexPage' })  //改用replaceUrl避免返回指导页
      .catch((err: Error) => {
        console.error('跳转失败:', err);
      });
  }

  //关闭当前页
  private handleCloseClick() {
    if (this.isCanClick()) {
      router.back();
    }
  }

  // 处理单击事件
  private handleSingleTap() {
    if (!this.isCanClick(300)) return;

    // 最后一页单击
    if (this.isLastPage) {
      //首次使用不准单击跳转
      if(this.showUserGuideCount > 0){
        router.back();
      }
    } else {
      // 非最后一页单击，翻到下一页
      this.currentIndex++;
      this.updatePageState(this.currentIndex);
      this.swiperController.showNext();
    }
  }

  // 处理滑动事件
  private handleSwipe(deltaX: number) {
    if (Date.now() - this.lastPageChangeTime < 500) return;

    // 第一页右滑(退出)
    if (deltaX > 50 && this.isFirstPage) {
      this.showUserGuideCount > 0 ? router.back() : console.log("第一页");
    }
    // 最后一页左滑(退出)
    else if (deltaX < -50 && this.isLastPage) {
      this.showUserGuideCount > 0 ? router.back() : this.goToScanActivity();
    }
  }
}
