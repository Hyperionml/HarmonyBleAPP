import { CommonDialogFragment } from "../../common/DialogFragmentManege/CommonDialogFragment"
import { ComponentContent } from "@kit.ArkUI"

export class EngineerDialog {

    static context: UIContext | null = null
    static fragment: CommonDialogFragment | null = null
    static progressNode: ComponentContent<Object>
    static text: string

    static async init(context: UIContext, didDisappear: () => void) {
        EngineerDialog.context = context

        EngineerDialog.progressNode = new ComponentContent(EngineerDialog.context!, wrapBuilder(engineerDialogComponent))

        let fragment = new CommonDialogFragment()

        fragment.setContext(EngineerDialog.context);
        fragment.setContentNode(EngineerDialog.progressNode)
        fragment.setOptions({
            autoCancel: false,
            onDidDisappear: didDisappear
        })

        EngineerDialog.fragment = fragment
    }
}

// Confirm the pop-up window
@Builder
function engineerDialogComponent() {
    Column() {
        Row(){
            Blank()

            Text('工程师模式')
                .fontSize(24)
                .width('70%')
                .fontColor(Color.Black)
                .textAlign(TextAlign.Center)

            Image($r('app.media.close'))
                .width('11%')
                .fillColor(Color.Black)
                .onClick(() => {
                    EngineerDialog.fragment?.closeDialog()
                })
        }
        .padding({top: 15})

        Column() {
            TextInput({text: EngineerDialog.text!!})
                .fontSize(14)
                .maxLength(11)
                .type(InputType.Number)
                .fontColor(Color.Black)
                .borderRadius(0)
                .backgroundColor($r('app.color.start_window_background'))
        }
        .justifyContent(FlexAlign.SpaceEvenly)

        Divider()
            .height(1.5)
            .color($r('app.color.lineColor'))
            .width('100%')
            .margin({ left: 16, right: 16,  bottom: 20})

        Row() {
            Text('提交')
                .border({
                    width: 2,
                    color: $r('app.color.lineColor'),
                    radius: 18
                })
                .fontColor($r('sys.color.black'))
                .onClick(() => {
                    EngineerDialog.fragment?.closeDialog()
                })
                .width('80%')
                .height('100%')
                .textAlign(TextAlign.Center)
        }
        .height(50)
    }
    .width(350)
    .padding({ bottom: 8 })
    .borderRadius(20)
    .backgroundColor(Color.White)
}