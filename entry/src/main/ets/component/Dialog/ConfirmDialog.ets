import { CommonDialogFragment } from "../../common/DialogFragmentManege/CommonDialogFragment"
import { ComponentContent, router } from "@kit.ArkUI"
import { common } from "@kit.AbilityKit"
import { ConfirmParams } from "../../common/DialogFragmentManege/ConfirmParams"


export class ConfirmDialog {

    static readonly TAG: string = 'ConfirmDialog'

    static context: UIContext | null = null
    static fragment: CommonDialogFragment | null = null
    static progressNode: ComponentContent<Object>

    static async init(context: UIContext, didDisappear: () => void, params?:ConfirmParams) {
        ConfirmDialog.context = context

        if(!params){
            params = new ConfirmParams($r('app.string.confirm_exit'), $r('app.string.dialog_result_no'), $r('app.string.dialog_result_yes'),
                () => {}, () => {
                    //真正关闭程序,配置removeMissionAfterTerminate可在后台任务列表中删除
                    const ctx = ConfirmDialog.context?.getHostContext() as common.UIAbilityContext;
                    ctx.terminateSelf();
                    //router.back()
                })
        }

        ConfirmDialog.progressNode = new ComponentContent(ConfirmDialog.context!, wrapBuilder(confirmDialogComponent), params)

        let fragment = new CommonDialogFragment()

        fragment.setContext(ConfirmDialog.context);
        fragment.setContentNode(ConfirmDialog.progressNode)
        fragment.setOptions({
            autoCancel: false,
            onDidDisappear: didDisappear
        })

        ConfirmDialog.fragment = fragment
    }
}

@Builder
function confirmDialogComponent(param: ConfirmParams) {
    Column() {
        Column() {

            Text(param.text)
                .fontSize(16)
                .fontColor($r('sys.color.black'))
                .textAlign(TextAlign.Start)
                .margin({top: 12})

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
            Text(param.left)
                .id('tvLeftNo')
                .fontColor($r('sys.color.black'))
                .onClick(() => {
                    ConfirmDialog.fragment?.closeDialog()
                    param.leftFun()
                })
                .width('49%')
                .height('100%')
                .textAlign(TextAlign.Center)

            Divider()
                .vertical(true)
                .height(1.5)
                .color($r('app.color.lineColor'))
                .height('100%')

            Text(param.right)
                .id('tvRightYes')
                .fontColor($r('sys.color.black'))
                .onClick(() => {
                    ConfirmDialog.fragment?.closeDialog()
                    param.rightFun()
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