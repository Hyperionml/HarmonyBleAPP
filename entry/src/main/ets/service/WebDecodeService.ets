import { common, Context } from '@kit.AbilityKit';
import { IWebDecodeResultHandle } from './IWebDecodeResultHandle';
import { DecodeResultBean, DecodeResultData } from '../bean/DecodeResultBean';
import { WebDecodeError } from './WebDecodeError';
import BuildProfile from 'BuildProfile';
import { DecodeRequest } from '../common/models/json/DecodeRequest';
import { DecodeResultDTO } from '../common/models/json/DecodeResult';
import { EventManager, Level, Log, NetworkManager, Utils } from 'common';
import { UserSetting } from '../common/UserSetting';
import taskpool from '@ohos.taskpool';
import { DeviceInfoUtils } from '../common/DeviceInfoUtils';
import { http } from '@kit.NetworkKit';
import { SerializationFactory } from '../common/serialization/SerializationFactory';
import { AppEvent } from '../common/event/AppEvent';
import { AppEventType } from '../common/event/AppEventType';

const TAG: string = 'WebDecodeService';

// 定义任务所需的参数接口
interface DecodeTaskParams {
  bean: DecodeResultData;
  uniqueId: number;
  context: Context;
}

// 定义任务返回结果接口
interface DecodeTaskResult {
  result: DecodeResultDTO | null;
  error: WebDecodeError;
  uniqueId: number;
}


@Concurrent
async function executeDecodeTask(params: DecodeTaskParams): Promise<DecodeTaskResult> {

  try {
    const decodeRequest = new DecodeRequest();

    // 构建请求体
    // 获取设备IMEI
    try {
      const deviceId = DeviceInfoUtils.getIMEI(params.context);
      console.log('aaaTest',`获取的IMEI: ${deviceId}`);
      decodeRequest.setIMEI(deviceId);
    } catch (error) {
      console.warn('aaaTest',`Failed to get device ID from DeviceInfoUtils: ${error}`);
    }

    // // 获取用户token和ID
    // try {
    //   const userSetting = new UserSetting(params.context);
    //   const accessToken = await userSetting.getUserAccessToken();
    //   const userId = await userSetting.getUserId();
    //   console.log(`获取的token: ${accessToken}`);
    //   console.log(`获取的userId: ${userId}`);
    //   decodeRequest.setToken(accessToken);
    //   decodeRequest.setUserId(userId);
    // } catch (error) {
    //   console.warn(`Failed to get user info: ${error}`);
    // }

    // 获取地理位置
    try {
      const location = await Utils.getGpsLocation(params.context);
      if (location) {
        decodeRequest.setLatitude(location.latitude);
        decodeRequest.setLongitude(location.longitude);
      }
    } catch (error) {
      console.warn('Failed to get location');
    }

    // 设置解码数据
    if (params.bean.codeDataList && params.bean.codeDataList.length > 0) {
      const codeDataList: number[][] = [];
      for (const codeData of params.bean.codeDataList) {
        // 将 Uint8Array 转换为 number[]
        const numberArr: number[] = Array.from(codeData);
        codeDataList.push(numberArr);
      }
      decodeRequest.setDecodes(codeDataList);
    }

    // 设置Code
    if (params.bean.code) {
      decodeRequest.setCode(params.bean.code);
      console.log('aaaTest',`设置的Code: ${params.bean.code}`);
    }

    console.log('aaaTest',"完整请求数据:", JSON.stringify(decodeRequest));

    // 网络检查
    console.log('aaaTest','开始检查网络权限');
    const hasInternetPermission = await Utils.checkInternetPermission(params.context);
    console.log('aaaTest',`网络权限检查结果: ${hasInternetPermission}`);
    if (!hasInternetPermission) {
      return {
        result: null,
        error: WebDecodeError.NetPermissionDenied,
        uniqueId: params.uniqueId
      };
    }

    console.log('开始检查网络连接状态');
    const networkManager = NetworkManager.getInstance(params.context);
    const isNetworkConnected = await networkManager.isNetworkConnected();
    console.log(`网络连接状态检查结果: ${isNetworkConnected}`);
    if (!isNetworkConnected) {
      console.warn('设备未连接到网络');
      return {
        result: null,
        error: WebDecodeError.OffLine,
        uniqueId: params.uniqueId
      };
    }

    // 使用ProtocolBufferSerialization发送请求
    const protocolBufferSerialization = SerializationFactory.create()
    console.log('aaaTest',`准备发送请求数据: ${JSON.stringify(decodeRequest)}`);

    // 发送请求并获取响应
    const responseData: DecodeResultDTO = await protocolBufferSerialization.requestEncrypted({
      url: BuildProfile.MAIN_SERVER + "/Decode/Decode",
      method: http.RequestMethod.POST,
      data: decodeRequest
    });

    // 处理响应结果
    if (responseData) {
      console.log('aaaTest',`响应结果: ${JSON.stringify(responseData)}`);
      return {
        result: responseData,
        error: WebDecodeError.None,
        uniqueId: params.uniqueId
      };
    } else {
      console.log('aaaTest','请求失败，无响应');
      return {
        result: null,
        error: WebDecodeError.Destroy,
        uniqueId: params.uniqueId
      };
    }
  } catch (error) {
    console.error(`Web decode error: ${error}`);

    // 处理特定的网络错误
    if (error instanceof Error) {
      if (error.message.includes('Network') || error.message.includes('OffLine')) {
        return {
          result: null,
          error: WebDecodeError.OffLine,
          uniqueId: params.uniqueId
        };
      } else if (error.message.includes('permission')) {
        return {
          result: null,
          error: WebDecodeError.NetPermissionDenied,
          uniqueId: params.uniqueId
        };
      }
    }

    return {
      result: null,
      error: WebDecodeError.Unknown,
      uniqueId: params.uniqueId
    };
  }
}

// 心跳任务并发函数
@Concurrent
async function executeHeartbeatTask(context: Context): Promise<void> {
  const TAG: string = 'WebDecodeService';
  try {
    const networkManager = NetworkManager.getInstance(context);

    // 心跳前先检查网络连接
    const isConnected = await networkManager.isNetworkConnected();
    if (!isConnected) {
      Log.w(TAG, 'Heartbeat failed: Network disconnected');
      return;
    }
    const httpClient = http.createHttp();
    const response = await httpClient.request(BuildProfile.MAIN_SERVER, {
      method: http.RequestMethod.GET,
      connectTimeout: 10000,
      readTimeout: 10000
    });
    if (response.responseCode >= 200 && response.responseCode < 300) {
      Log.d(TAG, 'MainServer Heartbeat success');
    }
    httpClient.destroy();
  } catch (error) {
    Log.e(TAG, `Heartbeat error: ${error}`);
  }
}

export class WebDecodeService {
  private context: Context;
  private handle: IWebDecodeResultHandle | null = null;
  private isRunning: boolean = false;
  private uniqueId: number = 0; //使用id检验是否正确的批次
  private task: taskpool.Task | null = null;
  private networkManager: NetworkManager; //声明网络管理器实例

  constructor(
    context: Context,
    handle: IWebDecodeResultHandle,
    networkManager?: NetworkManager
  ) {
    if (!handle || !context) {
      throw new Error('Handle and context cannot be null');
    }
    this.context = context;
    this.handle = handle;
    this.networkManager = networkManager || NetworkManager.getInstance(context); // 初始化网络管理器
  }

  public getIsRunning(): boolean {
    return this.isRunning;
  }

  public setIsRunning(isRunning: boolean): void {
    this.isRunning = isRunning;
  }

  public start(bean: DecodeResultBean): void {
    if (!bean) return;
    //if ((!bean.getCodeDataList() || bean.getCodeDataList().length === 0) && !bean.getCode()) return;
    if (this.isRunning) return;

    this.isRunning = true;
    this.uniqueId = Date.now();
    this.startTask(bean, this.uniqueId);
  }

  public async heartbeat(): Promise<void> {
    const task = new taskpool.Task(executeHeartbeatTask, this.context);
    taskpool.execute(task);
  }

  public stop(): void {
    if (!this.isRunning) return;
    this.isRunning = false;

    const emptyResult: DecodeResultDTO = {
      IsSuccess: false,
      Result: "",
      Url: "",
      Type: "",
      ErrorMessage: ""
    };
    this.notifyComplete(emptyResult, WebDecodeError.Cancel, this.uniqueId);

    if (this.task) {
      taskpool.cancel(this.task);
      this.task = null;
    }
    this.uniqueId = 0;  //重置id，注意重置id的时机
  }

  public release(): void {
    this.stop();
    this.handle = null;
  }

  private startTask(bean: DecodeResultBean, uniqueId: number): void {
    if (this.task) return;
    this.notifyStart();
    //准备任务参数
    const taskParams: DecodeTaskParams = {
      bean: bean.toPlainObject(),
      uniqueId: uniqueId,
      context: this.context,
      //networkManager: this.networkManager
    };

    //创建任务
    this.task = new taskpool.Task(executeDecodeTask, taskParams);

    //执行任务并处理结果
    taskpool.execute(this.task)
      .then((result: Object) => {
        const decodeTaskResult = result as DecodeTaskResult;
        this.notifyComplete(decodeTaskResult.result, decodeTaskResult.error, decodeTaskResult.uniqueId);
        this.task = null;
      })
      .catch((error: Error) => {
        Log.e(TAG, `Task execution error: ${error.message}`);
        this.notifyComplete(null, WebDecodeError.Unknown, taskParams.uniqueId);
        this.task = null;
      });
  }

  private notifyStart(): void {
    if (this.handle) {
      this.handle.onStartWebDecode();
    }
  }

  private notifyComplete(result: DecodeResultDTO | null, error: WebDecodeError, id: number): void {
    //不是同个批次的
    if (id !== this.uniqueId) {
      return;
    }
    this.isRunning = false;
    this.task = null;
    const finalResult: DecodeResultDTO = result || {
      IsSuccess: false,
      Result: "",
      Url: "",
      Type: "",
      ErrorMessage: ""
    };
    if (this.handle) {
      try{
        this.handle.onEndWebDecode(finalResult, error);
      } catch (callbackError) {
        Log.e(TAG, `Callback error stack: ${callbackError.stack}`);
      }
    }
  }
}