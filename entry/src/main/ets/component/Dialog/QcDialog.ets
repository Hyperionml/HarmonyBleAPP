import { CommonDialogFragment } from "../../common/DialogFragmentManege/CommonDialogFragment"
import { ComponentContent } from "@kit.ArkUI"
import { QcParams } from "../../common/DialogFragmentManege/QcParams"

export class QcDialog {

    static readonly TAG: string = 'QcDialog'

    static context: UIContext | null = null
    static fragment: CommonDialogFragment | null = null
    static progressNode: ComponentContent<Object>

    static async init(context: UIContext, didDisappear: () => void) {
        QcDialog.context = context

        QcDialog.progressNode = new ComponentContent(QcDialog.context!, wrapBuilder(qcDialogComponent),
            new QcParams('A', '', ''))

        let fragment = new CommonDialogFragment()

        fragment.setContext(QcDialog.context);
        fragment.setContentNode(QcDialog.progressNode)
        fragment.setOptions({
            autoCancel: false,
            onDidDisappear: didDisappear
        })

        QcDialog.fragment = fragment
    }
}

// Confirm the pop-up window
@Builder
function qcDialogComponent(qcParams: QcParams) {
    Column() {
        Column() {
            // 品质
            Row(){
                Text($r('app.string.tv_quality_key'))
                    .layoutWeight(5.5)
                    .margin({bottom: 5})
                    .textAlign(TextAlign.End)

                Text(qcParams.quality)
                    .fontSize(50)
                    .layoutWeight(4.5)
            }
            .margin({bottom: 10})

            // 异常单个数
            Row(){
                Text($r('app.string.txt_print_error_count_tip'))
                    .textAlign(TextAlign.End)
                    .layoutWeight(5.5)

                Text(qcParams.errorCountTip)
                    .layoutWeight(4.5)
            }
            .margin({bottom: 10})

            // 印点色深
            Row(){
                Text($r('app.string.txt_print_deep_tip'))
                    .textAlign(TextAlign.End)
                    .layoutWeight(5.5)

                Text(qcParams.deepTip)
                    .layoutWeight(4.5)
            }

        }
        .justifyContent(FlexAlign.SpaceEvenly)
        .padding(15)
        //.height(120)

        Divider()
            .height(1.5)
            .color($r('app.color.lineColor'))
            .width('100%')
            .margin({ left: 16, right: 16 })

        Row() {
            Text($r('app.string.dialog_close'))
                .onClick(() => {
                    QcDialog.fragment?.closeDialog()
                })
                .width('49%')
                .height('100%')
                .textAlign(TextAlign.Center)

            Divider()
                .vertical(true)
                .height(1.5)
                .color($r('app.color.lineColor'))
                .height('100%')

            Text($r('app.string.title_product'))
                .onClick(() => {
                    QcDialog.fragment?.closeDialog()
                })
                .width('49%')
                .height('100%')
                .textAlign(TextAlign.Center)
        }
        .height(50)
    }
    .width(350)
    .padding({ bottom: 8 })
    .borderRadius(32)
    .backgroundColor(Color.White)
}