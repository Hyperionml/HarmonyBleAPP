import { IndexPageViewModel } from '../viewmodels/IndexPageViewModel';
import { Logger } from 'common';

const TAG = 'BluetoothIndicatorComponent';

/**
 * 蓝牙指示器组件
 */
@Component
export struct BluetoothIndicatorComponent {
  @ObjectLink viewModel: IndexPageViewModel;
  
  // 回调事件
  onBluetoothClick?: () => void;
  
  build() {
    if (this.viewModel.isBluetoothShowOnMain) {
      Row() {
        Blank().flexGrow(1)
        
        if (this.viewModel.isConnected) {
          // 已连接状态
          Column() {
            Image($r('app.media.bluetooth'))
              .fillColor(this.viewModel.themeColor)
              .width(60)
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) {
                  this.viewModel.isBluetoothIconPressed = true;
                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                  this.viewModel.isBluetoothIconPressed = false;
                }
              })
              .shadow({
                radius: this.viewModel.isBluetoothIconPressed ? 8 : 0,
                color: Color.Black,
                offsetX: 0,
                offsetY: 2
              })
              .onClick(() => {
                this.onBluetoothClick?.();
              })
            
            Stack() {
              if (!this.viewModel.isPowerLow) {
                Image($r('app.media.bluetooth_battery_ok'))
                  .height(52)
                  .fillColor(this.viewModel.themeColor)
              } else {
                Image($r('app.media.bluetooth_battery'))
                  .height(52)
              }
              
              Text(this.viewModel.elePower)
                .fontSize(11)
                .fontColor(Color.White)
            }
            .opacity(this.viewModel.elePower === '' ? 0 : 1)
            .onAppear(() => {
              Logger.info(TAG, `蓝牙电量显示: ${this.viewModel.elePower}, 是否低电量: ${this.viewModel.isPowerLow}`);
            })
          }
          .width(70)
        } else {
          // 未连接状态
          Image($r('app.media.bluetooth_disabled'))
            .fillColor(this.viewModel.themeColor)
            .width(60)
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.viewModel.isBluetoothIconPressed = true;
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.viewModel.isBluetoothIconPressed = false;
              }
            })
            .shadow({
              radius: this.viewModel.isBluetoothIconPressed ? 8 : 0,
              color: Color.Black,
              offsetX: 0,
              offsetY: 2
            })
            .onClick(() => {
              this.onBluetoothClick?.();
            })
        }
      }
      .margin({ right: 23 })
      .height(90)
      .width('100%')
      .justifyContent(FlexAlign.Start)
    }
  }
}
