import { IndexPageViewModel } from '../viewmodels/IndexPageViewModel';
import { Decoder } from '../decoder/Decoder';
import { EntryUtils } from '../common/EntryUtils';
import { Logger } from 'common';

const TAG = 'ModeSwitchComponent';

/**
 * QT/QR模式切换组件
 */
@Component
export struct ModeSwitchComponent {
  @ObjectLink viewModel: IndexPageViewModel;
  // 回调事件
  onModeSwitch?: (isQT: boolean) => void;
  onPermissionRequest?: () => void;
  onShowToast?: (msg: string, time: number) => void;
  onZoomChange?: (value: number) => void;

  build() {
    Row() {
      Column() {
        if(this.viewModel.getCameraPermission){
          Image(this.viewModel.isQT ? $r('app.media.qt_code') : $r('app.media.icon_scanqt'))
            .width(this.viewModel.isQTSize)
            .height(this.viewModel.isQTSize)
            .fillColor(this.viewModel.themeColor)
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.viewModel.isModeIconPressed = true;
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.viewModel.isModeIconPressed = false;
              }
            })
            .shadow({ radius: this.viewModel.isModeIconPressed ? 8 : 0, color: Color.Black, offsetX: 0, offsetY: 2 })
          Text(this.viewModel.isQT ? 'QT' : 'QR')
            .fontSize(17)
            .fontWeight(500)
            .fontColor(this.viewModel.themeColor)
            .margin({ top: 2 })
        }
        else
        {
          Image($r('app.media.qt_code'))
            .width(this.viewModel.isQTSize)
            .height(this.viewModel.isQTSize)
            .fillColor(this.viewModel.themeColor)
            .shadow({ radius: this.viewModel.isModeIconPressed ? 8 : 0, color: Color.Black, offsetX: 0, offsetY: 2 })
          Text($r('app.string.permission_title'))
            .fontSize(17)
            .fontWeight(500)
            .fontColor(this.viewModel.themeColor)
            .margin({ top: 2 })
          // 背景波纹（无限循环）
          Circle()
            .width(this.viewModel.isQTSize)
            .height(this.viewModel.isQTSize)
            .fill(this.viewModel.themeColor)
            .opacity(this.viewModel.rippleOpacity)                         //透明度
            .scale({ x: this.viewModel.rippleScale, y: this.viewModel.rippleScale }) //缩放比, x: 横向缩放比, y: 纵向缩放比
            .position({ x: 4, y: 0 })                            // 居中
            .onAppear(() => {
              this.startRippleAnimation()
            })
        }
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        Logger.info(TAG, `模式切换按钮被点击，当前QT模式: ${this.viewModel.isQT}，相机权限: ${this.viewModel.getCameraPermission}`);

        if(!this.viewModel.getCameraPermission){
          Logger.info(TAG, "无相机权限，请求权限");
          this.onPermissionRequest?.(); // 触发Page的getPermission方法
          return;
        }

        let newStatus = !this.viewModel.isQT
        Logger.info(TAG, `切换模式从 ${this.viewModel.isQT} 到 ${newStatus}`);

        //保存当前模式的缩放值
        if(this.viewModel.isQT) {
          this.viewModel.qtZoomValue = this.viewModel.currentZoomValue;
        } else {
          this.viewModel.qrZoomValue = this.viewModel.currentZoomValue;
        }

        //切换模式状态
        this.viewModel.isQT = newStatus

        // 加载新模式的缩放值
        if (this.viewModel.isQT) {
          this.viewModel.currentZoomValue = this.viewModel.qtZoomValue;
          if (this.onShowToast) {
            this.onShowToast(EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext()!, $r('app.string.txt_qtcode_supported')), 1000);
          }
        } else {
          this.viewModel.currentZoomValue = this.viewModel.qrZoomValue;
          if (this.onShowToast) {
            this.onShowToast(EntryUtils.getStringByResourceManager(this.getUIContext().getHostContext()!, $r('app.string.txt_barcode_supported')), 1000);
          }
        }
        this.viewModel.zoomText = this.viewModel.currentZoomValue.toFixed(1);
        Logger.info(TAG, `更新缩放文本为: ${this.viewModel.zoomText}`);

        // 通过回调通知父组件更新缩放值和模式
        if (this.onZoomChange) {
          this.onZoomChange(this.viewModel.currentZoomValue);
        }

        // 通知模式切换完成
        if (this.onModeSwitch) {
          Logger.info(TAG, `调用onModeSwitch，QT模式: ${this.viewModel.isQT}`);
          this.onModeSwitch(this.viewModel.isQT);
        }
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .position({ bottom: this.viewModel.isQTBottom, left: 0 })

  }

  // 点击授权的波纹特效
  startRippleAnimation() {
    const run = () => {
      animateTo({
        duration: 1600,                 // 动画持续 1.6 秒
        curve: Curve.EaseOut,           // 缓出曲线，先快后慢
        onFinish: () => {               // 动画结束后的回调
          // 重置
          animateTo({ duration: 0 }, () => {
            this.viewModel.rippleScale = 1
            this.viewModel.rippleOpacity = 0.6
            if(!this.viewModel.getCameraPermission)
              run() // 再次循环
          })
        }
      }, () => {
        this.viewModel.rippleScale = 2.5          // 波纹放大到 2.5 倍
        this.viewModel.rippleOpacity = 0          // 同时透明度变为 0（淡出）
      })
    }
    if(!this.viewModel.getCameraPermission)
      run()
  }
}