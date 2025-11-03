import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, Level } from '@ohos/hypium'
import { buildLoginUrl } from '../main/ets/common/ProductType'
import http from '@ohos.net.http';
import { LoginResult } from '../main/ets/common/models/json/LoginResult';

/**
 * 验证登录返回的数据是否为有效数据
 */
async function verifyLoginResult(
  userName: string,
  password: string,
  resultAssertString: string,
  resultAssert: boolean,
  dataAssertString: string,
  dataAssert: boolean,
  title: string
): Promise<void> {
  try {
    const baseLoginUrl = buildLoginUrl();
    const loginUrl = `${baseLoginUrl}?userId=${userName}&password=${password}`;

    console.info(`${title} API URL: ${loginUrl}`);

    let request = http.createHttp();
    let response = await request.request(loginUrl, {
      method: http.RequestMethod.GET,
      header: { 'Content-Type': 'application/json' },
      readTimeout: 5000,
      connectTimeout: 5000,
      expectDataType: http.HttpDataType.OBJECT
    });

    const isHttpSuccess = response.responseCode === 200;
    console.info(`${title} 完整响应:`, JSON.stringify(response.result, null, 2));

    // 验证HTTP请求是否成功
    if (isHttpSuccess !== resultAssert) {
      return;
    }

    if (isHttpSuccess) {
      const result = LoginResult.fromPlainObject(response.result);
      const isSuccess = result.isSuccess() && result.getData() != null;

      // 验证业务数据是否有效
      if (isSuccess !== dataAssert) {
        console.error(`${title} 业务数据验证失败: 期望${dataAssert}, 实际${isSuccess}`);
      } else {
        console.info(`${title} 测试通过`);

        if (isSuccess && result.getData()) {
          const data = result.getData()!;
          console.info(`${title} 登录成功 - token: ${data.getAccessToken()}, userId: ${data.getUserId()}`);
        }
      }
    }

  } catch (error) {
    console.error(`${title} API error: ${error}`);
  }
}

export default function LoginPageTest() {
  describe('LoginPageTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
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

    /**
     * 测试输入错误的用户名/密码/设备id，看能否登录成功
     */
    it('testLogin1', Level.LEVEL3, async () => {
      await verifyLoginResult(
        'user',
        'password',
        "输入错误的用户名/密码/设备ID：",
        true,
        "能否返回有效登录数据：",
        false,
        "testLogin1"
      );
    })

    /**
     * 测试不输入用户名/密码/设备id，看能否登录成功
     */
    it('testLogin2', Level.LEVEL3, async () => {
      await verifyLoginResult(
        '',
        '',
        "不输入任何参数：",
        true,
        "能否返回有效登录数据：",
        false,
        "testLogin2"
      );
    })

    /**
     * 测试只输入用户名，看能否登录成功
     */
    it('testLogin3', Level.LEVEL3, async () => {
      await verifyLoginResult(
        'appstore',
        '',
        "只输入用户名：",
        true,
        "能否返回有效登录数据：",
        false,
        "testLogin3"
      );
    })

    /**
     * 测试只输入密码，看能否登录成功
     */
    it('testLogin4', Level.LEVEL3, async () => {
      await verifyLoginResult(
        '',
        '123',
        "只输入密码：",
        true,
        "能否返回有效登录数据：",
        false,
        "testLogin4"
      );
    })

    /**
     * 测试输入有效的用户名/密码/设备id，看能否正常返回数据
     */
    it('testLogin7', Level.LEVEL3, async () => {
      await verifyLoginResult(
        'appstore',
        '123',
        "发送有效的用户名/密码：",
        true,
        "能否返回有效登录数据：",
        true,
        "testLogin7"
      );
    })

    /**
     * 测试输入有效的用户名/错误的密码,有效的设备id，看能否正常返回数据
     */
    it('testLogin9', Level.LEVEL3, async () => {
      await verifyLoginResult(
        'appstore',
        '123456789',
        "发送有效的用户名/错误的密码：",
        true,
        "能否返回有效登录数据：",
        false,
        "testLogin9"
      );
    })

  })
}