import { router } from '@kit.ArkUI';
import { AppSetting } from '../common/AppSetting';
import { EntryUtils } from '../common/EntryUtils';
import WindowUtil from '../utils/WindowUtil';



@Entry
@Component
struct LanguageSettingPage {

  @State themeColor: ResourceColor = ''
  @State isChange: boolean = false
  @State currentLanguage: string = '简体中文'
  @State beforCurrentLanguage: string = '简体中文'

  appSetting = new AppSetting(this.getUIContext().getHostContext() as Context)

  //生命周期函数
  async aboutToAppear(): Promise<void> {
    //初始化页面参数（参数来自持久化数据）
    //主题颜色
    this.themeColor = await this.appSetting.getTheme()
    this.beforCurrentLanguage = this.currentLanguage = await this.appSetting.getLanguage()
  }

  //离开页面时恢复所有设置
  aboutToDisappear(): void {
    //恢复数据
    //this.appSetting.setLanguage(this.beforCurrentLanguage)
  }

  build() {
    Column(){
      Blank()
        .height(px2vp(WindowUtil.avoidArea.topRect.height))
        .width('100%')
        .backgroundColor($r('app.color.start_window_background'))
      //顶部标题栏
      this.buildHeader()
      this.line()
      Scroll(){
        Column(){
          this.buildRowWithImg($r('app.string.language_english_constant'), 'en') //en
          this.line()
          this.buildRowWithImg($r('app.string.language_french_constant'), 'fr') //fr
          this.line()
          this.buildRowWithImg($r('app.string.language_German_constant'), 'de') //de
          this.line()
          this.buildRowWithImg($r('app.string.language_Spanish_constant'), 'es') //es
          this.line()
          this.buildRowWithImg($r('app.string.language_Portuguese_constant'), 'pt') //pt
          this.line()
          this.buildRowWithImg($r('app.string.language_chinese_constant'), 'zh') //zh
          this.line()
        }

      }
    }
    .backgroundColor('#F5F5F5')
    .height('100%')

  }

  //顶部标题栏
  @Builder
  buildHeader(){
    Row(){
      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Row({ space: 5 }) {
          Image($r('app.media.headback'))
            .width(16)
            .height(16)
            .fillColor(this.themeColor)
          Text($r('app.string.app_bar_setting'))
            .fontSize(16)
            .fontColor(this.themeColor)
        }
        .onClick(() => {
          router.back()
        })
      }
      .height(24)
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .padding({
        left: 10,
        right: 10,
        top: 5,
        bottom: 5
      })
      Blank()
      Text($r('app.string.language'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .fontColor(this.themeColor)
        .padding({right:7})
      Blank()
      Button({ type: ButtonType.Normal, stateEffect: true }) {

        if(this.isChange){
          this.saveButtonText(1, true)
        }
        else {
          this.saveButtonText(0.8, false)
        }

      }
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius(5)
      .padding({ left: 10, right: 20, top: 5, bottom: 5 })
    }
    .backgroundColor($r('app.color.start_window_background'))
    .width('100%')
    .height(40)
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({bottom: 0})

  }

  //具有打勾标签的条
  @Builder
  buildRowWithImg(title: Resource, tag: string, topMargin: number = 0){
    Row() {
      Text(title)
        .fontSize(14)
        .fontColor('#000000')
        .flexGrow(1)
        .width('75%')


      Row({ space: 5 }) {
        if(tag === this.currentLanguage){
          this.checkImg(1)
        }
        else {
          //this.checkImg(0)
        }
      }

    }
    .height(35)
    .backgroundColor('#FFFFFF')
    .width('100%')
    .padding({ left: 16, right: 10 })
    .margin({top: topMargin})
    .onClick(() => {
      this.currentLanguage = tag
      this.checkIsChange()
    })
    .clickEffect({level:ClickEffectLevel.LIGHT, scale: 0.9})
  }

  @Builder
  line(){
    Divider()
      .height(1.5)
      .color('#ECECEC')
      .width('100%')
      .margin({ left: 16, right: 16 }) // 与开关缩进对齐
  }

  @Builder
  checkImg(opacity: number){
    Image($r('app.media.check'))
      .width(30)
      .height(30)
      .objectFit(ImageFit.Contain)
      .fillColor(this.themeColor)
      .opacity(opacity)
  }

  @Builder
  saveButtonText(opacity: number, enabled: boolean){
    Text($r('app.string.settings_save'))
      .fontSize(16)
      .fontColor(this.themeColor)
      .opacity(opacity)
      .enabled(enabled)
      .onClick(() => {
        //当没有属性改变时不会进行如下逻辑
        if(!this.isChange) return

        //提示弹窗
        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.the_modification_succeeded_and_is_being_restarted') })
        //刷新beforsetting
        this.beforCurrentLanguage = this.currentLanguage
        //设置系统语言
        this.appSetting.setLanguage(this.currentLanguage)
        //刷新页面（之后会修改为重启应用）
        this.checkIsChange()
        this.appSetting.setLanguage(this.beforCurrentLanguage)
        router.back({
          url: 'pages/SettingsPage',
          params: {
            currentLanguage: this.currentLanguage
          }
        })
      })
  }

  checkIsChange() {
    if(this.currentLanguage !== this.beforCurrentLanguage){
      this.isChange = true
    }
    else {
      this.isChange = false
    }
  }
}

