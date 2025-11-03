import { IndexPageViewModel } from '../viewmodels/IndexPageViewModel';

/**
 * 加载提示组件
 */
@Component
export struct LoadingComponent {
  @ObjectLink viewModel: IndexPageViewModel;
  
  build() {
    if (this.viewModel.isLoading) {
      Stack() {
        // 半透明遮罩
        Column()
          .width('100%')
          .height('100%')
        
        Column({ space: 10 }) {
          Image($r('app.media.progressbar_animated'))
            .fillColor(this.viewModel.themeColor)
            .width(40)
            .height(40)
            .rotate({ angle: this.viewModel.angle, z: 1 });
          
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
      .height('100%');
    }
  }
}
