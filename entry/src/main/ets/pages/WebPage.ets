import { webview } from '@kit.ArkWeb';
import WindowUtil from '../utils/WindowUtil';
import { AllowAgreementDialog } from '../component/Dialog/AllowAgreementDialog';
import { router } from '@kit.ArkUI';
import { AppSetting } from '../common/AppSetting';
import { EntryUtils } from '../common/EntryUtils';

interface paramObj {
  url: string
  from?: string
  type?: WebViewType
}

export enum WebViewType{
  OfficialWeb,
  Contract,
  Privacy,
  DecodeResult
}

//WebviewController.removeCache() 必须在绑定 <Web> 实例的 controller 上调用，因此无法实现在设置页面清理缓存，在设置页用一个隐藏的webview实现
// export class WebViewManager {
//   private static controller: webview.WebviewController | null = null;
//   static getController(): webview.WebviewController {
//     if (!WebViewManager.controller) {
//       WebViewManager.controller = new webview.WebviewController();
//     }
//     return WebViewManager.controller;
//   }
//   // 清理所有Web数据
//   static removeCache() {
//     WebViewManager.getController().removeCache(true)
//   }
// }

@Entry
@Component
struct WebPage {
  controller: webview.WebviewController = new webview.WebviewController();
  appSetting = new AppSetting(this.getUIContext().getHostContext()!)

  @State themeColor: ResourceColor = ''
  @State url: string = ''
  @State from: string = ''
  @State title:string = ''

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as paramObj;
    if (params?.url) {
      this.url = params.url;
      this.from = params.from === undefined ? '' : params.from
      console.log("WebPage Url:"+ params.url)
    } else {
    }

    if(params.type != undefined){
      let type = params.type as WebViewType;
      switch (type){
        case WebViewType.OfficialWeb:
          this.title = EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext()!, $r('app.string.official_website'))
          break;
        case WebViewType.Contract:
          this.title = EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext()!, $r('app.string.contract_protocol'))
          break;
        case WebViewType.Privacy:
          this.title = EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext()!, $r('app.string.privacy_policy'))
          break;
        case WebViewType.DecodeResult:
          this.title = EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext()!, $r('app.string.txt_decode_result'))
          break;
      }
    }

    const color = await this.appSetting.getTheme()
    this.themeColor = color
    EntryUtils.setThemeColor(color)
  }

  build() {
    Column() {
      Blank()
        .height(px2vp(WindowUtil.avoidArea.topRect.height))
        .width('100%')
        .backgroundColor($r('app.color.start_window_background'))
      this.buildHeader()
      Web({ src: this.url, controller: this.controller, renderMode: RenderMode.SYNC_RENDER })
        // .onAttach(()=>{
        //   let innerEvent: emitter.InnerEvent = {
        //     eventId: 10001
        //   };
        //   let callback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
        //     this.controller.removeCache(true)
        //     console.info(`eventData: ${JSON.stringify(eventData)}`);
        //   }
        //   emitter.once(innerEvent, callback);
        // })
    }
  }

  //顶部标题栏
  @Builder
  buildHeader(){
    Row(){
      Row(){
        Image($r('app.media.vector_drawable_headback'))
          .width(20)
          .height(20)
          .margin({left: 8, top: 8, bottom: 8})
          .fillColor(this.themeColor)
        Text($r('app.string.back'))
          .fontColor(this.themeColor)
          .maxLines(1)
          .padding({right: 30})
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .wordBreak(WordBreak.NORMAL)
      }
      .width('33%')
      .onClick(() => {
        router.back()
      })
      Text(this.title)
        .fontSize(20)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .wordBreak(WordBreak.NORMAL)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .fontColor(this.themeColor)
        .width('33%')
      Blank()
    }
    .backgroundColor($r('app.color.start_window_background'))
    .width('100%')
    .height(40)
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({bottom: 0})

  }
}