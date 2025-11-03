import { FileUtils, Log } from 'common';
import { common } from '@kit.AbilityKit';
import { FileTransferTest } from './FileTransferTest';
@Entry
@Component
struct DeviceManagerTest {
  @State testResult: string = '点击按钮开始测试';
  private context: common.UIAbilityContext | null = null;

  aboutToAppear(): void {
    try {
      this.context = getContext(this) as common.UIAbilityContext;
    } catch (error) {
      Log.e('DeviceManagerTest', `获取上下文失败: ${(error as Error).message}`);
    }
  }

  private async testFileTransfer(): Promise<void> {
    this.testResult = '测试进行中...';

    try {
      if (!this.context) {
        throw new Error('UIAbilityContext 为空，无法进行测试');
      }
      const fileTest = new FileTransferTest(this.context);
      const result = await fileTest.runAllTests();
      this.testResult = result;
    } catch (error) {
      this.testResult = `测试出错: ${(error as Error).message}`;
      Log.e('DeviceManagerTest', `测试出错: ${(error as Error).message}`);
    }
  }

  build() {
    Column({ space: 20 }) {
      Text('蓝牙文件传输功能测试')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 50 })

      Scroll() {
        Text(this.testResult)
          .fontSize(14)
          .textAlign(TextAlign.Start)
          .padding(10)
      }
      .layoutWeight(1)
      .backgroundColor('#f0f0f0')
      .border({ width: 1, color: '#ccc' })
      .margin({ bottom: 20 })

      Button('开始测试')
        .onClick(() => {
          this.testFileTransfer();
        })
        .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
  }
}
