import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { common, Context } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

const TAG = 'ImageSaver';

// 图片保存
export class ImageSaver {
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  //保存PixelMap到相册
  async savePixelMap(pixelMap: image.PixelMap | null): Promise<boolean> {
    if (!pixelMap) {
      promptAction.showToast({ message: '没有可保存的图片', duration: 2000 });
      return false;
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
      return new Promise<boolean>((resolve) => {
        imagePackerApi.packToFile(pixelMap, file.fd, packOpts, (err: BusinessError) => {
          if (err) {
            console.error(TAG, `图像打包保存到文件成功： code ${err.code}, message is ${err.message}`);
            promptAction.showToast({ message: '保存失败', duration: 2000 });
            resolve(false);
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

            // promptAction.showToast({ message: '已保存至相册！', duration: 2000 });
            resolve(true);
          }
        });
      });

    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`保存图片失败: ${JSON.stringify(businessError)}`);
      promptAction.showToast({ message: '保存失败，请检查权限设置', duration: 2000 });
      return false;
    }
  }
}