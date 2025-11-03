import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, Level } from '@ohos/hypium'
import { abilityDelegatorRegistry, By, Driver, MatchPattern, ON } from '@kit.TestKit';
import { Permissions, UIAbility, Want } from '@kit.AbilityKit';
import { display, router } from '@kit.ArkUI';
import { AppSetting } from '../../../main/ets/common/AppSetting';

const delegator: abilityDelegatorRegistry.AbilityDelegator = abilityDelegatorRegistry.getAbilityDelegator();

export default function IndexPageTest() {
  describe('IndexPageTest', () => {
    // 初始化Driver对象
    const driver = Driver.create();
    let ability: UIAbility|null = null;
    let appSetting: AppSetting | null = null

    beforeAll(async () => {
      const bundleName = abilityDelegatorRegistry.getArguments().bundleName;
      // 指定被测应用包名、ability名，请开发者替换为被测应用包名和ability名
      const want: Want = {
        bundleName: bundleName,
        abilityName: 'EntryAbility'
      }
      // 拉起被测应用
      await delegator.startAbility(want);
      // 等待应用拉起完成
      await driver.waitForIdle(500,1000);
      // 确认当前应用顶部Ability为指定的ability
      ability = await delegator.getCurrentTopAbility();
      appSetting = new AppSetting(ability!.context)
      await appSetting.setIsAllowAgreement(true)
      await appSetting.setShowUserGuideCount(2)
      await appSetting.setIsBluetoothShowOnMain(true);

      console.info("get top ability");
      expect(ability.context.abilityInfo.name).assertEqual('EntryAbility');

      const context = ability?.context;
      await context?.getApplicationContext().getRunningProcessInformation().then(() => {
        router.pushUrl({
          url: 'pages/IndexPageRefactored'
        });
      });
      await driver.waitForComponent(ON.text('允许'),3000);
      const allowButton1 = await driver.findComponent(ON.text('允许'));
      await allowButton1.click();
      await driver.waitForComponent(ON.text('允许'),3000);
      const allowButton2 = await driver.findComponent(ON.text('允许'));
      await allowButton2.click();
      await driver.waitForComponent(ON.text('允许'),3000);
      const allowButton3 = await driver.findComponent(ON.text('允许'));
      await allowButton3.click();
      await driver.waitForComponent(ON.text('本次使用允许'),3000);
      const allowButton4 = await driver.findComponent(ON.text('本次使用允许'));
      await allowButton4.click();

    })
    beforeEach(async () => {
      // 每个测试用例前等待1秒
      await driver.delayMs(1000)
    })
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    })
    afterAll(async () => {
      // 释放驱动
      await driver.delayMs(1000)
    })
    it('assertEqual', 0, () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let a = 'test'
      // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
      expect(a).assertEqual('test')
    })

    /**
     * 测试点击返回后再点击弹窗里面的“否”
     */
    it('testBackNo',Level.LEVEL3, async (done: Function) => {
      await driver.waitForIdle(2000,5000)
      await driver.waitForComponent(ON.id('exit'), 8000);
      await driver.assertComponentExist(ON.id('exit'));
      // 点击返回按钮
      const backBtn = await driver.findComponent(ON.id('exit'));
      await backBtn.click();
      // 等待弹窗出现
      await driver.waitForComponent(ON.id('tvLeftNo'), 3000);
      // 点击“否”按钮
      const noBtn = await driver.findComponent(ON.id('tvLeftNo'));
      await noBtn.click();
      await driver.assertComponentExist(ON.id('exit'));
      done();
    })

    /**
     * 测试帮助功能
     */
    it('testHelp',Level.LEVEL3, async (done: Function) => {

      await driver.waitForIdle(2000,5000)
      await driver.waitForComponent(ON.id('btnHelp'), 5000);

      const helpBtn = await driver.findComponent(ON.id('btnHelp'));
      await helpBtn.click();

      await driver.waitForComponent(ON.id('backButton'), 3000);
      const backBtn = await driver.findComponent(ON.id('backButton'));
      await backBtn.click();
      await driver.waitForIdle(3000, 5000);
      done()
    })

    /**
     * 右边弹窗--分享
     */
    it('testMore_share',Level.LEVEL3, async (done: Function) => {
      await driver.waitForComponent(ON.id('btnPlus'), 3000);
      const plusBtn = await driver.findComponent(ON.id('btnPlus'));
      await plusBtn.click();
      await driver.waitForComponent(ON.text('分享'), 3000);
      const shareBtn = await driver.findComponent(ON.text('分享'));
      await shareBtn.click();
      // 等待分享弹窗或页面
      await driver.waitForIdle(3000, 5000);
      await driver.click(50,100)
      await driver.delayMs(500);
      done()
    })

    /**
     * 右边弹窗--截图
     */
    it('testMore_snapshot',Level.LEVEL3, async (done: Function) => {

      await driver.waitForComponent(ON.id('btnPlus'), 8000);
      const plusBtn = await driver.findComponent(ON.id('btnPlus'));
      await plusBtn.click();
      await driver.delayMs(500);

      await driver.waitForComponent(ON.text('截图'), 3000);
      const snapshotBtn = await driver.findComponent(ON.text('截图'));
      await snapshotBtn.click();

      await driver.waitForIdle(2000,5000);
      done()
    })


    /**
     * 右边弹窗--登录
     */
    it('testMore_login',Level.LEVEL3, async (done: Function) => {
      await driver.waitForComponent(ON.id('btnPlus'), 8000);

      const plusBtn = await driver.findComponent(ON.id('btnPlus'));
      await plusBtn.click();
      await driver.delayMs(500);

      await driver.waitForComponent(ON.text('登录'), 3000);
      const loginBtn = await driver.findComponent(ON.text('登录'));
      await loginBtn.click();

      await driver.waitForComponent(ON.text('登录'), 3000);

      const backBtn = await driver.findComponent(ON.id('backButton'));
      await backBtn.click();

      await driver.assertComponentExist(ON.id('btnPlus'));
      done()
    })

    /**
     * 测试进度条
     */
    it('testProgressBar', Level.LEVEL3, async (done: Function) => {
      // 等待进度条组件加载
      await driver.waitForComponent(ON.id('seekbarZoom'), 2000);
      const seekBarComponent = await driver.findComponent(ON.id('seekbarZoom'));
      const component = await driver.findComponent(ON.id('seekbarZoom'));
      //找的坐标不能准确到进度条上，所以扩大了点击区域
      if (component) {
        const rect = await component.getBounds();
        const clickX = rect.left - 20 + Math.random() * (rect.top + 20);
        const clickY = rect.top - 20 + Math.random() * (rect.bottom + 20);
        await driver.click(Math.round(clickX), Math.round(clickY));
      }
      if (seekBarComponent) {
        // 获取组件信息
        let displayInfo = display.getDefaultDisplaySync();
        let screenWidth = displayInfo.width;
        let screenHeight = displayInfo.height;
        // let screenWidth = 1260;
        // let screenHeight = 2720;
        // 向右滑动
        await driver.drag(
          Math.round(screenWidth * 0.35),
          Math.round(screenHeight * 0.8),
          Math.round(screenWidth * 0.65),
          Math.round(screenHeight * 0.8),
          100
        );
        await driver.delayMs(500);
        // 向左滑动
        await driver.drag(
          Math.round(screenWidth * 0.65),
          Math.round(screenHeight * 0.8),
          Math.round(screenWidth * 0.35),
          Math.round(screenHeight * 0.8),
          100
        );
      }
      done()
    });

    /**
     * 测试开启手电筒
     */
    it('testFlash',Level.LEVEL3, async (done: Function) => {
      await driver.waitForComponent(ON.id('appBarBtnLight'), 5000);

      const flashBtn = await driver.findComponent(ON.id('appBarBtnLight'));
      await flashBtn.click();// 开灯
      await driver.delayMs(2000);
      await flashBtn.click();// 关灯
      await driver.delayMs(2000);
      expect(true).assertTrue();
      done();
    })

    /**
     * 测试跳转到反馈
     */
    it('testJumpToFeedback',Level.LEVEL3, async (done: Function) => {
      await driver.waitForComponent(ON.id('Feedback'), 8000);
      const feedbackBtn = await driver.findComponent(ON.id('Feedback'));
      await feedbackBtn.click();

      await driver.waitForComponent(ON.id('backBtn'), 3000);
      const backBtn = await driver.findComponent(ON.id('backBtn'));
      await backBtn.click();
      await driver.assertComponentExist(ON.id('btnPlus'));
      await driver.waitForIdle(2000,5000);
      done()
    })

    /**
     * 测试跳转到设置
     */
    it('testJumpToSetting',Level.LEVEL3, async (done: Function) => {
      await driver.waitForComponent(ON.id('appBarBtnSetting'), 5000);
      const settingBtn = await driver.findComponent(ON.id('appBarBtnSetting'));
      await settingBtn.click();

      await driver.waitForComponent(ON.id('btnBack'), 3000);

      const backBtn = await driver.findComponent(ON.id('btnBack'));
      await backBtn.click();
      await driver.waitForIdle(2000,5000);
      done()
    })

    /**
     * 测试点击返回再点击弹窗里面的“是”
     */
    it('testBackYes',Level.LEVEL3, async (done: Function) => {
      await driver.waitForComponent(ON.id('exit'), 8000);
      const backBtn = await driver.findComponent(ON.id('exit'));
      await backBtn.click();
      await driver.waitForComponent(ON.text('是'), 5000);
      const yesBtn = await driver.findComponent(ON.text('是'));
      await yesBtn.click();
      done()
    })


    })
}
