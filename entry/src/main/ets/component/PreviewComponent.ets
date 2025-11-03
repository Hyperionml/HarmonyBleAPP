import { IndexPageViewModel } from '../viewmodels/IndexPageViewModel';
import PreviewViewModel from '../viewmodels/PreviewViewModel';
import { Logger } from 'common';
const TAG = 'PreviewComponent';

/**
 * 相机预览组件
 */
@Component
export struct PreviewComponent {
  @ObjectLink viewModel: IndexPageViewModel;
  @Link previewVM: PreviewViewModel;
  
  // 回调事件
  onLoad?: () => void;
  onClickTmp?: (event: ClickEvent) => void;
  onPinchStart?: () => void;
  onPinchUpdate?: (scale: number) => void;
  onPinchEnd?: () => void;
  
  build() {
    Stack({ alignContent: Alignment.Center }) {
      // XComponent预览
      XComponent({
        type: XComponentType.SURFACE,
        controller: this.previewVM.xComponentController
      })
        .width(this.previewVM.getPreviewWidth())
        .height(this.previewVM.getPreviewHeight())
        .onLoad( () => {
          console.log('testtag XComponent onLoad触发')
          this.onLoad?.();
        })
        .onClick((event) => {
          console.log('testtag XComponent onClick触发')
          this.onClickTmp?.(event)
        })
        .gesture(
          PinchGesture({ fingers: 2 })
            .onActionStart(() => {
              Logger.info(TAG, '双指缩放开始');
              this.viewModel.originZoomBeforePinch = this.viewModel.currentZoomValue;
              this.viewModel.isZoomPinching = true;
              this.onPinchStart?.();
            })
            .onActionUpdate((event: GestureEvent) => {
              Logger.info(TAG, `双指缩放更新，scale: ${event.scale}`);
              const targetZoom = this.viewModel.originZoomBeforePinch * event.scale;
              const minZoom = 1.0;
              const maxZoom = 4.0;
              const clampedZoom = Math.min(Math.max(targetZoom, minZoom), maxZoom);
              
              this.viewModel.updateZoomValue(clampedZoom);
              this.onPinchUpdate?.(clampedZoom);
            })
            .onActionEnd(() => {
              Logger.info(TAG, '双指缩放结束');
              this.viewModel.isZoomPinching = false;
              this.onPinchEnd?.();
            })
        )

      // 聚焦框
      if (this.viewModel.isFocusBoxVisible) {
        Image($r('app.media.focus_crosshair'))
          .width(120)
          .height(120)
          .fillColor(this.viewModel.themeColor)
          .scale({ x: this.viewModel.focusScale, y: this.viewModel.focusScale })
          .position(this.viewModel.focusBoxPosition)
      }
    }
  }
}