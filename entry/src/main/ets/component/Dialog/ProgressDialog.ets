import { CommonDialogFragment } from "../../common/DialogFragmentManege/CommonDialogFragment"
import { ProgressParams } from "../../common/DialogFragmentManege/ProgressParams"
import { ComponentContent } from "@kit.ArkUI"

export class ProgressDialog {

    // 为确保正确性，使用时一定不要对成员变量进行二次赋值，只能会用初始化方法
    static context: UIContext | null = null
    static fragment: CommonDialogFragment | null = null
    static progressNode: ComponentContent<Object>

    /**
     * 在使用该弹窗之前一定要调用初始化方法
     * @param context
     * @param didDisappear 这是弹窗消失时的回调函数，在使用PopupManage进行管理的时候，该毁掉内一定要进行hide操作确保程序执行的正确性
     */
    static init(context: UIContext, didDisappear: () => void) {
        ProgressDialog.context = context

        ProgressDialog.progressNode = new ComponentContent(ProgressDialog.context!, wrapBuilder(buildProgress),
            new ProgressParams('更新中', 0))

        let fragment = new CommonDialogFragment()

        fragment.setContext(ProgressDialog.context);
        fragment.setContentNode(ProgressDialog.progressNode)
        fragment.setOptions({
            autoCancel: false,
            // 一个渐变动画
            transition: TransitionEffect.asymmetric(
                TransitionEffect.OPACITY.animation({ duration: 500 }),
                TransitionEffect.OPACITY.animation({ delay: 200, duration: 500 })
            ),
            onDidDisappear: didDisappear

        })

        ProgressDialog.fragment = fragment
    }

}

// Progress bar
@Builder
function buildProgress(params: ProgressParams) {
    Column() {
        Row() {
            Column() {
                Row() {
                    Text('')
                        .fontSize(16)
                    Text(`${params.value}%`)
                        .fontColor(Color.Gray)
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)

                Progress({ value: 0, total: 100, type: ProgressType.Linear })
                    .width('100%')
                    .height(20)
                    .value(params.value)
                    .margin({ top: 12 })
            }
            .width('80%')

            Row() {
                Image($r('app.media.mark_circle_fill'))
                    .width(30)
                    .height(30)
                    .onClick(() => {
                        ProgressDialog.fragment!.closeDialog()
                    })
            }
            .margin({ left: 12, top: 30 })
        }

    }
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.SpaceEvenly)
    .backgroundColor('#FFF0F0F0')
    .padding({
        left: 24,
        right: 24,
        top: 16,
        bottom: 16
    })
    .width(320)
    .height(140)
    .borderRadius(24)
}