import { CommonDialogFragment } from "../../common/DialogFragmentManege/CommonDialogFragment"
import { ComponentContent, router } from "@kit.ArkUI"
import { AppSetting } from "../../common/AppSetting"
import { ShareDialogParams } from "../../common/DialogFragmentManege/ShareDialogParams"

let themeColor: ResourceColor = '#007AFF'
//二维码
let qrCodeAndroid: Resource = $r('app.media.pt_android');
let qrCodeIOS: Resource = $r('app.media.pt_ios');

//初始化页面参数
let appSetting: AppSetting

export class ShareDialog {

    static readonly TAG: string = 'ShareDialog'

    static context: UIContext | null = null
    static fragment: CommonDialogFragment | null = null
    static progressNode: ComponentContent<Object>

    static async init(context: UIContext, didDisappear: () => void) {
        ShareDialog.context = context
        appSetting = new AppSetting(context.getHostContext()!)
        themeColor = await appSetting.getTheme()

        ShareDialog.progressNode = new ComponentContent(ShareDialog.context!, wrapBuilder(ShareDialogComponent), new ShareDialogParams(0))

        let fragment = new CommonDialogFragment()

        fragment.setContext(ShareDialog.context);
        fragment.setContentNode(ShareDialog.progressNode)
        fragment.setOptions({
            autoCancel: true,
            onDidDisappear: didDisappear
        })

        ShareDialog.fragment = fragment
    }
}

@Builder
function ShareDialogComponent(param: ShareDialogParams) {
    Column({ space: 20 }) {
        Text($r('app.string.btn_share'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.Black)
            .width('80%')
            .textAlign(TextAlign.Center);

        Divider()
            .strokeWidth(1)
            .color('#AAAAAA')
            .margin({ top: 10, bottom: 10 });

        Row() {
            // Android按钮
            Button($r('app.string.android'))
                .width(120)
                .height(40)
                .fontSize(16)
                .backgroundColor(param.selectedIndex === 0 ? themeColor : '#F5F5F5')
                .fontColor(param.selectedIndex === 0 ? Color.White : themeColor)
                .borderRadius({ topLeft:8, bottomLeft:8})
                .border({
                    width: 1,
                    color: themeColor,
                    radius: 4
                })
                .onClick(() => {
                    ShareDialog.progressNode.update(new ShareDialogParams(0))
                });

            // iOS按钮
            Button($r('app.string.ios'))
                .width(120)
                .height(40)
                .fontSize(16)
                .backgroundColor(param.selectedIndex === 1 ? themeColor : '#F5F5F5')
                .fontColor(param.selectedIndex === 1 ? Color.White : themeColor)
                .borderRadius({ topRight:8, bottomRight:8})
                .border({
                    width: 1,
                    color: themeColor,
                    radius: 4
                })
                .onClick(() => {
                    ShareDialog.progressNode.update(new ShareDialogParams(1))
                });
        }

        // 显示相应二维码
        Image(param.selectedIndex!! === 0 ? qrCodeAndroid : qrCodeIOS)
            .width(200)
            .height(200)
            .objectFit(ImageFit.Contain)
            .borderRadius(8)
            .shadow({ radius: 5, color: 'rgba(0,0,0,0.1)' });

    }
    .backgroundColor('#E6E8EB')
    .padding({ top: 25, bottom: 30, left: 20, right: 20 })
    .width('95%')
    .border({radius: 15})
}