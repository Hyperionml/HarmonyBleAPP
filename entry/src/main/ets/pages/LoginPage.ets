import { router } from '@kit.ArkUI';
import { EntryUtils } from '../common/EntryUtils';
import http from '@ohos.net.http';
import { AppSetting } from '../common/AppSetting';
import { UserSetting } from '../common/UserSetting';
import WindowUtil from '../utils/WindowUtil';
import BuildProfile from 'BuildProfile';
import { LoginResult } from '../common/models/json/LoginResult';
import { buildLoginUrl, ProductType } from '../common/ProductType';
import { WebViewType } from './WebPage';


const privacyUrl = `${BuildProfile.Privacy}?language=zh-cn`;
const contractUrl = `${BuildProfile.Contract}?language=zh-cn`;

@Entry
@Component
struct LoginPage {
  @State account: string = ''
  @State password: string = ''

  // 记住密码
  @State rememberPassword: boolean = false
  @State agreeTerms: boolean = false
  @State showPassword: boolean = false
  @State themeColor: ResourceColor = '#559BE9'
  //存储明文和密文
  @State passwordPlain: string = ''
  @State passwordMasked: string = ''
  // 弹窗
  @State showLoading: boolean = false
  @State isLogin: boolean = false
  @State isLoading: boolean = false //控制加载提示显示
  @State angle: number = 0

  //初始化页面参数
  appSetting = new AppSetting(this.getUIContext().getHostContext()!)
  userSetting = new UserSetting(this.getUIContext().getHostContext()!)

  /**
   * 生命周期，要在这里设置主题色，并获取登录状态信息
   * @returns
   */
  async aboutToAppear(): Promise<void> {
    console.log('页面即将显示，开始初始化...');

    //主题颜色
    this.themeColor = await this.appSetting.getTheme()
    EntryUtils.setThemeColor(this.themeColor)

    // 同步登录状态
    await this.syncLoginState()

    // 检查记住的密码状态
    const savedAccount = await this.userSetting.getUserName() || ''
    const savedRememberPassword = await this.userSetting.getIsRememberPassword() || false
    
    if (savedAccount) {
      this.account = savedAccount;
    }
    
    // 恢复记住密码勾选状态
    this.rememberPassword = savedRememberPassword;
    
    // 如果勾选了记住密码，则加载保存的密码
    if (savedRememberPassword) {
      this.password = await this.userSetting.getUserPassword() || ''
    } else {
      this.password = ''
    }
  }

  // 页面显示时同步状态（这一步可能是多余的）
  async onPageShow(): Promise<void> {
    await this.syncLoginState();
  }

  // 同步登录状态
  private async syncLoginState() {
    const accessToken = await this.userSetting.getUserAccessToken()
    this.isLogin = accessToken != undefined && accessToken != null && accessToken != ''
    console.log(`testtag 同步登录状态: ${this.isLogin}, AccessToken: ${accessToken}`);
  }

  build() {
    Stack(){
      Column() {
        Blank()
          .height(px2vp(WindowUtil.avoidArea.topRect.height))
          .width('100%')
          .backgroundColor($r('app.color.start_window_background'))
        // 顶部标题栏
        this.buildHeader()
        // 展示登录logo的区域
        this.buildLoginArea()
        // 输入框
        this.buildInput()
        // 记住密码的复选框
        this.buildRememberPassword()
        // 登录按钮
        this.buildLoginButton()
        // 同意协议的复选框
        this.buildAgreeTerms()
        Blank()
          .layoutWeight(1)
          .margin({ top: 10 })
        // 一个宝绅的logo
          this.buildLogo()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#007AFF')
      .padding({ bottom: 10 })

      // 这是在登录时的一个等待提示框
      if (this.isLoading) {
        this.buildLoading(); // 显示请稍等...
      }
    }
  }

  /**
   * 等待提示框
   */
  @Builder
  buildLoading() {
    Stack() {
      // 半透明遮罩
      Column()
        .width('100%')
        .height('100%')

      Column({ space: 10 }) {
        Image($r('app.media.progressbar_animated'))
          .fillColor(this.themeColor)
          .width(40)
          .height(40)
          .rotate({ angle: this.angle, z: 1 }); // 绑定旋转角度

        Text($r('app.string.dialog_waiting'))
          .fontSize(16)
          .fontColor(Color.White);
      }
      .width(120)
      .height(120)
      .borderRadius(12)
      .padding(20)
      .backgroundColor('rgba(30,30,30,0.5)')
      .alignItems(HorizontalAlign.Center);
    }
    .width('100%')
    .height('100%')
    .onAppear(() => {
      this.startRotation(); // 组件出现时启动动画
    });
  }

  // 标题栏
  @Builder
  buildHeader() {
    Row({ space: 10 }) {
      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Row({ space: 5 }) {
          Image($r('app.media.headback'))
            .width(16)
            .height(16)
            .fillColor(this.themeColor)
          Text($r('app.string.back'))
            .id('backButton')
            .fontSize(16)
            .fontColor(this.themeColor)
            .onClick(()=>{
              router.back();
            })
        }
      }
      .height(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(5)
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })

      Blank()

      Text($r('app.string.login'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .fontColor(this.themeColor)

      Blank()

      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Text($r('app.string.login_logout'))
          .id('logoutButton')
          .fontSize(16)
          .fontColor(this.themeColor)
          .opacity(this.isLogin ? 1 : 0.8) //未登录时是半透明
          //.onClick(() => this.handleLogout())
      }
      .backgroundColor('#FFFFFF')
      .borderRadius(5)
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      //.enabled(this.isLogin) //未登录时不可点
      .onClick(() => {
        if(!this.isLogin)return;
        this.handleLogout();
      })
    }
    .backgroundColor('#FFFFFF')
    .width('100%')
    .height(40)
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 20, right: 20 })
    .margin({ bottom: 20 })
  }


  @Builder
  buildLoginArea() {
    Column({ space:10 }) {
      Image($r('app.media.big_icon'))
        .width(110)
      Image($r('app.media.bsn_qt'))
        .width(110)
    }
    .margin({top:30})
  }

  /**
   * 输入框
   */
  @Builder
  buildInput() {
    Column({ space: 8 }) {
      // 账号输入框
      Row() {
        Image($r('app.media.ic_login_person'))
          .width(24)
          .height(24)
          .margin({ left: 16, top: 13, bottom: 13 })
          .fillColor(this.themeColor)
        Divider()
          .width(1)
          .height(24)
          .color('#CCCCCC')
        TextInput({ placeholder : ($r('app.string.login_account')),
        text:this.account})
          .fontColor(this.themeColor)
          .width('80%')
          .height(40)
          .backgroundColor('#FFFFFF')
          .padding({ left: 8 })
          .placeholderColor(this.themeColor)
          .borderRadius(8)
          .onChange((value: string): void => {
            this.account = value;
          })
      }
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .width('80%')
      .alignSelf(ItemAlign.Center)
      .margin({ top: 24 })

      // 密码输入框
      Row() {
        Image($r('app.media.ic_login_pw'))
          .width(24)
          .height(24)
          .margin({ left: 16, top: 13, bottom: 13 })
          .fillColor(this.themeColor)
        Divider()
          .width(1)
          .height(24)
          .color(this.themeColor)
          .margin({ top: 13, bottom: 13, left: 5 })
        TextInput({ placeholder: ($r('app.string.login_password')) ,  text: this.password })
          .showPasswordIcon(false)
          .fontColor(this.themeColor)
          .layoutWeight(1)// 使用权重占据剩余空间
          .height(40)
          .backgroundColor('#FFFFFF')
          .padding({ left: 8 })
          .placeholderColor(this.themeColor)
          .borderRadius(8)
          .type(this.showPassword ? InputType.Normal : InputType.Password)
          .onChange((value: string): void => {
            this.password = value;
          })
        //密码显示/隐藏切换图标
        Image(this.showPassword
          ? $r('app.media.ic_csee_pass')
          : $r('app.media.ic_nosee_pass')
        )
          .id('passwordEyeIcon')
          .width(24)
          .height(24)
          .fillColor(this.themeColor)
          .margin({ right: 10 })
          .onClick(() => {
            // 点击切换显示状态
            this.showPassword = !this.showPassword;
          })
      }
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .width('80%')
      .margin({ top: 10 })
    }
    .width('100%')
  }

  @Builder
  buildRememberPassword() {
    Row({ space: 8 }) {
      Checkbox()
        .select($$this.rememberPassword)
        .id('rememberPasswordCheckbox')
        .selectedColor(this.themeColor)
        .shape(CheckBoxShape.ROUNDED_SQUARE)
        .onChange(async(value: boolean) => {
          // 立即保存状态变化
          if (this.userSetting) {
            await this.userSetting.setIsRememberPassword(this.rememberPassword);
          }
        })
      // Image(this.rememberPassword
      //   ? $r('app.media.icon_checkbox_selected')
      //   : $r('app.media.icon_checkbox_not_selected')
      // )
      //   .width(16)
      //   .height(16)
      //   .onClick(async () => {
      //     this.rememberPassword = !this.rememberPassword;
      //     // 立即保存状态变化
      //     if (this.userSetting) {
      //       await this.userSetting.setIsRememberPassword(this.rememberPassword);
      //     }
      //   });

      Text($r('app.string.login_check_password'))
        .fontSize(15)
        .fontColor('#FFFFFF')
        .onClick(async () =>{
          this.rememberPassword = !this.rememberPassword;
          if(this.userSetting) {
            await this.userSetting.setIsRememberPassword(this.rememberPassword)
          }
        })
    }
    .width('80%') // 与输入框同宽
    .margin({ top: 20 })
    .alignSelf(ItemAlign.Center) // 居中对齐
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildLoginButton(){
    Button($r('app.string.login'))
      .id('login')
      .margin({top: 20})
      .width('80%')
      .height(48)
      .backgroundColor((this.account.trim()!== '' && this.password.trim()!== '')? '#4DA8FF' : Color.Black)
      .fontSize(18)
      .borderRadius(8)
      .enabled(this.account != '' && this.password != '')
      .onClick(async () => {
        if (!this.account.trim() || !this.password.trim()) {
          console.log('账号或密码为空，不执行登录');
          return;
        }

        if (!this.agreeTerms) {
          console.log('账号密码有效，但未勾选协议');
          this.getUIContext().getPromptAction().showToast({
            message: 'QT:' + EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext(), $r('app.string.txt_allow_agreement_first')),
            duration: 3000,
            alignment: Alignment.Top,
            offset: { dx: 0, dy: 300 },
          });
          return;
        }

        console.log('登录按钮点击事件触发，开始登录');
        await this.handleLogin();
       })

  }

  @Builder
  buildAgreeTerms() {
    Column(){
      Row( {space:8} ) {
        Checkbox()
          .id('agreeTermsCheckbox')
          .select($$this.agreeTerms)
          .selectedColor(this.themeColor)
          .shape(CheckBoxShape.ROUNDED_SQUARE)
          .onChange((value: boolean) => {
            this.agreeTerms = value;
          })
        // Image(this.agreeTerms
        //   ? $r('app.media.icon_checkbox_selected')
        //   : $r('app.media.icon_checkbox_not_selected')
        // )
        //   .width(16)
        //   .height(16)
        //   .onClick(() => {
        //     this.agreeTerms = !this.agreeTerms;
        //   });
        Text($r('app.string.txt_read_and_allow'))
          .fontSize(15)
          .fontColor(Color.Orange)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis }) // 超出省略
          .flexShrink(1) // 允许缩小
          .layoutWeight(1) // 占据剩余空间
          .onClick(() => {
            this.agreeTerms = !this.agreeTerms;
          })
      }
      .width('80%') // 与输入框同宽
      .margin({ top: 20 })
      .alignSelf(ItemAlign.Center) // 居中对齐
      .alignItems(VerticalAlign.Center)

      Row({ space: 30 }) {
        Text($r('app.string.privacy_policy'))
          .fontSize(14)
          .fontColor(Color.White)
          .fontWeight(800)
          .decoration({
            type: TextDecorationType.Underline,
            color: Color.White
          })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/WebPage',
              params: { url: privacyUrl,
                type: WebViewType.Privacy
              }
            });
          })
        Text($r('app.string.contract_protocol'))
          .fontSize(14)
          .fontColor(Color.White)
          .fontWeight(800)
          .decoration({
            type: TextDecorationType.Underline,
            color: Color.White
          })
          .onClick(()=>{
            router.pushUrl({
              url: 'pages/WebPage',
              params: {
                url: contractUrl,
                type: WebViewType.Contract
              }
            });
          })
      }
      .width('80%') // 与输入框同宽
      .margin({ top: 10 })
      .alignSelf(ItemAlign.Center) // 居中对齐
      .justifyContent(FlexAlign.Center) // 内容居中
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildLogo(){
    Column(){
      Image($r('app.media.logo2'))
        .width (92)
    }
    .width('100%')
    .margin({ bottom: 30 })
    .alignItems(HorizontalAlign.Center)
  }
  /**
   * 点击登录事件
   */
  private async handleLogin() {
    console.log('开始登录请求');
    this.isLoading = true;
    console.log(`当前输入: 账号=${this.account}, 密码=${this.password}`);

    try {
      // 校验协议勾选
      if (!this.agreeTerms) {
        console.log('用户未同意协议');
        this.getUIContext().getPromptAction().showToast({
          message: 'QT:' + EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext(), $r('app.string.txt_allow_agreement_first')),
          duration: 3000,
          alignment: Alignment.Top,
          offset: { dx: 0, dy: 300 },
        });
        this.isLoading = false;
        return;
      }

      const baseLoginUrl = buildLoginUrl();  //通过buildLoginUrl获取基础 URL
      const loginUrl = `${baseLoginUrl}?userId=${this.account}&password=${this.password}`;  // 再拼接账号密码参数
      console.log('请求地址:', loginUrl);

      let request = http.createHttp();
      let response = await request.request(
        loginUrl,
        {
          method: http.RequestMethod.GET,
          header: { 'Content-Type': 'application/json' },
          readTimeout: 5000,
          connectTimeout: 5000,
          expectDataType: http.HttpDataType.OBJECT
        }
      );
      console.log('响应状态码:', response.responseCode);
      console.log('testtag 完整响应:', JSON.stringify(response.result, null, 2));

      // 处理响应
      if (response.responseCode === 200) {
        const result = LoginResult.fromPlainObject(response.result);

        if (result.isSuccess() && result.getData()) {
          // 保存登录状态
          const data = result.getData();
          await this.saveLoginState(data!.getAccessToken(), data!.getUserId());

          // 跳转到首页
          router.replaceUrl({
            url: 'pages/IndexPage',
            params: { isLoginSuccess: 'true'
            }
          });

        } else {
          this.getUIContext().getPromptAction().showToast({
            message: 'QT:'+EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext(), $r('app.string.login_tip_name_and_password')),
            duration:3000,
            alignment: Alignment.Top,
            offset: { dx: 0, dy: 300 },
          });
        }
      } else {
      }
    } catch (error) {
      console.error('登录异常:', error);
    } finally {
      this.isLoading = false;
    }
  }

  //保存登录状态
  private async saveLoginState(accessToken: string, userId: string): Promise<void> {
    if (!this.userSetting) return;
    try {
      await this.userSetting.setUserName(this.account);

      if (this.rememberPassword) {
        await this.userSetting.setUserPassword(this.password); //保存密码
        await this.userSetting.setIsRememberPassword(true);
      } else {
        await this.userSetting.setUserPassword(''); // 清空密码
        await this.userSetting.setIsRememberPassword(false);
      }

      await this.userSetting.setIsAutoLogin(false); // 按需设置
      console.log('testtag accessToken：' + accessToken);
      await this.userSetting.setUserAccessToken(accessToken); // 保存Token
      await this.userSetting.setUserId(userId); // 保存用户 ID

      this.isLogin = true;

      console.log('testtag 登录状态保存成功');
      console.log('testtag UserAccessToken：' + await this.userSetting.getUserAccessToken());
    } catch (error) {
      console.error('testtag 保存登录状态失败:', error);
    }
  }

  // 登出
  private async handleLogout() {
    if (this.userSetting) {
      await this.userSetting.setUserAccessToken(null); // 传入null清空Token
      await this.userSetting.setUserId(null); // 清空用户ID

      // 根据记住密码状态决定是否清空密码
      if (!this.rememberPassword) {
        await this.userSetting.setUserPassword('');
        await this.userSetting.setIsRememberPassword(false);
        // 不勾选记住密码时，清空密码框
        this.password = '';
      }

      await this.userSetting.setIsAutoLogin(false);
    }
    this.isLogin = false;

    this.getUIContext().getPromptAction().showToast({
      message: 'QT:' + EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext(), $r('app.string.login_tip_logout')),
      duration: 3000,
      alignment: Alignment.Top,
      offset: { dx: 0, dy: 300 },
    });
  }

  //请稍后...动画效果
  startRotation() {
    setInterval(() => {
      this.angle += 10;  // 每次增加 10 度
      if (this.angle >= 360) {
        this.angle = 0;  // 重置角度
      }
    }, 150);
  }
}

export { LoginPage };
