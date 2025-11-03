import { IndexPageViewModel } from '../viewmodels/IndexPageViewModel';
import { Logger } from 'common';

const TAG = 'ZoomSliderComponent';

/**
 * 缩放滑块组件
 */
@Component
export struct ZoomSliderComponent {
  @ObjectLink viewModel: IndexPageViewModel;
  
  // 回调事件
  onZoomChange?: (value: number) => void;
  
  build() {
    Column() {
      Row() {
        Text($r('app.string.tool_zoom'))
          .fontSize(14)
          .fontColor(Color.White);
        
        Text(this.viewModel.zoomText)
          .id('seekbarZoom')
          .fontSize(14)
          .fontColor(Color.White)
          .margin({ left: 8 });
      }
      .padding({ left: 8 })
      .width('100%')
      
      Slider({
        value: this.viewModel.currentZoomValue,
        min: 1.0,
        max: 4.0,
        step: 0.1
      })
        .blockColor(this.viewModel.themeColor)
        .trackColor(Color.White)
        .selectedColor(this.viewModel.themeColor)
        .onChange((value: number) => {
          Logger.info(TAG, `缩放条值变化: ${value}`);
          this.viewModel.updateZoomValue(value);
          this.onZoomChange?.(value);
        });
    }
    .width('90%')
    .padding({ left: 20, right: 20, bottom: 13 })
    .backgroundColor(Color.Transparent)
    .borderRadius(8)
    .position({ bottom: this.viewModel.sliderBottom, left: 20 })
  }
}