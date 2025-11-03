import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, DEFAULT } from '@ohos/hypium'
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { UIAbility, Want } from '@kit.AbilityKit';
import { AppSetting } from '../../../main/ets/common/AppSetting';
import { router } from '@kit.ArkUI';

export default function AboutAppPageTest() {
    describe('AboutAppPageTest', () => {

        let delegator: abilityDelegatorRegistry.AbilityDelegator = abilityDelegatorRegistry.getAbilityDelegator();
        // 初始化Driver对象
        const driver = Driver.create();
        let ability: UIAbility | null = null;
        let hadBack = false
        let appSetting: AppSetting | null = null

        beforeAll(async () => {
            const bundleName = abilityDelegatorRegistry.getArguments().bundleName;
            const want: Want = {
                bundleName: bundleName,
                abilityName: 'EntryAbility'
            }
            await delegator.startAbility(want);
            await driver.waitForIdle(2000,5000)
            ability = await delegator.getCurrentTopAbility();
            appSetting = new AppSetting(ability!.context)
            await appSetting.setIsAllowAgreement(true)
            await appSetting.setShowUserGuideCount(2)
            expect(ability.context.abilityInfo.name).assertEqual('EntryAbility');

            const context = ability?.context;
            await context?.getApplicationContext().getRunningProcessInformation().then(async () => {
                await router.pushUrl({
                    url: 'pages/SettingsPage'
                });
                router.pushUrl({
                    url: 'pages/AboutAppPage'
                })
            });
            await driver.waitForIdle(2000,5000)
        })

        /**
         * 帮助页面跳转测试
         */
        it("testWarpHelpPage", DEFAULT, async () => {
            let btn1 = await driver.waitForComponent(ON.text('帮助'), 5000)
            await btn1.click()
            await driver.waitForComponent(ON.id('wait'), 1500)
            await driver.assertComponentExist(ON.text('什么是QT码?'))

            router.back()
        })

        /**
         * 反馈页面跳转测试
         */
        it("testWarpFeedback", DEFAULT, async () => {
            let btn1 = await driver.waitForComponent(ON.text('反馈'), 5000)
            await btn1.click()
            await driver.waitForComponent(ON.id('wait'), 1500)
            await driver.assertComponentExist(ON.text('允许'))
            await (await driver.waitForComponent(ON.text('允许'), 5000)).click()

            router.back()
        })

        /**
         * 官方页面跳转测试
         */
        it("testWarpOfficial", DEFAULT, async () => {
            let btn1 = await driver.waitForComponent(ON.text('官网'), 5000)
            await btn1.click()
            await driver.waitForComponent(ON.id('wait'), 1500)
            await driver.assertComponentExist(ON.text('官网').isAfter(ON.text('返回')))

            router.back()
        })

        /**
         * qt协议页面跳转测试
         */
        it("testWarpQT", DEFAULT, async () => {
            let btn1 = await driver.waitForComponent(ON.text('《QT软件许可及服务协议》'), 6000)
            await btn1.click()
            await driver.waitForComponent(ON.id('wait'), 1500)
            await driver.assertComponentExist(ON.text('《QT软件许可及服务协议》').isAfter(ON.text('返回')))

            router.back()
        })

        /**
         * 隐私政策页面跳转测试
         */
        it("testWarpPrivacy", DEFAULT, async () => {
            let btn1 = await driver.waitForComponent(ON.text('《隐私政策》'), 5000)
            await btn1.click()
            await driver.waitForComponent(ON.id('wait'), 1500)
            await driver.assertComponentExist(ON.text('《隐私政策》').isAfter(ON.text('返回')))

            router.back()
        })

        /**
         * 返回按钮测试
         */
        it("testBack", DEFAULT, async () => {
            let btn1 = await driver.waitForComponent(ON.text('设置'), 5000)
            await btn1.click()
            await driver.waitForComponent(ON.id('wait'), 1500)
            await driver.assertComponentExist(ON.text('主题'))
        })
    })
}