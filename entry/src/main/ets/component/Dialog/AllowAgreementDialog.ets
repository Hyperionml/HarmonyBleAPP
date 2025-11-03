import { AppSetting } from "../../common/AppSetting"
import { CommonDialogFragment } from "../../common/DialogFragmentManege/CommonDialogFragment"
import { ComponentContent, router } from "@kit.ArkUI"
import { WebViewType } from "../../pages/WebPage"
import BuildProfile from 'BuildProfile';

let appSetting: AppSetting
let themeColor: string
let language: string

export class AllowAgreementDialog {

    static readonly TAG: string = 'AllowAgreementDialog'

    static context: UIContext | null = null
    static fragment: CommonDialogFragment | null = null
    static progressNode: ComponentContent<Object>

    static async init(context: UIContext, didDisappear: () => void) {
        AllowAgreementDialog.context = context
        appSetting = new AppSetting(context.getHostContext()!)
        themeColor = await appSetting.getTheme()
        language = await appSetting.getLanguage()

        AllowAgreementDialog.progressNode = new ComponentContent(AllowAgreementDialog.context!, wrapBuilder(allowAgreementDialogComponent))

        let fragment = new CommonDialogFragment()

        fragment.setContext(AllowAgreementDialog.context);
        fragment.setContentNode(AllowAgreementDialog.progressNode)
        fragment.setOptions({
            autoCancel: false,
            onDidDisappear: didDisappear
        })

        AllowAgreementDialog.fragment = fragment
    }
}

// Confirm the pop-up window
@Builder
function allowAgreementDialogComponent() {
    Column() {
        Column() {
            Text($r('app.string.txt_allow_agreement_tips'))
                .fontSize(16)
                .margin({bottom: 5})
                .fontColor($r('sys.color.black'))
                .textAlign(TextAlign.Start)

            Text($r('app.string.privacy_policy'))
                .fontSize(16)
                .margin({bottom: 5})
                .fontColor(themeColor)
                .textAlign(TextAlign.Start)
                .onClick(() => {
                    AllowAgreementDialog.fragment?.closeDialog()
                    router.pushUrl({
                        url: 'pages/WebPage',
                        params: {
                            url: BuildProfile.Privacy + '?language=' + language,
                            from: AllowAgreementDialog.TAG,
                            type: WebViewType.Privacy
                        }
                    })
                })

            Text($r('app.string.contract_protocol'))
                .fontSize(16)
                .fontColor(themeColor)
                .textAlign(TextAlign.Start)
                .onClick(() => {
                    AllowAgreementDialog.fragment?.closeDialog()
                    router.pushUrl({
                        url: 'pages/WebPage',
                        params: {
                            url: BuildProfile.Contract +'?language=' + language,
                            from: AllowAgreementDialog.TAG,
                            type: WebViewType.Contract
                        }
                    })
                })
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
            Text($r('app.string.txt_not_allow'))
                .fontColor($r('sys.color.black'))
                .onClick(async () => {
                    AllowAgreementDialog.fragment?.closeDialog()
                    await appSetting.setIsAllowAgreement(false)
                })
                .width('49%')
                .height('100%')
                .textAlign(TextAlign.Center)

            Divider()
                .vertical(true)
                .height(1.5)
                .color($r('app.color.lineColor'))
                .height('100%')

            Text($r('app.string.txt_allow'))
                .fontColor($r('sys.color.black'))
                .onClick(async () => {
                    AllowAgreementDialog.fragment?.closeDialog()
                    await appSetting.setIsAllowAgreement(true)

                    const showUserGuideCount = appSetting.getShowUserGuideCountSync();
                    if(showUserGuideCount == 0){
                        router.replace({url: 'pages/GuidePage'})
                    }
                    else{
                        router.replace({url: 'pages/IndexPage'})
                    }
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