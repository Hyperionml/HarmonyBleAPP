import { LoadingDialog, router } from '@kit.ArkUI'
import { EntryUtils } from '../common/EntryUtils'
import { dataSharePredicates } from '@kit.ArkData';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import image from '@ohos.multimedia.image';
import { http } from '@kit.NetworkKit';
import i18n from '@ohos.i18n';
import { deviceInfo } from '@kit.BasicServicesKit';
import { AppSetting } from '../common/AppSetting';
import WindowUtil from '../utils/WindowUtil';
import { FeedbackResult } from '../common/models/json/FeedbackResult';
import { SerializationFactory } from '../common/serialization/SerializationFactory';
import { FeedbackRequest } from '../common/models/json/FeedbackRequest';
import BuildProfile from 'BuildProfile';
import { loginComponentManager } from '@kit.AccountKit';

let photoPicker = new photoAccessHelper.PhotoViewPicker();
let uris: Array<string> = [];

const title: string[] = ['扫描出错', '不知道应该怎么使用App', '程序经常崩溃', '摄像头抖动很厉害',
  '图像很清晰，但是无法识别码', '摄像头很模糊', '其他']
let isSelectedArr: string[] = []

@Entry
@Component
struct FeedbackPage {

  appSetting = new AppSetting(this.getUIContext().getHostContext()!)

  //按钮状态
  @State themeColor: ResourceColor = ''
  @State isSelected: boolean = false
  @State isCanCommit: boolean = false

  //电话，问题，图片
  @State phoneNumber: string = ''
  @State specificProblem: string = ''
  @State pixelMap: image.PixelMap | null = null

  //boolean类问题
  @State scanErr: boolean = false
  @State howToUse: boolean = false
  @State collapse: boolean = false
  @State shake: boolean = false
  @State unrecognized: boolean = false
  @State blurry: boolean = false
  @State other: boolean = false

  //生命周期函数
  async aboutToAppear(): Promise<void> {
    //初始化页面参数（参数来自持久化数据）
    //主题颜色
    const color = await this.appSetting.getTheme()
    this.themeColor = color
    EntryUtils.setThemeColor(color)
  }

  //弹窗
  async onPageShow(): Promise<void> {
    EntryUtils.requestPermission(this.getUIContext().getHostContext()!, ['ohos.permission.READ_MEDIA', 'ohos.permission.WRITE_MEDIA'])
  }

  //正文
  build() {
    Column(){
      Blank()
        .height(px2vp(WindowUtil.avoidArea.topRect.height))
        .width('100%')
        .backgroundColor($r('app.color.start_window_background'))
      //标题栏
      this.buildHeader()
      this.line()
      Scroll(){
        Column(){
          //电话号码
          this.buildNumberInput()
          this.line()
          //问题反馈
          this.buildIssueFeedback()
          this.line()
          //具体问题
          this.buildSpecificProblem()
          this.line()
          //图片
          this.buildImage()
          this.line()
          //提交按钮
          this.buildSaveButton()
        }
      }
    }
    .backgroundColor($r('app.color.lightGray'))
    .height('100%')
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
          .id('backBtn')
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
      Text($r('app.string.feedback_tv_title'))
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

  @Builder
  buildNumberInput(){
    Column(){
      Text($r('app.string.feedback_section0'))
        .fontSize(17)
        .fontWeight(800)
        .fontColor($r('sys.color.black'))
        .width('93%')
        .padding({left:5,top:5,bottom:0})
        .backgroundColor($r('app.color.lightGray'))
        .padding({left:5,top:5})
        .margin({bottom: 5})

      this.line()

      TextInput({placeholder: $r('app.string.feedback_et_phonenumber_hint'), text: $$this.phoneNumber })
        .id('phoneNumberInput')
        .fontSize(14)
        .maxLength(11)
        .type(InputType.Number)
        .fontColor(Color.Black)
        .borderRadius(0)
        .backgroundColor($r('app.color.start_window_background'))
        .placeholderColor('#8C8C8C')
        .onEditChange(()=>{
          this.checkCanCommit();
        })
    }
  }

  @Builder
  buildIssueFeedback(){
    Column(){
      Text($r('app.string.feedback_section1'))
        .fontSize(17)
        .fontWeight(800)
        .fontColor($r('sys.color.black'))
        .width('93%')
        .padding({left:5,top:5,bottom:0})
        .backgroundColor($r('app.color.lightGray'))
        .padding({left:5,top:5})
        .margin({bottom: 5})

      this.line()

      Row() {
        this.rowText($r('app.string.feedback_chk_question1'))
        Toggle({type: ToggleType.Checkbox, isOn: this.scanErr})
          .onClick(() => {
            this.scanErr = !this.scanErr
            this.checkCanCommit()
          })
      }
      .height(42)
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .backgroundColor($r('app.color.start_window_background'))
      .padding({ left: 10, right: 15 })
      .onClick(() => {
        this.scanErr = !this.scanErr
        this.checkCanCommit()
      })

      this.line()

      Row() {
        this.rowText($r('app.string.feedback_chk_question2'))
        Toggle({type: ToggleType.Checkbox, isOn: this.howToUse})
          .onClick(() => {
            this.howToUse = !this.howToUse
            this.checkCanCommit()
          })
      }
      .height(42)
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .backgroundColor($r('app.color.start_window_background'))
      .padding({ left: 10, right: 15 })
      .onClick(() => {
        this.howToUse = !this.howToUse
        this.checkCanCommit()
      })

      this.line()

      Row() {
        this.rowText($r('app.string.feedback_chk_question3'))
        Toggle({type: ToggleType.Checkbox, isOn: this.collapse})
          .onClick(() => {
            this.collapse = !this.collapse
            this.checkCanCommit()
          })
      }
      .height(42)
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .backgroundColor($r('app.color.start_window_background'))
      .padding({ left: 10, right: 15 })
      .onClick(() => {
        this.collapse = !this.collapse
        this.checkCanCommit()
      })

      this.line()

      Row() {
        this.rowText($r('app.string.feedback_chk_question4'))
        Toggle({type: ToggleType.Checkbox, isOn: this.shake})
          .onClick(() => {
            this.shake = !this.shake
            this.checkCanCommit()
          })
      }
      .height(42)
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .backgroundColor($r('app.color.start_window_background'))
      .padding({ left: 10, right: 15 })
      .onClick(() => {
        this.shake = !this.shake
        this.checkCanCommit()
      })

      this.line()

      Row() {
        this.rowText($r('app.string.feedback_chk_question5'))
        Toggle({type: ToggleType.Checkbox, isOn: this.unrecognized})
          .onClick(() => {
            this.unrecognized = !this.unrecognized
            this.checkCanCommit()
          })
      }
      .height(42)
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .backgroundColor($r('app.color.start_window_background'))
      .padding({ left: 10, right: 15 })
      .onClick(() => {
        this.unrecognized = !this.unrecognized
        this.checkCanCommit()
      })

      this.line()

      Row() {
        this.rowText($r('app.string.feedback_chk_question6'))
        Toggle({type: ToggleType.Checkbox, isOn: this.blurry})
          .onClick(() => {
            this.blurry = !this.blurry
            this.checkCanCommit()
          })
      }
      .height(42)
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .backgroundColor($r('app.color.start_window_background'))
      .padding({ left: 10, right: 15 })
      .onClick(() => {
        this.blurry = !this.blurry
        this.checkCanCommit()
      })

      this.line()

      Row() {
        this.rowText($r('app.string.feedback_chk_question7'))
        Toggle({type: ToggleType.Checkbox, isOn: this.other})
          .onClick(() => {
            this.other = !this.other
            this.checkCanCommit()
          })
      }
      .height(42)
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .backgroundColor($r('app.color.start_window_background'))
      .padding({ left: 10, right: 15 })
      .onClick(() => {
        this.other = !this.other
        this.checkCanCommit()
      })

    }
  }

  @Builder
  buildSpecificProblem(){
    Column(){
      Text($r('app.string.feedback_section2'))
        .fontSize(17)
        .fontWeight(800)
        .fontColor($r('sys.color.black'))
        .width('93%')
        .padding({left:5,top:5,bottom:0})
        .backgroundColor($r('app.color.lightGray'))
        .padding({left:5,top:5})
        .margin({bottom: 5})

      this.line()

      TextArea({placeholder: $r('app.string.feedback_et_feedback_hint'), text: $$this.specificProblem })
        .fontSize(14)
        .fontColor(Color.Black)
        .borderRadius(0)
        .backgroundColor($r('app.color.start_window_background'))
        .textOverflow(TextOverflow.Clip)
        .height(100)

    }
  }

  @Builder
  buildImage(){
    Column(){
      Text($r('app.string.feedback_section3'))
        .fontSize(17)
        .fontWeight(800)
        .fontColor($r('sys.color.black'))
        .width('93%')
        .padding({left:5,top:5,bottom:0})
        .backgroundColor($r('app.color.lightGray'))
        .padding({left:5,top:5})
        .margin({bottom: 5})

      this.line()

      Row(){
        Row(){
          if(!this.isSelected){
            Image($r('app.media.addpictures'))
              .id('addPic')
              .height(70)
              .width(70)
              .borderRadius(0)

          }
          else {
            Image(this.pixelMap)
              .height(70)
              .width(70)
              .borderRadius(0)
              .objectFit(ImageFit.Contain)
            Button('X')
              .fontSize(10)
              .fontColor(Color.White)
              .type(ButtonType.Circle)
              .height(12)
              .markAnchor({ x: 8, y: 32 })
              .onClick(() => {
                this.isSelected = false
              })
          }
        }
        .margin({left: 20})
        .height(70)
        .width(70)
        .onClick(() => {
          photoPicker.select()
            .then((res: photoAccessHelper.PhotoSelectResult) => {
              uris = res.photoUris
              this.uriGetAssets()
              if(uris.length !== 0){
                this.isSelected = true
              }
          })
        })
      }
      .backgroundColor($r('app.color.start_window_background'))
      .width('100%')
      .height(100)
    }
  }

  @Builder
  buildSaveButton(){
    Column(){
      this.commitButton()
    }
    .margin({bottom: 15})
    .height(70)
    Blank()
      .height(70)
  }

  @Builder
  rowText(title: string | Resource){
    Text(title)
      .fontSize(14)
      .fontColor($r('sys.color.black'))
      .flexGrow(1)
      .padding({ left: 7, bottom: 5 })
      .width(80)
  }

  @Builder
  line(color: ResourceColor = $r('app.color.lineColor')){
    Divider()
      .height(1.5)
      .color(color)
      .width('100%')
      .margin({ left: 16, right: 16 }) // 与开关缩进对齐
  }

  //提交按钮
  @Builder
  commitButton(){
    Button($r('app.string.submit'))
      .height(40)
      .width('70%')
      .margin({top: 15})
      .backgroundColor((this.isCanCommit)? Color.White : Color.Black)
      .fontColor(this.themeColor)
      .borderWidth(1)
      .borderColor($r('app.color.lineColor'))
      .enabled(this.isCanCommit)
      .onClick(async () => {
        await this.commit()
      })
  }

  checkCanCommit(){
    this.isCanCommit = this.phoneNumber !== '' && this.checkPhone() && (this.scanErr !== false || this.howToUse !== false ||
      this.collapse !== false || this.shake !== false || this.unrecognized !== false ||
      this.blurry !== false || this.other !== false)
  }

  //这是提交按钮后的等待弹窗
  dialogControllerProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: $r('app.string.dialog_waiting'),
    }),
  })

  /**
   * 这是进入反馈页面时弹出的提示窗口
   */
  private showAlertDialog(){
    this.getUIContext().showAlertDialog(
      {
        message: $r('app.string.txt_require_album_permission'),
        autoCancel: false,
        alignment: DialogAlignment.Center,
        primaryButton: {
          value: $r('app.string.dialog_result_no'),
          fontColor: Color.Black,
          action: () => {}
        },
        secondaryButton: {
          value: $r('app.string.dialog_result_yes'),
          fontColor: Color.Black,
          action: () => {}
        }
      }
    )
  }

  /**
   * 根据图片选择器返回的uri获取该图片的缩略图
   */
  async uriGetAssets() {
    try {
      let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.getUIContext().getHostContext());
      let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
      // 配置查询条件，使用PhotoViewPicker选择图片返回的uri进行查询
      predicates.equalTo('uri', uris[0]);
      let fetchOption: photoAccessHelper.FetchOptions = {
        fetchColumns: [photoAccessHelper.PhotoKeys.WIDTH, photoAccessHelper.PhotoKeys.HEIGHT, photoAccessHelper.PhotoKeys.TITLE, photoAccessHelper.PhotoKeys.DURATION],
        predicates: predicates
      };
      let fetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> = await phAccessHelper.getAssets(fetchOption);
      // 得到URI对应的PhotoAsset对象，读取文件的部分信息
      const asset: photoAccessHelper.PhotoAsset = await fetchResult.getFirstObject();
      // 获取缩略图
      asset.getThumbnail((err, pixelMap) => {
        if (err == undefined) {
          console.info('getThumbnail successful ' + JSON.stringify(pixelMap));
          this.pixelMap = pixelMap
        } else {
          console.error('getThumbnail fail', err);
        }
      });
    } catch (error){
      console.error(`uriGetAssets failed with err, code is ${error.code}, message is ${error.message}`);
    }
  }

  checkPhone(){
    //判断电话号码格式是否正确(正则表达式：开头为1，后面10位数字)
    const reg = /^1\d{10}$/;
    let tag = reg.test(this.phoneNumber)
    console.log(`testtag reg.test(this.phoneNumber): ${tag}`)
    return tag;
  }

  /**
   * 提交按钮的逻辑函数
   */
  async commit(){
    console.log('testtag commit开始')

    if(!this.checkPhone()){
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.feedback_tip_et_phonenumber') })
      return
    }

    let protocolBufferSerialization = SerializationFactory.create()

    //请稍后弹窗
    this.dialogControllerProgress.open()
    console.log('testtag uris:', uris);
    //将图片上传至服务器并获取图片在服务器中的url
    let imgUrl: string = ''
    if(uris.length !== 0){
      let imgRes = await protocolBufferSerialization.uploadImg(uris[0]) as FeedbackResult

      if(imgRes.IsSuccess === false){
        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.feedback_tip_failure') })
        return
      }
      imgUrl = imgRes.Url!
    }

    console.log('testtag imgUrl:', imgUrl);

    //将选择栏的所有信息组合成数组
    if(this.scanErr) isSelectedArr.push(title[0])
    if(this.howToUse) isSelectedArr.push(title[1])
    if(this.collapse) isSelectedArr.push(title[2])
    if(this.shake) isSelectedArr.push(title[3])
    if(this.unrecognized) isSelectedArr.push(title[4])
    if(this.blurry) isSelectedArr.push(title[5])
    if(this.other) isSelectedArr.push(title[6])
    console.log('testtag isSelectedArr:', isSelectedArr);

    let uploadData: FeedbackRequest = new FeedbackRequest()
    uploadData.IMEI = EntryUtils.getUUID()
    uploadData.PackageName = EntryUtils.getBundleInfoForSelfSync().name
    uploadData.SystemName = 'HarmonyOS'
    uploadData.VersionCode = EntryUtils.getBundleInfoForSelfSync().versionCode
    uploadData.VersionName = EntryUtils.getBundleInfoForSelfSync().versionName
    uploadData.Language = i18n.System.getAppPreferredLanguage()
    uploadData.DeviceBrand = deviceInfo.brand
    uploadData.ABIs = deviceInfo.abiList
    uploadData.Phone = this.phoneNumber
    uploadData.Date = EntryUtils.getFormattedSystemTime()
    uploadData.ChkQuestions = isSelectedArr
    uploadData.imageUrl = imgUrl === '' ? null : imgUrl
    uploadData.TvQuestion = this.specificProblem
    uploadData.DefaultLanguage = i18n.System.getSystemLanguage()
    console.log(`testtag uploadData: ${JSON.stringify(uploadData)}`)

    //将所有反馈信息包括图片url发送至后端
    let dataRes: FeedbackResult = await protocolBufferSerialization.requestEncrypted({
      url: BuildProfile.MAIN_SERVER + '/Feedback/AddFeedback',
      method: http.RequestMethod.POST,
      data: uploadData
    })
    console.log(`testtag dataRes: ${JSON.stringify(dataRes)}`)

    //关闭弹窗
    this.dialogControllerProgress.close()
    if(dataRes.IsSuccess === false){
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.feedback_tip_defeated') })
    }
    else {
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.feedback_tip_success') })
      router.back()
    }

  }

}


