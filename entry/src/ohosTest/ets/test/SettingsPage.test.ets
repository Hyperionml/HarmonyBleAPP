import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, DEFAULT } from '@ohos/hypium'
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { UIAbility, Want } from '@kit.AbilityKit';
import { AppSetting } from '../../../main/ets/common/AppSetting';
import { AnimatedDrawableDescriptor, router } from '@kit.ArkUI';

export default function SettingsPageTest() {
    describe('SettingsPageTest', () => {

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
            });
            await driver.waitForIdle(2000,5000)
        })

        /**
         * 测试返回
         */
        it("testBack", DEFAULT, async () => {
            let btn = await driver.waitForComponent(ON.text('返回'), 5000)
            await btn.click()
            await driver.waitForComponent(ON.id('exit'), 3000)
            await driver.assertComponentExist(ON.text('允许'))

            hadBack = true
            router.pushUrl({url: 'pages/SettingsPage'})
            await driver.waitForIdle(2000,5000)
        })

        /**
         * 测试保存
         */
        it("testSave", DEFAULT, async () => {
            let btn = await driver.waitForComponent(ON.text('保存'), 5000)
            await btn.click()
            await driver.assertComponentExist(ON.text('主题'))
        })

        /**
         * 测试主题
         */
        it("testTheme", DEFAULT, async () => {
            let btn = await driver.waitForComponent(ON.id('greenTheme'), 5000)
            await btn.click()
            await driver.waitForComponent(ON.id('exit'), 2000)
            let btn2 = await driver.waitForComponent(ON.text('保存'), 5000)
            await btn2.click()
            if(appSetting === null){
                appSetting = new AppSetting(ability!.context)
            }
            await driver.waitForComponent(ON.id('wait'), 1500)
            let theme = await appSetting.getTheme()
            expect('#00C853').assertEqual(theme)

            await router.pushUrl({url: 'pages/SettingsPage'})
            await driver.waitForIdle(2000,5000)
        })

        /**
         * 测试跳转到语言设置界面
         */
        it("testLanguageSetting", DEFAULT, async () => {
            let btn = await driver.waitForComponent(ON.text('简体中文'), 5000)
            await btn.click()
            await driver.waitForIdle(2000,5000)
            await driver.assertComponentExist(ON.text('语言'))

            router.back()
            await driver.waitForIdle(2000,5000)
        })

        /**
         * 测试声音开关
         */
        it("testSoundSwitch", DEFAULT, async () => {
            let sound = await appSetting?.getIsSound()
            let btn = await driver.waitForComponent(ON.text('声音'), 5000)
            await btn.click()
            await driver.waitForComponent(ON.text('允许'), 3000)
            let btn2 = await driver.waitForComponent(ON.text('保存'), 6000)
            await btn2.click()
            await driver.waitForComponent(ON.text('允许'), 3000)
            expect(!sound).assertEqual(await appSetting?.getIsSound())

            await router.pushUrl({url: 'pages/SettingsPage'})
            await driver.waitForIdle(2000,5000)
        })

        /**
         * 测试震动开关
         */
        it("testVibrateSwitch", DEFAULT, async () => {
            let sound = await appSetting?.getIsShake()
            let btn = await driver.waitForComponent(ON.text('震动'), 5000)
            await btn.click()
            await driver.waitForIdle(2000,5000)
            let btn2 = await driver.waitForComponent(ON.text('保存'), 5000)
            await btn2.click()
            await driver.waitForComponent(ON.text('允许'), 3000)
            expect(!sound).assertEqual(await appSetting?.getIsShake())

            await router.pushUrl({url: 'pages/SettingsPage'})
            await driver.waitForIdle(2000,5000)
        })

        /**
         * 测试跳转到关于App
         */
        it("testJumpToAboutApp", DEFAULT, async () => {
            let btn = await driver.waitForComponent(ON.text('关于App'), 5000)
            await btn.click()
            await driver.waitForIdle(2000,5000)
            await driver.assertComponentExist(ON.text('官网'))

            await router.back()
            await driver.waitForIdle(2000,5000)
        })

        /**
         * 测试清理缓存
         */
        it("testCleanCache", DEFAULT, async () => {
            let btn = await driver.waitForComponent(ON.text('清理缓存'), 5000)
            await btn.click()
            await driver.waitForIdle(2000,5000)
            let btn2 = await driver.waitForComponent(ON.text('是'), 6000)
            await btn2.click()
            await driver.waitForIdle(2000,5000)
            await driver.waitForComponent(ON.text('允许'), 5000)
            await driver.assertComponentExist(ON.text('允许'))
        })

        /**
         * 测试系统返回键
         */
        it("testSystemBack", DEFAULT, async () => {
            await driver.pressBack()
            await driver.waitForComponent(ON.text('允许'), 3000)
            if(!hadBack){
                await driver.assertComponentExist(ON.text('允许'))
            }
            else {
                await driver.assertComponentExist(ON.id('exit'))
            }
        })
    })
}