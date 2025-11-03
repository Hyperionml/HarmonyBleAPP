import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'

export default function ApiTest() {
    describe('ApiTest', () => {

        /**
         * -------------------------------------------------------------------------------------------------------------
         * ------------------------------------------------LoginActivity------------------------------------------------
         * -------------------------------------------------------------------------------------------------------------
         */
        it('testLogin1', 0, () => {
            // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
            let a = 'test'
            // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
            expect(a).assertEqual('test')
        })
    })
}