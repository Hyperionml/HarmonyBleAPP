import { Context } from '@kit.AbilityKit';
import promptAction from '@ohos.promptAction';
import { http } from '@kit.NetworkKit';
import BuildProfile from 'BuildProfile';
import { SerializationFactory } from '../../common/serialization/SerializationFactory';
import { ProtocolBufferSerialization } from '../../common/serialization/ProtocolBufferSerialization';
import { DecodeRequest } from '../../common/models/json/DecodeRequest';
import { util } from '@kit.ArkTS';
import { DecodeResult } from '../../common/models/json/DecodeResult';

export class WebDecodeServiceTest {
  // 核心：直接构造并发送请求体的测试方法（仅保留核心逻辑）
  static async testManualRequest(context: Context): Promise<void> {

    try {
      console.log('=== 开始构造请求体测试 ===');

      // 构造请求体
      const decodeRequest = new DecodeRequest();
      decodeRequest.setCode("20140");


      // 发送请求体
      promptAction.showToast({ message: '发送虚拟请求...', duration: 1500 });
      let protocolBufferSerialization = SerializationFactory.create()


      let responseData: DecodeResult = await protocolBufferSerialization.requestEncrypted({
        url: BuildProfile.MAIN_SERVER + "/Decode/Decode",
        method: http.RequestMethod.POST,
        data: decodeRequest
      });

      // 响应处理
      if (responseData) {
        promptAction.showToast({ message: `请求成功`, duration: 3000 });
        console.log('响应结果:', JSON.stringify(responseData, null, 2));
      } else {
        promptAction.showToast({ message: '请求失败：无响应', duration: 2000 });
      }

      console.log('=== 构造请求体测试结束 ===');

    } catch (error) {
      console.error('测试异常:', error);
      promptAction.showToast({ message: `异常: ${(error as Error).message}`, duration: 2000 });
    }
  }
}
