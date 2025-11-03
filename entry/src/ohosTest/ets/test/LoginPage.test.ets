import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, Level } from '@ohos/hypium'
// 导入测试依赖kit
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { UIAbility, Want } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';


const delegator: abilityDelegatorRegistry.AbilityDelegator = abilityDelegatorRegistry.getAbilityDelegator();

export default function LoginPageTest() {
  describe('LoginPageTest', () => {
    // 初始化Driver对象
    const driver = Driver.create();
    let ability: UIAbility|null = null;
    beforeAll(async() => {
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
      console.info("get top ability");
      expect(ability.context.abilityInfo.name).assertEqual('EntryAbility');
    })
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    })
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    })
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    })

    it('assertEqual', 0, () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let a = 'test'
      // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
      expect(a).assertEqual('test')
    })

    it('EntryScanPage',Level.LEVEL3, async (done: Function) => {
      console.info("uitest: EntryScanPage begin");
      // 依据指定文本“Next”查找目标控件
      const next = await driver.findComponent(ON.text('同意'));//同意隐私协议
      // 点击目标控件
      await next.click();
      await driver.waitForIdle(1000,2000);
      // 逐页点击，等待页面切换
      for (let i = 1; i <= 5; i++) {
        console.log(`执行滑动操作从第${i}页到第${i+1}页`);
        // 滑动
        await driver.swipe(800, 500, 200, 500, 20000);
        await driver.waitForIdle(500,1000);
      }
      console.log(`查找按钮`);
      const enter = await driver.findComponent(ON.text('进入'));
      console.log(`找到按钮`);
      await enter.click();                                      //进入扫描页
      await driver.pressBack();
      console.info("uitest: EntryScanPage done");
      done();
    })

    it('EntryLoginPage',Level.LEVEL3, async (done: Function) => {
      console.info("uitest: EntryLoginPage begin");

      const context = ability?.context;
      // 直接导航到LoginPage
      await context?.getApplicationContext().getRunningProcessInformation().then(() => {
        router.pushUrl({
          url: 'pages/LoginPage'
        });
      });
      // 等待页面加载
      await driver.waitForIdle(2000, 3000);
      // 验证LoginPage元素是否存在
      await driver.assertComponentExist(ON.text('登录'));
      console.info("LoginPage loaded successfully");

      console.info("uitest: EntryLoginPage done");
      done();
    })

    /**
     * 测试记住密码
     */
    it('testRememberPassword', Level.LEVEL3, async (done: Function) => {
      const context = ability?.context;
      await context?.getApplicationContext().getRunningProcessInformation().then(() => {
        router.pushUrl({ url: 'pages/LoginPage' });
      });
      await driver.waitForIdle(2000, 3000);
      const rememberPwdCheckbox = await driver.findComponent(ON.id('rememberPasswordCheckbox'));
      const isChecked = await rememberPwdCheckbox.isChecked();
      expect(isChecked).assertEqual(true);
      await rememberPwdCheckbox.click();
      console.info(`bbb 记住密码框状态：${isChecked}`)

      const isUnchecked = await rememberPwdCheckbox.isChecked();
      expect(isUnchecked).assertEqual(false);
      await rememberPwdCheckbox.click();
      console.info(`bbb 记住密码框状态：${isUnchecked}`)
      done();
    })

    /**
     * 测试密码隐藏
     */
    it('testPasswordShowHide', Level.LEVEL3, async (done: Function) => {
      const context = ability?.context;
      await context?.getApplicationContext().getRunningProcessInformation().then(() => {
        router.pushUrl({ url: 'pages/LoginPage' });
      });
      await driver.waitForIdle(2000, 3000);

      const textInputs = await driver.findComponents(ON.type('TextInput'));
      const passwordInput = textInputs[1];// 密码输入框
      await passwordInput.inputText('123');
      await driver.waitForIdle(1000, 2000);
      const passwordEyeIcon = await driver.findComponent(ON.id('passwordEyeIcon'));
      //多次点击切换
      for (let i = 1; i <= 3; i++) {
        console.info(`bbb uitest: 第${i}次点击密码眼睛图标`);
        await passwordEyeIcon.click();
        await driver.waitForIdle(2000, 3000);
      }
      done();
    })

    /*
     * 测试登录
     */
    it('testLoginAndLogout', Level.LEVEL3, async (done: Function) => {
      const context = ability?.context;
      await context?.getApplicationContext().getRunningProcessInformation().then(() => {
        router.pushUrl({ url: 'pages/LoginPage' });
      });
      await driver.waitForIdle(2000, 3000);

      // 输入正确账号密码并登录
      const textInputs = await driver.findComponents(ON.type('TextInput'));
      const accountInput = textInputs[0];// 账号输入框
      const passwordInput = textInputs[1];// 密码输入框
      await accountInput.inputText('appstore');
      await passwordInput.inputText('123');
      await driver.pressBack();// 收起键盘
      await driver.waitForComponent(ON.id('agreeTermsCheckbox'),3000);
      const agreeCheckbox = await driver.findComponent(ON.id('agreeTermsCheckbox'));
      await driver.waitForComponent(ON.id('login'),3000);
      const loginButton = await driver.findComponent(ON.id('login'));
      await agreeCheckbox.click();
      await loginButton.click();
      await driver.waitForIdle(5000, 8000); // 等待登录跳转
      await driver.waitForComponent(ON.text('允许'),3000);
      await driver.assertComponentExist(ON.text('允许'))
      router.pushUrl({url: 'pages/LoginPage'})
      await driver.waitForIdle(2000,5000)

      const logoutButton = await driver.findComponent(ON.id('logoutButton'));
      await logoutButton.click();
      await driver.waitForIdle(2000, 3000);
      await driver.assertComponentExist(ON.text('登录')); // 退出后还在登录页
      done();
    })

    /*
     * 测试返回
     */
    it('testBackButton', Level.LEVEL3, async (done: Function) => {
      console.info("uitest: testBackButton begin");
      const context = ability?.context;
      await context?.getApplicationContext().getRunningProcessInformation().then(() => {
        router.pushUrl({ url: 'pages/LoginPage' });
      });
      await driver.waitForComponent(ON.id('backButton'),3000);
      const customBackButton = await driver.findComponent(ON.id('backButton'));
      await customBackButton.click();
      await driver.waitForComponent(ON.text('同意'),5000);
      await driver.assertComponentExist(ON.text('同意'))
      await driver.waitForIdle(2000,5000)
      done();
    })


    /**
     * 测试输入错误的用户名/密码/设备id，看能否登录成功（使用无效的用户名/密码/设备id）
     */
    it('testLogin1', Level.LEVEL3,async (done: Function) => {
      console.info("uitest: testLogin1 begin");
      const context = ability?.context;
      // 直接导航到LoginPage
      await context?.getApplicationContext().getRunningProcessInformation().then(() => {
        router.pushUrl({
          url: 'pages/LoginPage'
        });
      });
      await driver.waitForComponent(ON.type('TextInput'),3000);
      // 输入错误的用户名和密码
      const textInputs = await driver.findComponents(ON.type('TextInput'));
      const accountInput = textInputs[0];// 账号输入框
      const passwordInput = textInputs[1];// 密码输入框
      await accountInput.inputText('user');
      await passwordInput.inputText('password');
      await driver.pressBack();// 收起键盘

      // 勾选协议
      await driver.waitForComponent(ON.id('agreeTermsCheckbox'),3000);
      const agreeCheckbox = await driver.findComponent(ON.id('agreeTermsCheckbox'));
      await agreeCheckbox.click();
      // 点击登录按钮
      const loginButton = await driver.findComponent(ON.text('登录'));
      await loginButton.click();
      // 等待响应
      await driver.waitForIdle(3000, 5000);
      // 验证是否仍然在登录页面（登录失败）
      await driver.assertComponentExist(ON.text('登录'));
      console.info("uitest: testLogin1 done");
      done();
    })

    /**
     * 测试不输入用户名/密码，看能否登录成功
     */
    it('testLogin2', Level.LEVEL3,async (done: Function) => {
      console.info("uitest: testLogin2 begin");
      const context = ability?.context;
      // 直接导航到LoginPage
      await context?.getApplicationContext().getRunningProcessInformation().then(() => {
        router.pushUrl({
          url: 'pages/LoginPage'
        });
      });
      await driver.waitForComponent(ON.type('TextInput'),3000);
      // 不输入任何参数
      const textInputs = await driver.findComponents(ON.type('TextInput'));
      const accountInput = textInputs[0];// 账号输入框
      const passwordInput = textInputs[1];// 密码输入框
      await accountInput.inputText(' ');
      await passwordInput.inputText(' ');
      await driver.pressBack();// 收起键盘

      // 勾选协议
      await driver.waitForComponent(ON.id('agreeTermsCheckbox'),3000);
      const agreeCheckbox = await driver.findComponent(ON.id('agreeTermsCheckbox'));
      await agreeCheckbox.click();
      // 点击登录按钮
      const loginButton = await driver.findComponent(ON.text('登录'));
      await loginButton.click();
      // 等待响应
      await driver.waitForIdle(3000, 5000);
      // 验证是否仍然在登录页面（登录失败）
      await driver.assertComponentExist(ON.text('登录'));

      console.info("uitest: testLogin2 done");
      done();
    })

    /**
     * 测试只输入用户名，看能否登录成功
     */
    it('testLogin3', Level.LEVEL3,async (done: Function) => {
      console.info("uitest: testLogin3 begin");
      const context = ability?.context;
      // 直接导航到LoginPage
      await context?.getApplicationContext().getRunningProcessInformation().then(() => {
        router.pushUrl({
          url: 'pages/LoginPage'
        });
      });
      await driver.waitForComponent(ON.type('TextInput'),3000);
      // 只输入用户名
      const textInputs = await driver.findComponents(ON.type('TextInput'));
      const accountInput = textInputs[0];// 账号输入框
      const passwordInput = textInputs[1];// 密码输入框
      await accountInput.inputText('appstore');
      await passwordInput.inputText(' ');
      await driver.pressBack();// 收起键盘

      // 勾选协议
      await driver.waitForComponent(ON.id('agreeTermsCheckbox'),3000);
      const agreeCheckbox = await driver.findComponent(ON.id('agreeTermsCheckbox'));
      await agreeCheckbox.click();
      // 点击登录按钮
      const loginButton = await driver.findComponent(ON.text('登录'));
      await loginButton.click();
      // 等待响应
      await driver.waitForIdle(3000, 5000);
      // 验证是否仍然在登录页面（登录失败）
      await driver.assertComponentExist(ON.text('登录'));

      console.info("uitest: testLogin3 done");
      done();
    })

    /**
     * 测试只输入密码，看能否登录成功
     */
    it('testLogin4', Level.LEVEL3,async (done: Function) => {
      console.info("uitest: testLogin4 begin");
      const context = ability?.context;
      // 直接导航到LoginPage
      await context?.getApplicationContext().getRunningProcessInformation().then(() => {
        router.pushUrl({
          url: 'pages/LoginPage'
        });
      });
      await driver.waitForComponent(ON.type('TextInput'),3000);
      // 只输入密码
      const textInputs = await driver.findComponents(ON.type('TextInput'));
      const accountInput = textInputs[0];// 账号输入框
      const passwordInput = textInputs[1];// 密码输入框
      await accountInput.inputText(' ');
      await passwordInput.inputText('123');
      await driver.pressBack();// 收起键盘

      // 勾选协议
      await driver.waitForComponent(ON.id('agreeTermsCheckbox'),3000);
      const agreeCheckbox = await driver.findComponent(ON.id('agreeTermsCheckbox'));
      await agreeCheckbox.click();
      // 点击登录按钮
      const loginButton = await driver.findComponent(ON.text('登录'));
      await loginButton.click();
      // 等待响应
      await driver.waitForIdle(3000, 5000);
      // 验证是否仍然在登录页面（登录失败）
      await driver.assertComponentExist(ON.text('登录'));
      console.info("uitest: testLogin4 done");
      done();
    })

  })
}

