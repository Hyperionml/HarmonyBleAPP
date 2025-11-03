import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, DEFAULT } from '@ohos/hypium';
import { JSON5 } from '@wolfx/json5';
import { DecodeResultDTO } from '../../../main/ets/common/models/json/DecodeResult';
import { DecodeRequest } from '../../../main/ets/common/models/json/DecodeRequest';
import { SerializationFactory } from '../../../main/ets/common/serialization/SerializationFactory';
import BuildProfile from 'BuildProfile';
import { http } from '@kit.NetworkKit';

const TAG = 'aaa';
export default function WebDecodeServiceTest() {
  describe('WebDecodeServiceTest', () => {
    beforeAll(async () => {

    });

    beforeEach(async () => {

    });

    afterEach(async () => {

    });

    /**
     * 测试网络解码接口
     */
    it('testNetworkDecode', 0, async () => {
      console.log(TAG, "网络解码测试")
      let url = BuildProfile.MAIN_SERVER + "/Decode/Decode";
      let decodeRequest = new DecodeRequest()
      decodeRequest.setCode('20140')

      let protocolBufferSerialization = SerializationFactory.create()
      let ioResult: DecodeResultDTO = await protocolBufferSerialization.requestEncrypted({
        url: url,
        method: http.RequestMethod.POST,
        data: decodeRequest
      })

      console.log(TAG,`向解码接口发送请求，返回结果= ${JSON5.stringify(ioResult)}`)
      expect(ioResult.IsSuccess).assertEqual(true)
    })



  });
}