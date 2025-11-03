import { IndexPageViewModel } from '../viewmodels/IndexPageViewModel';
import { ScanningEffectCanvasDynamic, ScanningEffectCanvasStatic } from '../component/view/ScanningEffectCanvas';

/**
 * 扫描框组件
 */
@Component
export struct ScanBoxComponent {
  @ObjectLink viewModel: IndexPageViewModel;
  
  build() {
    Stack() {
      // 静态扫描框
      ScanningEffectCanvasStatic({
        isQT: this.viewModel.isQT,
        themeColor: this.viewModel.themeColor,
        centerY: this.viewModel.scanningEffectYPercent
      })
        .hitTestBehavior(HitTestMode.Transparent)
      
      // 动态扫描效果
      ScanningEffectCanvasDynamic({
        isQT: this.viewModel.isQT,
        themeColor: this.viewModel.themeColor,
        centerY: this.viewModel.scanningEffectYPercent
      })
        .hitTestBehavior(HitTestMode.Transparent)
    }
    .hitTestBehavior(HitTestMode.Transparent)
  }
}
