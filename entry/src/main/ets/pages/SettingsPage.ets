import { promptAction, router, ThemeControl } from '@kit.ArkUI';
import { PageCustomTheme, Colors, EntryUtils } from '../common/EntryUtils';
import i18n from '@ohos.i18n';
import { AppSetting } from '../common/AppSetting';
import { UserSetting } from '../common/UserSetting';
import WindowUtil from '../utils/WindowUtil';
import { ConfirmDialog } from '../component/Dialog/ConfirmDialog';
import { ConfirmParams } from '../common/DialogFragmentManege/ConfirmParams';
import { PopupManage } from '../common/popup/PopupManage';
import { webview } from '@kit.ArkWeb';
import BuildProfile from 'BuildProfile';


interface settingState{
  themeColor: ResourceColor
  soundEnabled : boolean
  vibrationEnabled: boolean
  bluetoothEnabled: boolean
  currentLanguage: string
}

@Entry
@Component
struct SettingsPage {

  @State isLogin: boolean = false
  appSetting = new AppSetting(this.getUIContext().getHostContext()!)
  userSetting = new UserSetting(this.getUIContext().getHostContext()!)

  //进入当前页面时的各种设置参数（用于校验保存按钮的状态）
  @State beforSetting: settingState = {
    themeColor: '',
    soundEnabled: true,
    vibrationEnabled: false,
    bluetoothEnabled: false,
    currentLanguage: '简体中文'
  }

  //实时更新的页面参数
  @State themeColor: ResourceColor = ''
  @State soundEnabled: boolean = true
  @State vibrationEnabled: boolean = false
  @State bluetoothEnabled: boolean = false
  @State currentLanguage: string = '简体中文'

  //用于确认页面参数是否更改的标记
  @State isChange: boolean = false

  //生命周期函数
  async aboutToAppear(): Promise<void> {
    //初始化页面参数（参数来自持久化数据）
    //主题颜色
    const color = await this.appSetting.getTheme()
    //存储进入界面时的主题颜色
    this.beforSetting.themeColor = this.themeColor = color
    EntryUtils.setThemeColor(color)
    //其他配置
    this.soundEnabled = this.beforSetting.soundEnabled = await this.appSetting.getIsSound()
    this.vibrationEnabled = this.beforSetting.vibrationEnabled = await this.appSetting.getIsShake()
    this.bluetoothEnabled = this.beforSetting.bluetoothEnabled = (await this.appSetting.getIsBluetoothShowOnMain())!
    let UserAccessToken = await this.userSetting.getUserAccessToken()
    this.isLogin = UserAccessToken != undefined && UserAccessToken != null && UserAccessToken.length != 0
  }

  async onPageShow(): Promise<void> {
    this.currentLanguage = this.beforSetting.currentLanguage = await this.appSetting.getLanguage()
  }

  //离开页面时恢复所有设置
  async aboutToDisappear(): Promise<void> {
    //恢复主题颜色
    EntryUtils.setThemeColor(this.beforSetting.themeColor)

    //恢复数据
    await this.save()
  }

  private static controller = new webview.WebviewController();

  build() {
    Column(){
      Blank()
        .height(px2vp(WindowUtil.avoidArea.topRect.height))
        .width('100%')
        .backgroundColor($r('app.color.start_window_background'))
      //顶部标题栏
      this.buildHeader()
      //主体内容
      Column(){
        //滚动框
        Scroll(){
          Column(){
            this.buildTheme()   //主题选择模块
            this.buildLanguage() //语言设置
            this.buildRecognitionEffect() //识别特效
            this.buildDetector() //探测器

            //this.rowWithGo($r('app.string.txt_professional_model'), 20, 'pages/ProModePage')
            this.rowWithOutAny($r('app.string.web_clear_cache'), 20 ,this.clearCache)
            this.rowWithGo($r('app.string.about_app'), 5, 'pages/AboutAppPage')

            // 临时创建 Web 实例以绑定 controller
            Column() {
              Web({ src: 'about:blank' ,controller:SettingsPage.controller})
            }
            .height(0)
            .visibility(Visibility.Hidden)

            this.buildLogout()
            Row(){}.layoutWeight(1)
          }
        }
        .width('100%')
        .layoutWeight(1)

        if(this.currentLanguage == 'zh'){
          //版权信息
          this.buildRight()
        }
      }
      .layoutWeight(1)
    }
    .backgroundColor($r('app.color.lightGray'))
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
          Text($r('app.string.back'))
            .id('btnBack')
            .fontSize(16)
            .fontColor(this.themeColor)
        }
        .onClick(() => {
          router.back()
        })
      }
      .height(24)
      .backgroundColor($r('app.color.start_window_background'))
      .padding({
        left: 10,
        right: 10,
        top: 5,
        bottom: 5
      })
      Blank()
      Text($r('app.string.app_bar_setting'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .fontColor(this.themeColor)
        .padding({right:7})
      Blank()
      Button({ type: ButtonType.Normal, stateEffect: true }) {

        if(this.isChange){
          Text($r('app.string.settings_save'))
            .fontSize(16)
            .fontColor(this.themeColor)
            .opacity(1)
        }
        else {
          Text($r('app.string.settings_save'))
            .fontSize(16)
            .fontColor(this.themeColor)
            .opacity(0.8)
            .enabled(false)
        }

      }
      .backgroundColor($r('app.color.start_window_background'))
      .borderRadius(5)
      .padding({ left: 10, right: 20, top: 5, bottom: 5 })
      //保存按钮的事件
      .onClick(async () => {
        //当没有属性改变时不会进行如下逻辑
        if(!this.isChange) return

        //刷新beforsetting
        this.beforSetting = {
          themeColor: this.themeColor,
          soundEnabled: this.soundEnabled,
          vibrationEnabled: this.vibrationEnabled,
          bluetoothEnabled: this.bluetoothEnabled,
          currentLanguage: this.currentLanguage
        }
        //刷新页面（之后会修改为重启应用）
        await this.save()
        this.checkChange()
        router.back()
      })
    }
    .backgroundColor($r('app.color.start_window_background'))
    .width('100%')
    .height(40)
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({bottom: 0})

  }

  //主题选择模块
  @Builder
  buildTheme(){
    Column() {
      Column(){
        Text($r('app.string.theme'))
          .fontSize(17)
          .fontWeight(800)
          .fontColor($r('sys.color.black'))
          .width('93%')
          .padding({left:5,top:5,bottom:0})
          .backgroundColor($r('app.color.lightGray'))
          .padding({left:10,top:5})
          .margin({bottom: 5})
      }

      Column(){
        Row({ space: 32 }) {
          this.buildThemeItem('#00C853', '#9043ea', 80, 'greenTheme')
          this.buildThemeItem('#559BE9', $r('app.color.ThemeColorOrange'))
          this.buildThemeItem('#FF9500', $r('app.color.ThemeColorBlue'))
        }
        Row().height(13)
        Row({ space: 32 }) {
          this.buildThemeItem('#FF3B30', $r('app.color.redSelectColor'))
          this.buildThemeItem('#FFCC00', $r('app.color.yellowSelectColor'))
          this.buildThemeItem('#8E8E93', $r('app.color.graySelectColor'))
        }
      }
      .backgroundColor(Color.White)
      .padding({ top: 15, bottom: 15 })
      .width('100%')
      }
  }

  @Builder
  buildThemeItem(color: ResourceColor, focusBorderColor: ResourceColor, boxSize: number = 80, id?: string) {

    if(color === this.themeColor){
      // 主题方块
      Column()
        .id(id ? id : null)
        .width(boxSize)
        .height(boxSize)
        .backgroundColor(color)
        .borderRadius(8)
        .borderWidth(3)
        .borderColor(focusBorderColor)
        .onClick(() => {
          this.themeColor = color
          console.log('testtag selectColor: ' + color)
          EntryUtils.setThemeColor(color)
          this.checkChange()
        })
    }
    else {
      Column()
        .id(id ? id : null)
        .width(boxSize)
        .height(boxSize)
        .backgroundColor(color)
        .borderRadius(8)
        .onClick(() => {
          this.themeColor = color
          console.log('testtag selectColor: ' + color)
          EntryUtils.setThemeColor(color)
          this.checkChange()
        })
    }
  }

  //语言设置
  @Builder
  buildLanguage(){
    Row() {
      Text($r('app.string.app_bar_setting'))
        .fontSize(14)
        .fontColor($r('sys.color.black'))
        .flexGrow(1)
        .width('75%')
        .height(35)

      Row() {
        Text($r('app.string.currentlanguage'))
          .fontSize(17)
          .fontColor($r('app.color.languageSettingFontColor'))
        Image($r('app.media.disclosureback'))
          .width(30)
          .height(30)
          .objectFit(ImageFit.Contain)
      }
      .padding({right: 20})
    }
    .backgroundColor($r('app.color.start_window_background'))
    .width('100%')
    .padding({ left: 16, right: 20 })
    .margin({top: 5})
    .onClick(() => {
      // 跳转语言选择
      router.pushUrl({
        url: 'pages/LanguageSettingPage'
      })
    });
  }

  //识别特效
  @Builder
  buildRecognitionEffect() {
    Column() {
      Column(){
        Text($r('app.string.identify_effect'))
          .fontSize(14)
          .fontWeight(800)
          .fontColor($r('sys.color.black'))
          .width('100%')
          .padding({left:16, bottom: 4, top: 13})
          .backgroundColor($r('app.color.lightGray'))
      }

      // 声音开关
      Row() {
        Text($r('app.string.whether_to_turn_on_sound'))
          .fontSize(14)
          .fontColor($r('sys.color.black'))
          .flexGrow(1)
          .padding({ left: 7, bottom: 5 })

        Toggle({type: ToggleType.Switch, isOn: this.soundEnabled})
          .size({ width: 40, height: 25})
          .switchPointColor($r('app.color.start_window_background'))
          .onClick(() => {
            this.soundEnabled = !this.soundEnabled
            this.checkChange()
          })
      }
      .height(35)
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .backgroundColor($r('app.color.start_window_background'))
      .padding({ left: 10, right: 15 })
      .onClick(() => {
        this.soundEnabled = !this.soundEnabled
        this.checkChange()
      })

      Divider()
        .height(1.5)
        .color($r('app.color.lineColor'))
        .width('100%')
        .margin({ left: 16, right: 16 }) // 与开关缩进对齐

      // 震动开关
      Row() {
        Text($r('app.string.whether_to_open_vibration'))
          .fontSize(14)
          .fontColor($r('sys.color.black'))
          .flexGrow(1)
          .padding({ left: 7, bottom: 5 })

        Toggle({type: ToggleType.Switch, isOn: this.vibrationEnabled})
          .size({ width: 40, height: 25})
          .switchPointColor($r('app.color.start_window_background'))
          .onClick(() => {
            this.vibrationEnabled = !this.vibrationEnabled
            this.checkChange()
          })
      }
      .height(35)
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .backgroundColor($r('app.color.start_window_background'))
      .padding({ left: 10, right: 15 })
      .onClick(() => {
        this.vibrationEnabled = !this.vibrationEnabled
        this.checkChange()
      })

    }
    .backgroundColor($r('app.color.start_window_background'))
    .width('100%');
  }

  //探测器模块
  @Builder
  buildDetector(){
    Column() {
      Column(){
        Text($r('app.string.text_detector'))
          .fontSize(17)
          .fontWeight(800)
          .fontColor($r('sys.color.black'))
          .width('100%')
          .padding({ top: 13, left: 16, bottom: 4 })
          .backgroundColor($r('app.color.lightGray'))
      }

      Row() {
        Text($r('app.string.text_bluetooth_show_on_main'))
          .fontSize(14)
          .fontColor($r('sys.color.black'))
          .flexGrow(1)
          .padding({ left: 7, bottom: 5 })

        Toggle({type: ToggleType.Switch, isOn: this.bluetoothEnabled})
          .size({ width: 40, height: 25})
          .switchPointColor($r('app.color.start_window_background'))
          .onClick(() => {
            this.bluetoothEnabled = !this.bluetoothEnabled
            this.checkChange()
          })

      }
      .height(35)
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .backgroundColor($r('app.color.start_window_background'))
      .padding({ left: 10, right: 15 })
      .onClick(() => {
        this.bluetoothEnabled = !this.bluetoothEnabled
        this.checkChange()
      })

    }
    .backgroundColor($r('app.color.start_window_background'))
    .width('100%')

  }

  //登出条
  @Builder
  buildLogout(){
    if(this.isLogin){
      this.rowWithOutAny($r('app.string.login_logout'), 20, () => {
        this.isLogin = false
        //dataPreferences?.putSync('isLogin', false)
        //dataPreferences?.flush()
        this.userSetting.setUserAccessToken(null)
        this.userSetting.setUserId(null)
        this.getUIContext().getPromptAction().showToast({ message: '账号已经退出登录！' })
      })
    }
  }

  //版权信息条
  @Builder
  buildRight(){
    Row(){
      Text(BuildProfile.RecordNumber)
        .fontColor(Color.Gray)
        .fontSize(9)
        .height(5)
        .margin({top: 3})
    }
    .width('100%')
    .height(20)
    .zIndex(1)
    .justifyContent(FlexAlign.Center)
  }

  //具有向右标签的条
  @Builder
  rowWithGo(title: string | Resource, topMargin: number = 25, routerTag: string = ''){
    Row() {
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
    .height(35)
    .backgroundColor($r('app.color.start_window_background'))
    .width('100%')
    .padding({ left: 16, right: 10 })
    .margin({top: topMargin})
    .onClick(() => {
      //跳转
      router.pushUrl({
        url: routerTag
      })
    });
  }

  //没有任何标签的条
  @Builder
  rowWithOutAny(title: Resource | string, topMargin: number = 25, onClick?:() => void){
    Row() {
      Text(title)
        .fontSize(14)
        .fontColor($r('sys.color.black'))
        .flexGrow(1)
        .width('75%')
    }
    .height(35)
    .backgroundColor($r('app.color.start_window_background'))
    .width('100%')
    .padding({ left: 16, right: 10 })
    .margin({top: topMargin})
    .onClick(() => {
      if(onClick) onClick()
    })
  }

  //用于检查页面参数是否修改的函数
  private checkChange() {
    if(this.themeColor !== this.beforSetting.themeColor || this.soundEnabled !== this.beforSetting.soundEnabled
      || this.vibrationEnabled !== this.beforSetting.vibrationEnabled || this.bluetoothEnabled !== this.beforSetting.bluetoothEnabled){
      this.isChange = true
    }
    else {
      this.isChange = false
    }
  }

  private async save(){
    //恢复数据
    await this.appSetting.setThemeColor(this.beforSetting.themeColor)
    await this.appSetting.setIsShake(this.beforSetting.vibrationEnabled)
    await this.appSetting.setIsBluetoothShowOnMain(this.beforSetting.bluetoothEnabled)
    await this.appSetting.setIsSound(this.beforSetting.soundEnabled)
    await this.appSetting.setLanguage(this.beforSetting.currentLanguage)
  }

  private clearCache = () => {
    let popupManage = new PopupManage(this.getUIContext().getHostContext()!)
    let params = new ConfirmParams($r('app.string.txt_do_web_clear_cache'), $r('app.string.dialog_result_no'), $r('app.string.dialog_result_yes'),() => {}, () => {
      //WebviewController.removeCache() 必须在绑定 <Web> 实例的 controller 上调用，因此无法实现在设置页面清理缓存，用一个隐藏的webview实现
      // WebViewManager.removeCache()
      SettingsPage.controller.removeCache(true);
      promptAction.showToast({
        message: EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext()!, $r('app.string.the_modification_succeeded_and_is_being_restarted')),
        duration: 1000
      });
      setTimeout(()=>{
        this.getUIContext().getRouter().replaceUrl({ url: 'pages/IndexPage' })
          .catch((err: Error) => {
            console.error('跳转失败:', err);
          });
      },1000)
    })
    ConfirmDialog.init(this.getUIContext(), () => {
      popupManage.hide(ConfirmDialog.fragment!)
    },params)
    popupManage.show(ConfirmDialog.fragment!)
  }

}
