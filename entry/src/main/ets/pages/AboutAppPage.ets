import { router, ThemeControl } from '@kit.ArkUI';
import { PageCustomTheme, Colors, EntryUtils } from '../common/EntryUtils';
import { AppSetting } from '../common/AppSetting';
import WindowUtil from '../utils/WindowUtil';
import BuildProfile from "BuildProfile";
import { WebViewType } from './WebPage';

@Entry
@Component
struct AboutAppPage {

    @State themeColor: ResourceColor = ''
    @State language: string = ''

    appSetting = new AppSetting(this.getUIContext().getHostContext()!)

    //生命周期函数
    async aboutToAppear(): Promise<void> {
        //初始化页面参数（参数来自持久化数据）
        this.language = await this.appSetting.getLanguage()
        //console.log(`bailimltest language: ${this.language}`);
        //主题颜色
        const color = await this.appSetting.getTheme()
        const theme = new PageCustomTheme(new Colors(color))
        ThemeControl.setDefaultTheme(theme)
    }

    onWillApplyTheme(theme: Theme): void {
        this.themeColor = theme.colors.brand
    }

    build() {
        Column(){
            Blank()
                .height(px2vp(WindowUtil.avoidArea.topRect.height))
                .width('100%')
                .backgroundColor($r('app.color.start_window_background'))
            //标题栏
            this.buildHeader()

            //主题
            Scroll(){
                Column(){
                    //logo
                    this.BuildLogo()
                    //跳转栏
                    Column(){
                        Row() {
                            this.buildRowWithGo($r('app.string.btn_help'))
                        }
                        .height(35)
                        .backgroundColor($r('app.color.start_window_background'))
                        .width('100%')
                        .padding({ left: 16, right: 10 })
                        .margin({top: 0})
                        .onClick(() => {
                            router.pushUrl({
                                url: 'pages/GuidePage'
                            })
                        });

                        Divider()
                            .height(1.5)
                            .color('#ECECEC')
                            .margin({ left: 16, right: 16 })

                        Row() {
                            this.buildRowWithGo($r('app.string.feedback_tv_title'))
                        }
                        .height(35)
                        .backgroundColor($r('app.color.start_window_background'))
                        .width('100%')
                        .padding({ left: 16, right: 10 })
                        .margin({top: 0})
                        .onClick(() => {
                            //跳转
                            router.pushUrl({
                                url: 'pages/FeedbackPage'
                            })
                        });

                        Divider()
                            .height(1.5)
                            .color('#ECECEC')
                            .margin({ left: 16, right: 16 })

                        Row() {
                            this.buildRowWithGo($r('app.string.official_website'))
                        }
                        .height(35)
                        .backgroundColor($r('app.color.start_window_background'))
                        .width('100%')
                        .padding({ left: 16, right: 10 })
                        .margin({top: 0})
                        .onClick(() => {
                            //跳转
                            let url = BuildProfile.OfficialWebsiteUrl
                            router.pushUrl({
                                url: 'pages/WebPage',
                                params: {
                                    url: BuildProfile.OfficialWebsiteUrl,
                                    type: WebViewType.OfficialWeb
                                }
                            })
                        });
                    }
                }
                .width('100%')
            }
            .width('100%')

            //站位空白
            Column().layoutWeight(1)

            //版权栏
            this.buildRight()


        }
        .backgroundColor('#F5F5F5')
    }

    @Builder
    buildHeader() {
        Row(){
            Row(){
                Image($r('app.media.vector_drawable_headback'))
                    .width(20)
                    .height(20)
                    .margin({left: 8, top: 8, bottom: 8})
                    .fillColor(this.themeColor)
                Text($r('app.string.app_bar_setting'))
                    .fontColor(this.themeColor)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .wordBreak(WordBreak.NORMAL)
            }
            .width('33%')
            .onClick(() => {
                router.back()
            })

            Text($r('app.string.about_app'))
                .margin({right: 0})
                .fontColor(this.themeColor)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .wordBreak(WordBreak.NORMAL)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .textAlign(TextAlign.Center)
                .fontColor(this.themeColor)
                .width('33%')
            Blank()
        }
        .width('100%')
        .height(50)
        .backgroundColor('#fff')
    }

    @Builder
    BuildLogo(){
        Column(){
            Image($r('app.media.big_icon'))
                .margin({top: 12})
                .width(100)
                .height(100)
            Text('QT')
                .fontSize(20)
                .fontColor(Color.Black)
                .fontWeight(FontWeight.Bold)
            Text('Version'+ BuildProfile.VERSION_NAME)
                .fontSize(15)
                .fontColor('#60000000')
        }
        .margin({bottom:8})
    }

    @Builder
    buildRowWithGo(title: string | Resource){
        Text(title)
            .fontSize(14)
            .fontColor($r('sys.color.black'))
            .flexGrow(1)
            .width('75%')


        Row({ space: 5 }) {
            Image($r('app.media.disclosureback'))
                .width(30)
                .height(30)
                .objectFit(ImageFit.Contain);
        }
    }

    @Builder
    buildRight(){
        Column(){
            Text($r('app.string.contract_protocol'))
                .fontSize(14)
                .onClick(() => {
                    router.pushUrl({
                        url: 'pages/WebPage',
                        params: {
                            url: BuildProfile.Contract+ '?language=' + this.language,
                            type: WebViewType.Contract
                        }
                    })
                })

            Text($r('app.string.and'))
                .fontSize(14)
                .fontColor('#60000000')

            Text($r('app.string.privacy_policy'))
                .fontSize(14)
                .onClick(() => {
                    router.pushUrl({
                        url: 'pages/WebPage',
                        params: {
                            url: BuildProfile.Privacy + '?language=' + this.language,
                            type: WebViewType.Privacy
                        }
                    })

                })

            Text(`Copyright ${BuildProfile.CopyrightYear} ` + EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext(), $r('app.string.bsn')) + '.All right reserved')
                .fontSize(10)
                .fontColor('#60000000')

            if(this.language === 'zh'){
                Text(BuildProfile.RecordNumber)
                    .fontSize(10)
                    .fontColor('#60000000')
            }

        }
        .width('100%')
        .zIndex(1)
        .justifyContent(FlexAlign.Center)
    }
}

