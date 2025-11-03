import { ProgressDialog } from '../../component/Dialog/ProgressDialog';
import { PopupManage } from '../../common/popup/PopupManage';
import { ProgressParams } from '../../common/DialogFragmentManege/ProgressParams';
import { AllowAgreementDialog } from '../../component/Dialog/AllowAgreementDialog';
import { promptAction, router } from '@kit.ArkUI';
import { EngineerDialog } from '../../component/Dialog/EngineerDialog';
import { QcDialog } from '../../component/Dialog/QcDialog';
import { BleDevice, BleException, BleManager, BleReadCallback, HexUtil } from '@ohos/fastble/Index';
import fs from '@ohos.file.fs';
import { DeviceEvent, DeviceEventType, DeviceManager, QTBle } from 'devices';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { common } from '@kit.AbilityKit';
import { EventManager, Level } from 'common';
import { IndexPage } from '../IndexPage';
import { TestNapi, Utils as DUtils,CodeTypes,CodeTypesUtil } from 'decoder';
import { util } from '@kit.ArkTS';
import image from '@ohos.multimedia.image';
import { EntryUtils } from '../../common/EntryUtils';
import { ConfirmDialog } from '../../component/Dialog/ConfirmDialog';
import { ShareDialog } from '../../component/Dialog/ShareDialog';
import { ImageSaver } from '../../common/FileStorageManager';
import BuildProfile from 'BuildProfile';

interface paramObj {
    from?: string
}

@Entry
@Component
struct BailimlTestPage {
    @State mImage: image.PixelMap|null = null;
    @State popupManage: PopupManage | null = null
    @State updateProgress: number = 10
    @State isProgressShow: boolean = false
    @State content_text: string = '';

    async aboutToAppear(): Promise<void> {
        this.popupManage = new PopupManage(this.getUIContext().getHostContext()!)
        ProgressDialog.init(this.getUIContext(), () => {
            this.popupManage?.hide(ProgressDialog.fragment!)
        })

        ConfirmDialog.init(this.getUIContext(), () => {
            this.popupManage?.hide(ConfirmDialog.fragment!)
        })

        ShareDialog.init(this.getUIContext(), () => {
            this.popupManage?.hide(ShareDialog.fragment!)
        })

    }

    onPageShow(): void {
        const params = router.getParams() as paramObj;
        if (params?.from === AllowAgreementDialog.TAG) {
            this.popupManage?.show(AllowAgreementDialog.fragment!)
        }
    }

    build() {
        Column() {

            Button('截图事件')
                .backgroundColor(Color.Red)
                .onClick(() => {
                    if (BuildProfile.BLE_MODE) {
                        QTBle.setIsTakePhoto(true);
                    } else {
                        DeviceManager.setIsTakePhoto(true);
                    }
                })


            Button('拍照文件存在吗')
                .onClick(() => {
                    let filePath = '/data/storage/el2/base/haps/entry/files/screenshot.DAT'
                    let file = fs.statSync(filePath);
                    let isFile = file.isFile()
                    let size = file.size
                    console.log('testtag ' + filePath + ',size:' + size);

                    let fileMd5 = DUtils.getMD5ofFile(filePath)

                    let data = new Uint8Array([1, 2, 3, 4, 5]);
                    let data2 = new Uint8Array([1, 2, 3, 4, 5]);
                    let crc = DUtils.getCrc(data, 0, data.length);
                    let crc2 = DUtils.getCrc(data2, 0, data.length);

                    promptAction.showToast({
                        message: '调用getMD5ofFile成功:'+fileMd5+`，getCrc结果：${crc} / ${crc2}`,
                        duration: 2000
                    });
                })

            Button('存')
                .onClick(async  () => {
                    this.mImage = await readFileContent('/data/storage/el2/base/haps/entry/files/screenshot.DAT')
                    let imageSaver: ImageSaver = new ImageSaver(this.getUIContext().getHostContext()!);
                    let success = await imageSaver.savePixelMap(this.mImage)
                    if (success) {
                        promptAction.showToast({
                            message: '截图已保存至相册',
                            duration: 3000,
                            alignment: Alignment.Top,
                            offset: { dx: 0, dy: 300 },
                        });
                    } else {
                        promptAction.showToast({
                            message: '保存失败，请重试',
                            duration: 3000,
                            alignment: Alignment.Top,
                            offset: { dx: 0, dy: 300 },
                        });
                    }
                })

            Button('看看弹窗')
                .onClick(async () => {
                    this.popupManage?.show(ShareDialog.fragment!)
                })

            Image(this.mImage).width(200)
        }
    }

    appendDataText(content: string): void {
        this.content_text += content;
        this.content_text += "\n";
    }

}


async function readFileContent(filePath: string): Promise<image.PixelMap|null> {
    try {
        // 检查文件是否存在
        try {
            await fs.access(filePath);
        } catch (error) {
            console.error(`文件不存在: ${filePath}`);
            return null;
        }

        // 获取文件信息
        const fileStat = await fs.stat(filePath);
        console.log(`文件大小: ${fileStat.size} 字节`);

        // 打开文件
        const file = await fs.open(filePath, fs.OpenMode.READ_ONLY);

        // 创建缓冲区读取文件内容
        const buffer = new ArrayBuffer(fileStat.size);
        const readBytes = await fs.read(file.fd, buffer);

        // 转换为字符串并打印
        const textDecoder = util.TextDecoder.create('utf-8');
        const content = textDecoder.decodeWithStream(new Uint8Array(buffer), { stream: false });

        const width = 400;
        const height = 400;
        let grayArray = new Uint8Array(buffer);

        console.log('testtag 文件内容:');
        console.log(`testtag content: ${grayArray}`);
        console.log(`testtag 读取了 ${readBytes} 字节`);

        // 关闭文件
        await fs.close(file.fd);

        let rgba = new Uint8Array(width * height * 4);
        for (let i = 0; i < grayArray.length; i++) {
            const v = grayArray[i];
            const offset = i * 4;
            rgba[offset] = v;       // R
            rgba[offset + 1] = v;   // G
            rgba[offset + 2] = v;   // B
            rgba[offset + 3] = 255; // A
        }

        const opts: image.InitializationOptions = {
            size: { width: width, height: height },
            pixelFormat: image.PixelMapFormat.RGBA_8888, // 常用格式
            editable: true,
        };
        return image.createPixelMapSync(rgba.buffer,opts);
    } catch (error) {
        console.error(`读取文件失败: ${error.code}, ${error.message}`);
        return null;
    }
}

