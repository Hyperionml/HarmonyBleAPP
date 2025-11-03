import { AppSetting } from '../common/AppSetting'
import { PopupManage } from '../common/popup/PopupManage'
import { AllowAgreementDialog } from '../component/Dialog/AllowAgreementDialog'
import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { systemDateTime } from '@kit.BasicServicesKit'

@Entry
@Component
struct SplashPage {

    appSetting = new AppSetting(this.getUIContext().getHostContext()!)

    @State themeColor: ResourceColor = ''
    @State popupManage: PopupManage = new PopupManage(this.getUIContext().getHostContext()!)
    @State loading: boolean = true
    @State isAllowAgreement: boolean | null = null
    @State exitPressTime: number = 0 //控制退出的时间标记

    onBackPress(){
        let curTime = systemDateTime.getTime()

        if(curTime - this.exitPressTime < 3000){
            //真正关闭程序,配置removeMissionAfterTerminate可在后台任务列表中删除
            const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
            ctx.terminateSelf();
            return false
        }
        //提示弹窗
        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.tips_double_click_exit') })
        this.exitPressTime = curTime

        return true
    }

    //生命周期函数
    async onPageShow(): Promise<void> {
        //初始化页面参数（参数来自持久化数据）
        //主题颜色
        const color = await this.appSetting.getTheme()
        this.isAllowAgreement = await this.appSetting.getIsAllowAgreement()
        this.themeColor = color
        this.loading = true

        await AllowAgreementDialog.init(this.getUIContext(), () => {
            this.popupManage.hide(AllowAgreementDialog.fragment!)
            this.isAllowAgreement = this.appSetting.getIsAllowAgreementSync()
            this.loading = false
        })

        console.log(`testtag this.isAllowAgreement: ${this.isAllowAgreement}`)
        if(!this.isAllowAgreement){
            this.popupManage.show(AllowAgreementDialog.fragment!)
        }else {
            const showUserGuideCount = this.appSetting.getShowUserGuideCountSync();
            if(showUserGuideCount == 0){
                router.replace({url: 'pages/GuidePage'})
            }
            else{
                router.replace({url: 'pages/IndexPageRefactored'})
            }
        }
    }

    onPageHide(): void {
        this.popupManage.hideAll()
    }

    build() {
        Stack({alignContent: Alignment.BottomEnd}){
            Column(){
                Blank().height('30%')
                Stack() {
                    Image($r('app.media.big_icon'))
                        .width(100)
                        .height(100)
                }
                .height('20%')
                Stack(){
                    Image($r('app.media.bsn_qt'))
                        .width(170)
                }
                .height('10%')
                Blank()
                Stack(){
                    Image($r('app.media.logo2'))
                        .height(66)
                }
                .height('20%')

            }
            .height('100%')
            .width('100%')
            .backgroundColor(this.themeColor)

            if(!this.loading && this.isAllowAgreement === false){
                Button('退出')
                    .width(90)
                    .height(40)
                    .backgroundColor('#FFFFFF')
                    .fontColor(this.themeColor)
                    .fontSize(16)
                    .borderRadius(5)
                    .margin({ bottom: 10, right: 10 })
                    .onClick(() => {
                        //真正关闭程序,配置removeMissionAfterTerminate可在后台任务列表中删除
                        const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
                        ctx.terminateSelf();
                    })
            }
        }


    }
}