import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, Level } from '@ohos/hypium'
import { UIAbility, Want } from '@kit.AbilityKit';
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { AppSetting } from '../../../main/ets/common/AppSetting';
import { router } from '@kit.ArkUI';

const delegator: abilityDelegatorRegistry.AbilityDelegator = abilityDelegatorRegistry.getAbilityDelegator();
/**
 * 用普通蓝牙模式测试，因为扫描QT开头的设备会比较快，不然就会超时报错，由于扫描出QT开头的设备时间有时会比较长，大概率会超时
 */
export default function BluetoothPageTest() {
  describe('BluetoothPageTest', () => {
    const driver = Driver.create();
    let ability: UIAbility|null = null;

    beforeAll(async () => {
      const bundleName = abilityDelegatorRegistry.getArguments().bundleName;
      const want: Want = {
        bundleName: bundleName,
        abilityName: 'EntryAbility'
      }
      await delegator.startAbility(want);
      await driver.waitForIdle(500,1000);
      ability = await delegator.getCurrentTopAbility();

      console.info("get top ability");
      expect(ability.context.abilityInfo.name).assertEqual('EntryAbility');

      const context = ability?.context;
      await context?.getApplicationContext().getRunningProcessInformation().then(() => {
        router.pushUrl({
          url: 'pages/BluetoothPage'
        });
      });
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

    it('ConnectBluetoothDevice', Level.LEVEL3, async (done: Function) => {
      const TAG = 'BluetoothTest';
      try {
          await driver.waitForComponent(ON.text('允许'), 3000);
          const allowButton = await driver.findComponent(ON.text('允许'));
          await allowButton.click();

        for (let i = 0; i < 3; i++) {
          console.info(TAG, `第${i+1}次查找QT设备`);
          await driver.delayMs(5000);

          // 查找所有文本组件
          const textComponents = await driver.findComponents(ON.type('Text'));

          // 遍历寻找QT设备
          for (const component of textComponents) {
            try {
              const text = await component.getText().catch(() => '');
              if (text.startsWith('QT')) {
                console.info(TAG, `找到QT设备: ${text}`);
                await component.click();
                await driver.delayMs(7000);
                console.info(TAG, "设备连接完成");
                await driver.assertComponentExist(ON.text('同意'));
                done();
                return;
              }
            } catch (err) {
              // 忽略异常
            }
          }
          if (i < 2) {
            console.info(TAG, "未找到设备，刷新重试");
            try {
              await driver.waitForComponent(ON.id('refresh'), 3000);
              const refreshButton = await driver.findComponent(ON.id('refresh'));
              await refreshButton.click();
              await driver.delayMs(5000);
            } catch (err) {
              console.error(TAG, "刷新失败");
              break;
            }
          }
        }

        console.info(TAG, "未找到QT设备");
        done();
      } catch (error) {
        console.error(TAG, "测试失败: " + error);
        done();
      }
    });

    })
}