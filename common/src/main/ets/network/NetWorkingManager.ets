import { Context } from '@kit.AbilityKit';
import { wifiManager } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { connection } from '@kit.NetworkKit';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { bundleManager } from '@kit.AbilityKit';
import { Log } from '../Log';

export class NetworkManager {
  private context: Context;
  private static mInstance: NetworkManager | null = null;

  private constructor(context: Context) {
    this.context = context;
  }

  /**
   * 获取单例实例
   * @param context 应用上下文
   * @returns NetworkManager实例
   */
  public static getInstance(context: Context): NetworkManager {
    if (!NetworkManager.mInstance) {
      NetworkManager.mInstance = new NetworkManager(context);
    }
    return NetworkManager.mInstance!;
  }

  /**
   * 检查网络权限
   */
  private async checkNetworkPermission(): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      );
      const appInfo = bundleInfo.appInfo;
      const tokenId = appInfo.accessTokenId;

      // 检查网络权限
      const grantStatus = await atManager.checkAccessToken(
        tokenId,
        'ohos.permission.INTERNET' as Permissions
      );

      const isGranted = grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      Log.d('NetworkManager', `网络权限检查结果: ${isGranted}`);
      return isGranted;
    } catch (error) {
      Log.e('NetworkManager', '检查网络权限失败:');
      return false;
    }
  }

  /**
   * 检查网络是否连接可用
   * @returns 网络是否可用
   */
  public async isNetworkConnected(): Promise<boolean> {
    try {
      // 首先检查网络权限
      const hasPermission = await this.checkNetworkPermission();
      if (!hasPermission) {
        Log.w('NetworkManager', '应用未获得网络权限');
        return false;
      }

      Log.d('NetworkManager', '开始检查网络连接状态');

      // 获取默认网络句柄
      let netHandle = connection.getDefaultNetSync();

      // 检查网络是否有有效连接
      if (netHandle.netId == 0) {
        Log.d('NetworkManager', '无可用网络连接');
        return false;
      }

      // 获取网络能力对象
      let netCapability = connection.getNetCapabilitiesSync(netHandle);

      // 关键状态判断：检查networkCap是否存在且包含NET_CAPABILITY_VALIDATED标志
      if (!netCapability.networkCap) {
        Log.d('NetworkManager', '网络能力信息为空');
        return false;
      }

      const isConnected = netCapability.networkCap.includes(
        connection.NetCap.NET_CAPABILITY_VALIDATED
      );

      Log.d('NetworkManager', `网络连接状态检查结果: ${isConnected}`);
      return isConnected;

    } catch (error) {
      const businessError = error as BusinessError;
      Log.e('NetworkManager', `检查网络连接状态失败，错误码：${businessError.code}`);
      // 错误码201表示权限不足，需要特殊处理
      if (businessError.code === 201) {
        Log.w('NetworkManager', '网络权限不足，请检查应用权限设置');
      }
      return false;
    }
  }

  /**
   * 检查WiFi是否连接可用
   * @returns WiFi是否可用
   */
  public async isWifiConnected(): Promise<boolean> {
    try {
      const linkedInfo = await wifiManager.getLinkedInfo();
      // 验证WiFi连接状态：ssid非空且bssid非空表示有效连接
      const isConnected = linkedInfo.ssid.trim() !== '' && linkedInfo.bssid.trim() !== '';
      Log.d('NetworkManager', `WiFi连接状态: ${isConnected}`);
      return isConnected;
    } catch (error) {
      const errorCode = typeof error === 'number' ? error : (error as BusinessError).code;
      Log.e('NetworkManager', `获取WiFi连接信息失败，错误码：${errorCode}`);

      // 常见错误码说明
      // 201：权限不足
      // 202：调用者不具备系统权限
      if (errorCode === 201) {
        this.showToast('请授予WiFi信息访问权限');
      }
      return false;
    }
  }

  /**
   * 检查移动数据是否连接可用
   * @returns 移动数据是否可用
   */
  public async isMobileConnected(): Promise<boolean> {
    try {
      if (!await this.isNetworkConnected()) {
        return false;
      }

      // 获取网络类型来判断是否为移动数据
      let netHandle = connection.getDefaultNetSync();
      let netCapability = connection.getNetCapabilitiesSync(netHandle);

      // 检查networkCap是否存在
      if (!netCapability.networkCap) {
        Log.d('NetworkManager', '网络能力信息为空');
        return false;
      }

      // 检查是否包含蜂窝网络能力
      const isMobile = netCapability.networkCap.includes(
        connection.NetCap.NET_CAPABILITY_MMS
      ) || netCapability.networkCap.includes(
        connection.NetCap.NET_CAPABILITY_INTERNET
      );

      // 如果是移动网络且WiFi未连接，则认为是移动数据连接
      return isMobile && !(await this.isWifiConnected());
    } catch (error) {
      console.error('检查移动数据连接状态失败: ' + JSON.stringify(error));
      return false;
    }
  }

  /**
   * 切换WiFi开关状态
   * @param enabled 是否启用WiFi
   * @returns 是否操作成功
   */
  public async toggleWiFi(enabled: boolean): Promise<boolean> {
    try {
      if (enabled) {
        await wifiManager.enableWifi();
      } else {
        // await wifiManager.disenableWifi();  //todo 找到不启用wifi的接口
      }
      return true;
    } catch (error) {
      const errorCode = typeof error === 'number' ? error : (error as BusinessError).code;
      console.error(`切换WiFi状态失败${errorCode}`);

      return false;
    }
  }

  /**
   * 检查是否处于飞行模式
   * @returns 是否处于飞行模式
   */
  public async isAirplaneModeOn(): Promise<boolean> {
    try {
      return !(await this.isNetworkConnected());
    } catch (error) {
      console.error('检查飞行模式状态失败: ' + JSON.stringify(error));
      return false;
    }
  }

  /**
   * 切换飞行模式
   * @param setAirPlane 是否开启飞行模式
   */
  public async toggleAirplaneMode(setAirPlane: boolean): Promise<void> {
    console.warn('暂不支持直接设置飞行模式');
    if (setAirPlane) {
      // 关闭WiFi作为替代方案
      await this.toggleWiFi(false);
    }
  }

  /**
   * 开始WiFi扫描
   * @returns 是否扫描成功
   */
  public async startScanWIFI(): Promise<boolean> {
    try {
      await wifiManager.scan();
      return true;
    } catch (error) {
      console.error('WiFi扫描失败: ' + JSON.stringify(error));
      return false;
    }
  }

  /**
   * 获取WiFi列表
   * @returns WiFi列表
   */
  public async getWifiList(): Promise<wifiManager.WifiScanInfo[] | null> {
    try {
      const scanResults = await wifiManager.getScanInfoList();
      if (scanResults && scanResults.length > 0) {
        const wifiList: wifiManager.WifiScanInfo[] = [];
        const signalStrength = new Map<string, number>();

        scanResults.forEach((result, index) => {
          if (result.ssid && result.ssid.trim() !== '') {
            const key = `${result.ssid} ${result.capabilities || ''}`;
            if (!signalStrength.has(key)) {
              signalStrength.set(key, index);
              wifiList.push(result);
            }
          }
        });
        return wifiList;
      } else {
        if (!await this.isWifiConnected()) {
          this.showToast('请打开WiFi以查看网络列表');
        }
        return null;
      }
    } catch (error) {
      console.error('获取WiFi列表失败: ' + JSON.stringify(error));
      return null;
    }
  }

  /**
   * 显示提示信息
   * @param message 提示内容
   */
  private showToast(message: string): void {
    try {
      promptAction.showToast({
        message: message,
        duration: 2000
      });
    } catch (error) {
      console.error('显示提示信息失败: ' + JSON.stringify(error));
    }
  }
}