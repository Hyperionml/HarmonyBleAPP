import { EntryUtils } from '../common/EntryUtils';
import { LengthMetrics, router } from '@kit.ArkUI';
import { AppSetting } from '../common/AppSetting';
import WindowUtil from '../utils/WindowUtil';


let cameraList: camera[] = [{name: '[0]广角', minFocalLength: 100.00, focalLength: 5.59, equivalentFocalLengths: 23.6, hyperFocalLength: 8310.67, sensorSize: {width: 8.2, height: 6.1}, viewAngles: 92, apertures: 1.9, cameraId: '2,3' },
  {name: '[3]超广角',minFocalLength: -1,focalLength: 1.68,equivalentFocalLengths: 15.9,hyperFocalLength: 572.73,sensorSize: {width: 3.7, height: 2.7}, viewAngles: 113,apertures: 2.2 }
]

@Entry
@Component
struct ProModePage {

  appSetting = new AppSetting(this.getUIContext().getHostContext()!)

  @State themeColor: ResourceColor = ''
  @State isChange: boolean = false

  @State hyperFocalDistance: boolean = false
  @State multiFocalLength: boolean = false
  @State isAutoCamera: boolean = true
  @State selectCameraId: string = '[0]广角'

  @State isOpenCamera: boolean[] = [true, true]

  //进入当前页面时的各种设置参数（用于校验保存按钮的状态）
  @State beforSetting: settingState = {
    hyperFocalDistance: false,
    multiFocalLength: false,
    isAutoCamera: true,
    selectCameraId: '[0]广角'
  }

  //生命周期函数
  async aboutToAppear(): Promise<void> {
    //初始化页面参数（参数来自持久化数据）
    //主题颜色
    this.themeColor = await this.appSetting.getTheme()

    this.hyperFocalDistance = this.beforSetting.hyperFocalDistance = await this.appSetting.getIsEnabledHyperfocalDistance()
    this.multiFocalLength = this.beforSetting.multiFocalLength = await this.appSetting.getIsSupportMultiFocalLength();
    this.isAutoCamera = this.beforSetting.isAutoCamera =
      await this.appSetting.existedIsAutoDecodeCamera() ? await this.appSetting.getIsAutoDecodeCamera() : true;
    this.selectCameraId = this.beforSetting.selectCameraId = await this.appSetting.getSelectedCameraId()

    //获取摄像头列表（这里采用模拟数据）
    this.isOpenCamera.push()
  }

  //离开页面时恢复所有设置
  aboutToDisappear(): void {
    //恢复数据
    this.save()
  }

  build() {
    Column(){
      //顶部标题栏
      this.buildHeader()
      this.line()

      Column(){
        Row() {
          this.buildText(EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext()!, $r('app.string.setting_lensInfo_hyperfocal_distance')))

          Toggle({type: ToggleType.Switch, isOn: this.hyperFocalDistance})
            .size({ width: 40, height: 25})
            .onClick(() => {
              this.hyperFocalDistance = !this.hyperFocalDistance
              this.checkChange()
            })
        }
        .height(35)
        .alignItems(VerticalAlign.Center)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .padding({ left: 10, right: 15 })
        .onClick(() => {
          this.hyperFocalDistance = !this.hyperFocalDistance
          this.checkChange()
        })

        this.line()

        Row() {
          this.buildText(EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext()!, $r('app.string.setting_support_multi_focal_length')))

          Toggle({type: ToggleType.Switch, isOn: this.multiFocalLength})
            .size({ width: 40, height: 25})
            .onClick(() => {
              this.multiFocalLength = !this.multiFocalLength
              this.checkChange()
            })
        }
        .height(35)
        .alignItems(VerticalAlign.Center)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .padding({ left: 10, right: 15 })
        .onClick(() => {
          this.multiFocalLength = !this.multiFocalLength
          this.checkChange()
        })

        this.line()

        Row() {
          this.buildText(EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext()!, $r('app.string.txt_auto_camera')))

          Toggle({type: ToggleType.Switch, isOn: this.isAutoCamera})
            .size({ width: 40, height: 25})
            .onClick(() => {
              this.isAutoCamera = !this.isAutoCamera
              this.checkChange()
            })
        }
        .height(35)
        .alignItems(VerticalAlign.Center)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .padding({ left: 10, right: 15 })
        .onClick(() => {
          this.isAutoCamera = !this.isAutoCamera
          this.checkChange()
        })

        this.line()

        List(){
          if(!this.isAutoCamera){
            ForEach(cameraList, (item: camera, index: number) => {
              this.buildRowCamera(item.name, index)
            })
          }
        }
        Row().layoutWeight(1)
      }
    }
    .padding({top:px2vp(WindowUtil.avoidArea.topRect.height)})
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

      Text($r('app.string.txt_professional_model'))
        .fontSize(20)
        .width('33%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .wordBreak(WordBreak.NORMAL)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .fontColor(this.themeColor)

      this.saveButton()
    }
    .backgroundColor('#FFFFFF')
    .width('100%')
    .height(40)
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({bottom: 0})

  }

  @Builder
  line(color: ResourceColor = '#ECECEC'){
    Divider()
      .height(1.5)
      .color(color)
      .width('100%')
      .margin({ left: 16, right: 16 }) // 与开关缩进对齐
  }

  @Builder
  buildSwitchItem(title: string, isOn: boolean, changeState: () => void) {

    Row() {
      Text(title)
        .fontSize(14)
        .fontColor('#000000')
        .flexGrow(1)
        .padding({ left: 7, bottom: 5 })

      Toggle({type: ToggleType.Switch, isOn: isOn})
        .size({ width: 40, height: 25})
        .onChange(() => {
          isOn = !isOn

          changeState()
          this.checkChange()
        })
    }
    .height(35)
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .padding({ left: 10, right: 15 })
  }

  @Builder
  buildRowCamera(title: string, index: number){
    Column(){
      Row() {
        this.upOrDownImg(index, () => {
          this.isOpenCamera[index] = !this.isOpenCamera[index]
        })

        Text(title)
          .fontSize(14)
          .fontColor('#000000')
          .flexGrow(1)
          .padding({ left: 7, bottom: 5 })

        this.checkImg(title)

      }
      .height(35)
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .backgroundColor('#FFFFFF')
      .padding({ left: 10, right: 15 })
      .onClick(() => {
        this.selectCameraId = title
        this.checkChange()
      })

      if(this.isOpenCamera[index]){
        Column(){
          this.buildRow(EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext()!, $r('app.string.setting_lensInfo_minimum_focus_distance')),
            (cameraList[index].minFocalLength === -1 ? '-': cameraList[index].minFocalLength + 'mm'))

          this.line()

          this.buildRow(EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext()!, $r('app.string.setting_focal_length')),
            cameraList[index].focalLength + 'mm')

          this.line()

          this.buildRow(EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext()!, $r('app.string.setting_equivalent_focal_length')),
            cameraList[index].equivalentFocalLengths + 'mm')

          this.line()

          this.buildRow(EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext()!, $r('app.string.setting_lensInfo_hyperfocal_distance')),
            cameraList[index].hyperFocalLength + 'mm')

          this.line()

          this.buildRow(EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext()!, $r('app.string.setting_physical_size')),
            cameraList[index].sensorSize.width + 'x' + cameraList[index].sensorSize.height + 'mm\u00B2')

          this.line()

          this.buildRow(EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext()!, $r('app.string.setting_view_angle')),
            cameraList[index].viewAngles + '\u00B0')

          this.line()

          this.buildRow(EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext()!, $r('app.string.setting_aperture')),
            'f/' + cameraList[index].apertures)

          this.line()

          if(cameraList[index].cameraId !== undefined && cameraList[index].cameraId !== ''){
            this.buildRow(EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext()!, $r('app.string.setting_associated_ids')),
              cameraList[index].cameraId as string, Color.Red)
          }
        }
        .backgroundColor('#f5f5f5')
      }

    }

  }

  @Builder
  upOrDownImg(isOpenIndex: number, click: () => void){
    if(this.isOpenCamera[isOpenIndex]){
      Image($r('app.media.down'))
        .height(30)
        .width(30)
        .onClick(() => {
          click()
        })
    }
    else {
      Image($r('app.media.up'))
        .height(30)
        .width(30)
        .onClick(() => {
          click()
        })
    }
  }

  @Builder
  checkImg(name: string){
    if(name === this.selectCameraId){
      Image($r('app.media.check'))
        .fillColor(this.themeColor)
        .height(30)
        .width(30)
    }
    else {
      Image($r('app.media.check'))
        .fillColor(this.themeColor)
        .height(30)
        .width(30)
        .opacity(0)
    }
  }

  //没有任何标签的条
  @Builder
  buildRow(title: string, data: string,fontColor: ResourceColor = '#000000', topMargin: number = 0){
    Row() {
      Text(title)
        .fontSize(14)
        .fontColor('#000000')
        .flexGrow(1)
        .width('60%')

      Text(data)
        .fontSize(14)
        .fontColor(fontColor)
        .flexGrow(1)
        .width('40%')
    }
    .height(20)
    .backgroundColor('#f5f5f5')
    .width('100%')
    .padding({ left: 16, right: 10 })
    .margin({top: topMargin})
  }

  @Builder
  saveButton(){
    if(this.isChange){
      Text($r('app.string.settings_save'))
        .fontSize(16)
        .fontColor(this.themeColor)
        .opacity(1)
        .maxLines(1)
        .textAlign(TextAlign.End)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .wordBreak(WordBreak.NORMAL)
        .backgroundColor('#FFFFFF')
        .borderRadius(5)
        .padding({ left: 10, right: 20, top: 5, bottom: 5 })
        .width('34%')
        //保存按钮的事件
        .onClick(() => {
          //当没有属性改变时不会进行如下逻辑
          if(!this.isChange) return

          //刷新beforsetting
          this.beforSetting = {
            hyperFocalDistance: this.hyperFocalDistance,
            multiFocalLength : this.multiFocalLength,
            isAutoCamera: this.isAutoCamera,
            selectCameraId: this.selectCameraId
          }

          //刷新页面（之后会修改为重启应用）
          this.save()
          this.checkChange()
          router.back()
        })
    }
    else {
      Text($r('app.string.settings_save'))
        .fontSize(16)
        .fontColor(this.themeColor)
        .opacity(0.5)
        .maxLines(1)
        .textAlign(TextAlign.End)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .wordBreak(WordBreak.NORMAL)
        .backgroundColor('#FFFFFF')
        .borderRadius(5)
        .padding({ left: 10, right: 20, top: 5, bottom: 5 })
        .width('34%')
        //保存按钮的事件
        .onClick(() => {
          //当没有属性改变时不会进行如下逻辑
          if(!this.isChange) return

          //刷新beforsetting
          this.beforSetting = {
            hyperFocalDistance: this.hyperFocalDistance,
            multiFocalLength : this.multiFocalLength,
            isAutoCamera: this.isAutoCamera,
            selectCameraId: this.selectCameraId
          }

          //刷新页面（之后会修改为重启应用）
          this.save()
          this.checkChange()
          router.back()
        })
    }
  }

  @Builder
  buildText(title: string){
    Text(title)
      .fontSize(14)
      .fontColor('#000000')
      .flexGrow(1)
      .padding({ left: 7, bottom: 5 })
  }

  checkChange() {
    if(this.hyperFocalDistance !== this.beforSetting.hyperFocalDistance || this.multiFocalLength !== this.beforSetting.multiFocalLength
      || this.isAutoCamera !== this.beforSetting.isAutoCamera || this.selectCameraId !== this.beforSetting.selectCameraId){
      this.isChange = true
    }
    else {
      this.isChange = false
    }
  }

  save(){
    //恢复数据
    this.appSetting.setIsEnabledHyperfocalDistance(this.beforSetting.hyperFocalDistance)
    this.appSetting.setIsSupportMultiFocalLength(this.beforSetting.multiFocalLength)
    this.appSetting.setIsAutoDecodeCamera(this.beforSetting.isAutoCamera)
    this.appSetting.setSelectedCameraId(this.beforSetting.selectCameraId)
  }
}


interface settingState{
  hyperFocalDistance: boolean
  multiFocalLength : boolean
  isAutoCamera: boolean
  selectCameraId: string
}

interface camera{
  name: string
  minFocalLength: number
  focalLength: number
  equivalentFocalLengths: number
  hyperFocalLength: number
  sensorSize: Size
  viewAngles: number
  apertures: number
  cameraId?: string
}