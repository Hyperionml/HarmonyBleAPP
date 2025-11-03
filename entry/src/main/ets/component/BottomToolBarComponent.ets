import { IndexPageViewModel } from '../viewmodels/IndexPageViewModel';

/**
 * 底部工具栏组件
 */
@Component
export struct BottomToolBarComponent {
  @ObjectLink viewModel: IndexPageViewModel;
  
  // 回调事件
  onFeedbackClick?: () => void;
  onFlashToggle?: (isOn: boolean) => void;
  onSettingClick?: () => void;
  
  build() {
    Row() {
      // 反馈图标
      Image($r('app.media.vector_pageedit'))
        .id('Feedback')
        .width(70)
        .height(70)
        .fillColor(this.viewModel.themeColor)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.viewModel.isFeedbackIconPressed = true;
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.viewModel.isFeedbackIconPressed = false;
          }
        })
        .shadow({
          radius: this.viewModel.isFeedbackIconPressed ? 8 : 0,
          color: Color.Black,
          offsetX: 0,
          offsetY: 2
        })
        .onClick(() => {
          this.onFeedbackClick?.();
        })
        .padding(10)
        .borderRadius(8)
      
      // 闪光灯
      Image(this.viewModel.isFlashOn ? $r('app.media.vector_light_line') : $r('app.media.vector_light'))
        .id('appBarBtnLight')
        .width(70)
        .height(70)
        .fillColor(this.viewModel.themeColor)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.viewModel.isFlashIconPressed = true;
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.viewModel.isFlashIconPressed = false;
          }
        })
        .shadow({
          radius: this.viewModel.isFlashIconPressed ? 8 : 0,
          color: Color.Black,
          offsetX: 0,
          offsetY: 2
        })
        .onClick(() => {
          this.viewModel.toggleFlash();
          this.onFlashToggle?.(this.viewModel.isFlashOn);
        })
        .padding(10)
        .borderRadius(8)
      
      // 设置图标
      Image($r('app.media.vector_setting'))
        .id('appBarBtnSetting')
        .width(70)
        .height(70)
        .fillColor(this.viewModel.themeColor)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.viewModel.isSettingIconPressed = true;
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.viewModel.isSettingIconPressed = false;
          }
        })
        .shadow({
          radius: this.viewModel.isSettingIconPressed ? 8 : 0,
          color: Color.Black,
          offsetX: 0,
          offsetY: 2
        })
        .onClick(() => {
          this.onSettingClick?.();
        })
        .padding(10)
        .borderRadius(8)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceEvenly)
    .position({ bottom: 0, left: 0 })
    .padding({ right: 10, bottom: 30 })
  }
}
