import { IndexPageViewModel } from '../viewmodels/IndexPageViewModel';

/**
 * 顶部导航栏组件
 */
@Component
export struct HeaderComponent {
  @ObjectLink viewModel: IndexPageViewModel;
  
  // 回调事件
  onBackClick?: () => void;
  onHelpClick?: () => void;
  onMenuClick?: () => void;
  @BuilderParam customMenuBuilder?: () => void;
  
  build() {
    Row() {
      // 返回按钮
      Image($r('app.media.vector_drawable_headback'))
        .id('exit')
        .width(48)
        .height(48)
        .margin({ left: 20 })
        .fillColor(this.viewModel.themeColor)
        .borderRadius(8)
        .onClick(() => {
          if(this.onBackClick){
            this.onBackClick!();
          }
        })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.viewModel.isBackIconPressed = true;
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.viewModel.isBackIconPressed = false;
          }
        })
        .shadow({
          radius: this.viewModel.isBackIconPressed ? 8 : 0,
          color: Color.Black,
          offsetX: 0,
          offsetY: 2
        })
      
      Blank()
      
      // 帮助按钮
      Image($r('app.media.vector_help'))
        .id('btnHelp')
        .width(60)
        .height(60)
        .fillColor(this.viewModel.themeColor)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.viewModel.isHelpIconPressed = true;
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.viewModel.isHelpIconPressed = false;
          }
        })
        .shadow({
          radius: this.viewModel.isHelpIconPressed ? 8 : 0,
          color: Color.Black,
          offsetX: 0,
          offsetY: 2
        })
        .onClick(() => {
          this.onHelpClick?.();
        })
        .padding(10)
        .borderRadius(8)
      
      Blank()
      
      // 菜单按钮
      Image($r('app.media.vector_add_light'))
        .id('btnPlus')
        .width(55)
        .height(55)
        .margin({ right: 20 })
        .fillColor(this.viewModel.themeColor)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.viewModel.isMenuIconPressed = true;
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.viewModel.isMenuIconPressed = false;
          }
        })
        .onClick(() => {
          this.viewModel.selectVisible = false;
          animateTo({ duration: 0 }, () => {
            this.viewModel.selectVisible = true;
          });
        })
        .shadow({
          radius: this.viewModel.isMenuIconPressed ? 8 : 0,
          color: Color.Black,
          offsetX: 0,
          offsetY: 2
        })
        .bindMenu(
          this.viewModel.selectVisible,
          this.customMenuBuilder,
          {
            offset: { x: 50, y: 0 },
            onDisappear: () => {
              this.viewModel.selectVisible = false;
            }
          } as MenuOptions
        )
    }
    .padding({ top: 10 })
    .width('100%')
    .justifyContent(FlexAlign.SpaceEvenly)
    .alignItems(VerticalAlign.Top)
  }
}
