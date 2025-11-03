import { ComponentContent, promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { BarcodeFormat } from '@ohos/zxing';
import QRCode from '../../utils/zxing/QRCode';
import { BusinessError } from '@kit.BasicServicesKit';
import PermissionManager from '../../utils/PermissionManager';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';

const TAG = 'ImageSaverPage';

@Entry
@Component
struct ImageSaverPage {
  @State message: string = '测试ZXing解码';
  @State decodedText: string = '';
  @State pixelMap: image.PixelMap | null = null;
  @State imageInfo: string = '';

  build() {
    Column() {
      // 标题
      Text('ZXing解码并保存图像')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 30 })

      // 图片预览
      if (this.pixelMap) {
        Image(this.pixelMap)
          .objectFit(ImageFit.Contain)
          .height(300)
          .width('90%')
          .margin({ bottom: 20 })
      } else {
        Column() {
          Text('没有图片')
            .fontSize(16)
            .fontColor('#666666')
        }
        .height(300)
        .width('90%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ bottom: 20 })
      }

      // 图片信息
      Text(this.imageInfo)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 10 })

      // 解码结果
      Text('解码结果: ' + this.decodedText)
        .fontSize(14)
        .fontColor('#333333')
        .margin({ bottom: 30 })

      // 测试按钮
      Button(this.message)
        .width('80%')
        .height(50)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .onClick(() => this.testZXingDecode())
        .margin({ bottom: 20 })

      // 保存到相册按钮
      Button('保存到相册')
        .width('80%')
        .height(50)
        .fontSize(18)
        .enabled(this.pixelMap !== null)
        .onClick(() => this.saveToAlbum())
        .margin({ bottom: 20 })

    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(20)
    .backgroundColor(Color.White)
  }

  private async testZXingDecode() {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const resMgr = ctx.resourceManager;
      const rawFd = resMgr.getRawFdSync('baidu_qrcode.png');
      const imageSource = image.createImageSource(rawFd);
      let pixelMap = imageSource.createPixelMapSync();

      this.pixelMap = pixelMap;

      // 获取图片信息
      const imageInfo = imageSource.getImageInfoSync();
      this.imageInfo = `尺寸: ${imageInfo.size.width} × ${imageInfo.size.height}`;

      // 使用ZXing解码
      let qrcode = new QRCode();
      let decodedText = await qrcode.decode(pixelMap, {
        width: imageInfo.size.width,
        height: imageInfo.size.height,
        format: BarcodeFormat.QR_CODE
      });

      this.decodedText = decodedText;
      this.message = '解码成功';

      promptAction.showToast({
        message: 'ZXing解码成功',
        duration: 2000
      });
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`ZXing解码失败: ${JSON.stringify(businessError)}`);

      promptAction.showToast({
        message: '解码失败，请重试',
        duration: 2000
      });
    }
  }

  private async saveToAlbum() {
    if (!this.pixelMap) {
      promptAction.showToast({ message: '没有可保存的图片', duration: 2000 });
      return;
    }

    try {

      // 使用photoAccessHelper保存图片到相册
      const context = getContext(this) as common.UIAbilityContext;
      const helper = photoAccessHelper.getPhotoAccessHelper(context);

      // 创建相册资源
      const uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpeg');

      // 打开文件进行写入
      const file = await fileIo.open(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);

      // 创建图像打包器
      const imagePackerApi = image.createImagePacker();
      const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 98 };

      // 将pixelMap打包保存到文件
      imagePackerApi.packToFile(this.pixelMap, file.fd, packOpts, (err: BusinessError) => {
        if (err) {
          console.error(`图像打包保存到文件成功： code ${err.code}, message is ${err.message}`);
          promptAction.showToast({ message: '保存失败', duration: 2000 });
        } else {
          console.info(TAG, '图像打包保存到文件成功');

          // 释放资源
          imagePackerApi.release((releaseErr: BusinessError) => {
            if (releaseErr) {
              console.error(TAG, `释放图像资源失败： code ${releaseErr.code}, message is ${releaseErr.message}`);
            } else {
              console.info(TAG, '释放图像资源成功');
            }
            // 关闭文件
            fileIo.close(file.fd);
          });

          promptAction.showToast({ message: '已保存至相册！', duration: 2000 });
        }
      });

    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`保存图片失败: ${JSON.stringify(businessError)}`);
      promptAction.showToast({ message: '保存失败，请检查权限设置', duration: 2000 });
    }
  }
}