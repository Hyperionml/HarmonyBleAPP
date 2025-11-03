import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, DEFAULT } from '@ohos/hypium'
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { UIAbility, Want } from '@kit.AbilityKit';
import { AppSetting } from '../../../main/ets/common/AppSetting';
import { router } from '@kit.ArkUI';
import { EntryUtils } from '../../../main/ets/common/EntryUtils';

export default function LanguageSettingPageTest() {
    describe('LanguageSettingPageTest', () => {

        let delegator: abilityDelegatorRegistry.AbilityDelegator = abilityDelegatorRegistry.getAbilityDelegator();
        // 初始化Driver对象
        const driver = Driver.create();
        let ability: UIAbility | null = null;

        beforeAll(async () => {
            const bundleName = abilityDelegatorRegistry.getArguments().bundleName;
            const want: Want = {
                bundleName: bundleName,
                abilityName: 'EntryAbility'
            }
            await delegator.startAbility(want);
            await driver.waitForIdle(2000,5000)
            ability = await delegator.getCurrentTopAbility();
            let appSetting = new AppSetting(ability!.context)
            await appSetting.setIsAllowAgreement(true)
            await appSetting.setShowUserGuideCount(2)
            expect(ability.context.abilityInfo.name).assertEqual('EntryAbility');

            const context = ability?.context;
            await context?.getApplicationContext().getRunningProcessInformation().then(async () => {
                await router.pushUrl({
                    url: 'pages/SettingsPage'
                });
                router.pushUrl({
                    url: 'pages/LanguageSettingPage'
                });
            });
            await driver.waitForIdle(2000,5000)
        })

        /**
         * 测试选中图标是否正确显示
         */
        it("testIfIconCorrectlyDisplayed1", DEFAULT, async () => {
            await driver.waitForIdle(2000,5000)
            let btn1 = await driver.waitForComponent(ON.text('English'), 5000)
            await btn1.click()
            await driver.waitForIdle(4000,5000)
            await driver.assertComponentExist(ON.type('Image').isAfter(ON.text('English')).isBefore(ON.text('Français')))
        })

        it("testIfIconCorrectlyDisplayed2", DEFAULT, async () => {
            let btn2 = await driver.waitForComponent(ON.text('Français'), 5000)
            await btn2.click()
            await driver.waitForComponent(ON.type('Image').isAfter(ON.text('Français')).isBefore(ON.text('Deutsch')), 2000)
            await driver.assertComponentExist(ON.type('Image').isAfter(ON.text('Français')).isBefore(ON.text('Deutsch')))
        })

        it("testIfIconCorrectlyDisplayed3", DEFAULT, async () => {
            await driver.waitForIdle(2000,5000)
            let btn2 = await driver.waitForComponent(ON.text('Deutsch'), 5000)
            await btn2.click()
            await driver.waitForComponent(ON.type('Image').isAfter(ON.text('Deutsch')).isBefore(ON.text('Español')), 2000)
            await driver.assertComponentExist(ON.type('Image').isAfter(ON.text('Deutsch')).isBefore(ON.text('Español')))
        })

        it("testIfIconCorrectlyDisplayed4", DEFAULT, async () => {
            await driver.waitForIdle(2000,5000)
            let btn2 = await driver.waitForComponent(ON.text('Español'), 5000)
            await btn2.click()
            await driver.waitForComponent(ON.type('Image').isAfter(ON.text('Español')).isBefore(ON.text('Protuguês')), 2000)
            await driver.assertComponentExist(ON.type('Image').isAfter(ON.text('Español')).isBefore(ON.text('Protuguês')))
        })

        it("testIfIconCorrectlyDisplayed5", DEFAULT, async () => {
            await driver.waitForIdle(2000,5000)
            let btn2 = await driver.waitForComponent(ON.text('Protuguês'), 5000)
            await btn2.click()
            await driver.waitForComponent(ON.type('Image').isAfter(ON.text('Protuguês')).isBefore(ON.text('简体中文')), 2000)
            await driver.assertComponentExist(ON.type('Image').isAfter(ON.text('Protuguês')).isBefore(ON.text('简体中文')))
        })

        it("testIfIconCorrectlyDisplayed6", DEFAULT, async () => {
            await driver.waitForIdle(2000,5000)
            let btn2 = await driver.waitForComponent(ON.text('简体中文'), 5000)
            await btn2.click()
            await driver.waitForComponent(ON.type('Image').isAfter(ON.text('简体中文')), 2000)
            await driver.assertComponentExist(ON.type('Image').isAfter(ON.text('简体中文')))
        })

        /**
         * 测试保存功能
         */
        it("testParamsSave1", DEFAULT, async () => {
            await driver.waitForIdle(2000,5000)
            let btn1 = await driver.waitForComponent(ON.text('English'), 5000)
            await btn1.click()
            await driver.waitForIdle(2000,5000)
            let btn2 = await driver.waitForComponent(ON.text('保存'), 5000)
            await btn2.click()
            await driver.waitForIdle(2000,5000)
            await driver.waitForComponent(ON.text('Theme'), 2000)
            await driver.assertComponentExist(ON.text('Theme'))

            router.pushUrl({url: 'pages/LanguageSettingPage'})
            await driver.waitForIdle(2000,5000)
        })

        /**
         * 测试保存功能
         */
        it("testParamsSave2", DEFAULT, async () => {
            await driver.waitForIdle(2000,5000)
            let btn1 = await driver.waitForComponent(ON.text('Français'), 2000)
            await btn1.click()
            await driver.waitForIdle(2000,5000)
            let btn2 = await driver.waitForComponent(ON.text('保存'), 5000)
            if(btn2 !== null){
                await btn2.click()
            } else {
                let btn3 = await driver.waitForComponent(ON.text('Save'), 5000)
                await btn3.click()
            }
            await driver.waitForIdle(2000,5000)
            await driver.assertComponentExist(ON.text('Thème'))

            router.pushUrl({url: 'pages/LanguageSettingPage'})
            await driver.waitForIdle(2000,5000)
        })

        /**
         * 测试保存功能
         */
        it("testParamsSave3", DEFAULT, async () => {
            await driver.waitForIdle(2000,5000)
            let btn1 = await driver.waitForComponent(ON.text('Deutsch'), 2000)
            await btn1.click()
            await driver.waitForIdle(1000,5000)
            let btn2 = await driver.waitForComponent(ON.text('保存'), 5000)
            if(btn2 !== null){
                await btn2.click()
            } else {
                let btn3 = await driver.waitForComponent(ON.text('Enregistrer'), 5000)
                await btn3.click()
            }
            await driver.waitForComponent(ON.id('wait'),1500)
            await driver.assertComponentExist(ON.text('Thema'))

            router.pushUrl({url: 'pages/LanguageSettingPage'})
            await driver.waitForIdle(2000,5000)
        })

        /**
         * 测试保存功能
         */
        it("testParamsSave4", DEFAULT, async () => {
            await driver.waitForIdle(2000,5000)
            let btn1 = await driver.waitForComponent(ON.text('Español'), 2000)
            await btn1.click()
            await driver.waitForIdle(1000,5000)
            let btn2 = await driver.waitForComponent(ON.text('保存'), 5000)
            if(btn2 !== null){
                await btn2.click()
            } else {
                let btn3 = await driver.waitForComponent(ON.text('erhalten'), 5000)
                await btn3.click()
            }
            await driver.waitForIdle(2000,5000)
            await driver.assertComponentExist(ON.text('Español'))

            router.pushUrl({url: 'pages/LanguageSettingPage'})
            await driver.waitForIdle(2000,5000)
        })

        /**
         * 测试保存功能
         */
        it("testParamsSave5", DEFAULT, async () => {
            await driver.waitForIdle(2000,5000)
            let btn1 = await driver.waitForComponent(ON.text('Protuguês'), 2000)
            await btn1.click()
            await driver.waitForIdle(1000,5000)
            let btn2 = await driver.waitForComponent(ON.text('保存'), 5000)
            if(btn2 !== null){
                await btn2.click()
            } else {
                let btn3 = await driver.waitForComponent(ON.text('Guardar'), 5000)
                await btn3.click()
            }
            await driver.waitForIdle(2000,5000)
            await driver.assertComponentExist(ON.text('Protuguês'))

            router.pushUrl({url: 'pages/LanguageSettingPage'})
            await driver.waitForIdle(2000,5000)
        })

        /**
         * 测试保存功能
         */
        it("testParamsSave6", DEFAULT, async () => {
            await driver.waitForIdle(2000,5000)
            let btn1 = await driver.waitForComponent(ON.text('简体中文'), 2000)
            await btn1.click()
            await driver.waitForIdle(1000,5000)
            let btn2 = await driver.waitForComponent(ON.text('保存'), 5000)
            if(btn2 !== null){
                await btn2.click()
                await driver.waitForIdle(2000,5000)
                await driver.assertComponentExist(ON.text('语言'))
            } else {
                let btn3 = await driver.waitForComponent(ON.text('Salvar'), 5000)
                await btn3.click()
                await driver.waitForIdle(2000,5000)
                await driver.assertComponentExist(ON.text('主题'))
            }


            router.pushUrl({url: 'pages/LanguageSettingPage'})
            await driver.waitForIdle(2000,5000)
        })

        /**
         * 测试返回功能
         */
        it("testBack", DEFAULT, async () => {
            await driver.waitForIdle(2000,5000)
            let btn1 = await driver.waitForComponent(ON.text('设置'), 2000)
            await btn1.click()
            await driver.waitForIdle(1000, 5000)
            await driver.assertComponentExist(ON.text('主题'))
        })
    })
}