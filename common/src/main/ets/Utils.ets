import { abilityAccessCtrl, Context, Permissions, bundleManager, } from '@kit.AbilityKit';
import { geoLocationManager } from "@kit.LocationKit";
import { Log } from './Log'
import { promptAction } from '@kit.ArkUI';


export interface LocationInfo {
  latitude: number;
  longitude: number;
}

export class Utils {
  /**
   * 获取当前系统时间的毫秒数
   */
  public static getTime(): number {
    return Date.now()
  }

  /**
   * 将字符串数组用指定分隔符拼接
   * @param delimiter 分隔符
   * @param arr 字符串数组
   * @returns 拼接后的字符串
   */
  static join(delimiter: string, arr: string[]): string {
    // 校验参数合法性
    if (!arr || arr.length === 0) {
      throw new Error("数组不能为空或空数组");
    }
    let result = '';
    for (let i = 0; i < arr.length; i++) {
      if (i > 0) {
        result += delimiter;
      }
      result += arr[i];
    }
    return result;
  }

  /**
   * 将字符串列表用指定分隔符拼接
   * @param delimiter 分隔符
   * @param list 字符串列表（Array<string>）
   * @returns 拼接后的字符串
   */
  static joinList(delimiter: string, list: string[]): string {
    // 校验参数合法性
    if (!list || list.length === 0) {
      throw new Error("列表不能为空或空列表");
    }
    // 直接复用数组的join方法，因为鸿蒙中List通常以Array形式存在
    return Utils.join(delimiter, list);
  }

  /**
   * JSON字符串反序列化为指定类型的对象
   * @param jsonString JSON字符串
   * @param cls 目标类型的构造函数
   * @returns 解析后的对象或null
   */
  public static jsonParse<T>(jsonString: string): T | null {
    if (!jsonString || jsonString.trim() === '') {
      return null;
    }

    try {
      return JSON.parse(jsonString) as T;
    } catch (e) {
      console.error("jsonParse error:", e);
      return null;
    }
  }

  /**
   * JSON字符串反序列化为复杂类型（使用TypeToken模式）
   * @param jsonString JSON字符串
   * @param type 目标类型描述
   * @returns 解析后的对象或null
   */
  public static jsonParseWithType<T>(jsonString: string): T | null {
    if (!jsonString || jsonString.trim() === '') {
      return null;
    }

    try {
      return JSON.parse(jsonString) as T;
    } catch (e) {
      console.error("jsonParseWithType error:", e);
      return null;
    }
  }

  /**
   * 对象序列化为JSON字符串
   * @param value 要序列化的对象
   * @returns JSON字符串
   */
  public static stringify(value: object): string {
    if (value === null || value === undefined) {
      return "null";
    }

    try {
      return JSON.stringify(value);
    } catch (e) {
      console.error("stringify error:", e);
      return "{}";
    }
  }


  public static getUuidFrom16Bits(uuid: string) {
    if (4 != uuid.length) {
        throw new Error('uuid length error, should be 4 ')
    }

    // 生成蓝牙标准 UUID 格式（基于 16 位短 UUID 扩展）
    let uuidStr = "0000" + uuid + "-0000-1000-8000-00805F9B34FB";
    return uuidStr;
  }

  public static substring(str: string, start: number, length?: number): string {
    if (length !== undefined) {
      return str.substring(start, start + length);
    } else {
      return str.substring(start);
    }
  }

  /**
   * 检查权限
   */
  public static async checkPermission(context: Context, permission: string): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      let tokenId = 0;

      // 获取应用的accessTokenId
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      );
      const appInfo = bundleInfo.appInfo;
      tokenId = appInfo.accessTokenId;
      // 校验权限
      const grantStatus = await atManager.checkAccessToken(
        tokenId,
        permission as Permissions
      );

      // 判断权限状态
      const isGranted = grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      if (isGranted) {
        Log.i('Utils', `已获得 ${permission} 权限`);
      } else {
        Log.i('Utils', `未获得 ${permission} 权限，需要向用户申请权限。`);
      }
      return isGranted;
    } catch (error) {
      Log.e('Utils', `检查权限 ${permission} 失败: ${error}`);
      return false;
    }
  }


  /**
   * 获取设备的 GPS 位置信息
   */
  public static async getGpsLocation(context: Context): Promise<LocationInfo | null> {
    try {
      Log.d('Utils', '开始检查位置权限');
      // 检查位置权限
      const hasLocationPermission = await Utils.checkPermission(context, 'ohos.permission.APPROXIMATELY_LOCATION');
      Log.d('Utils', `位置权限检查结果: ${hasLocationPermission}`);

      if (!hasLocationPermission) {
        Log.w('Utils', '位置权限未授予');
        return null;
      }

      Log.d('Utils', '权限已授予，开始获取当前位置');
      // 权限已授予，获取当前位置
      const location = await geoLocationManager.getCurrentLocation();
      Log.d('Utils', `获取到位置信息: latitude=${location.latitude}, longitude=${location.longitude}`);

      return {
        latitude: location.latitude,
        longitude: location.longitude
      };
    } catch (error) {
      Log.e('Utils', `获取位置信息失败: ${JSON.stringify(error)}`);
      if (error instanceof Error) {
        Log.e('Utils', `错误详情: ${error.message}`);
        Log.e('Utils', `错误堆栈: ${error.stack}`);
      }
    }
    return null;
  }

  /**
   * 获取网络权限
   */
  public static async checkInternetPermission(context: Context): Promise<boolean> {
    return await Utils.checkPermission(context, 'ohos.permission.INTERNET');
  }


}
