import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { ArkTSUtils, taskpool } from '@kit.ArkTS';
import { emitter } from '@kit.BasicServicesKit';

let testTag = false

function printLog(data: boolean): void {
  console.info("taskpool: data is: " + data);
  testTag = data
}

@Concurrent
function test(tag: boolean): string{
  console.log('taskpool执行成功')


  // emitter.emit({eventId: 1}, {
  //   data: {
  //     'obj': 'test'
  //   }
  // })

  return '你好'
}

export default function localUnitTest() {
  describe('localUnitTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    });
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    });
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    });
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    });

    it('assertContain', 0, async () => {

      emitter.on('heyiwei', (msg) => {
        console.log(`msg: ${JSON.stringify(msg)}`)
      })

      console.log('test启动')

      // emitter.emit({eventId: 1}, {
      //   data: {
      //     'obj': 'test'
      //   }
      // })

      const conditionVariable: ArkTSUtils.locks.ConditionVariable = new ArkTSUtils.locks.ConditionVariable();
      conditionVariable.waitFor(3000).then(() => {
        console.info(`Thread being awakened, then continue...`);
      })
      //let str = await taskpool.execute(test)
      //console.log(`${JSON.stringify(str)}`)
    });
  });
}

