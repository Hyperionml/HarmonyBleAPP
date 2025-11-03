import { BusinessError } from '@kit.BasicServicesKit';
import { bundleManager, Permissions } from '@kit.AbilityKit';
import { userAuth } from '@kit.UserAuthenticationKit';
import deviceInfo from '@ohos.deviceInfo';
import { UIAbility } from '@kit.AbilityKit'; // 导入UIAbility基类

export class DeviceInfoUtils {
  /**
   * 获取应用版本名
   * @returns 版本名
   */
  static getVersionName(): string {
    try {
      const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      if (!bundleInfo) return "0.0";
      return bundleInfo.versionName;
    } catch (error) {
      console.error("getVersionName error:", error);
      return "0.0";
    }
  }

  /**
   * 获取应用版本号
   * @returns 版本号
   */
  static getVersionCode(): number {
    try {
      const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      if (!bundleInfo) return 0;
      return bundleInfo.versionCode;
    } catch (error) {
      console.error("getVersionCode error:", error);
      return 0;
    }
  }

  static getIMEI(context: Context): string {
    return DeviceInfoUtils.getUUID();
  }


  /**
   * 获取一个不变和基本不重复的UUID
   */
  static getUUID(): string {
    try {
      let serial: string = "fixed";

      let mSzDevIDShort = '35' +
        (deviceInfo.brand?.length ?? 0) % 10 +
        (deviceInfo.marketName?.length ?? 0) % 10 +
        (deviceInfo.productSeries?.length ?? 0) % 10 +
        (deviceInfo.productModel?.length ?? 0) % 10 +
        (deviceInfo.productModelAlias?.length ?? 0) % 10 +
        (deviceInfo.softwareModel?.length ?? 0) % 10 +
        (deviceInfo.hardwareModel?.length ?? 0) % 10 +
        (deviceInfo.hardwareProfile?.length ?? 0) % 10 +
        (deviceInfo.bootloaderVersion?.length ?? 0) % 10 +
        (deviceInfo.abiList?.length ?? 0) % 10 +
        (deviceInfo.securityPatchTag?.length ?? 0) % 10 +
        (deviceInfo.displayVersion?.length ?? 0) % 10 +
        (deviceInfo.osFullName?.length ?? 0) % 10;

      // 计算哈希值
      const hashHigh = DeviceInfoUtils.hashCode(mSzDevIDShort);
      const hashLow = DeviceInfoUtils.hashCode(serial);

      // 转换为16进制
      const hexHigh = DeviceInfoUtils.toPaddedHex(hashHigh, 8);
      const hexLow = DeviceInfoUtils.toPaddedHex(hashLow, 8);

      // 格式化为标准UUID
      return `00000000${hexHigh}00000000${hexLow}`.replace(
        /^(.{8})(.{4})(.{4})(.{4})(.{12})$/,
        '$1-$2-$3-$4-$5'
      );
    } catch (error) {
      console.error("getUUID error:", error);
      return "00000000-0000-0000-0000-000000000000";
    }
  }

  /**
   * 获取手机型号
   * @returns 手机型号
   */
  static getSystemModel(): string {
    return deviceInfo.productModel || "Unknown";
  }

  /**
   * 获取手机厂商
   * @returns 手机厂商
   */
  static getDeviceBrand(): string {
    return deviceInfo.brand || "Unknown";
  }

  /**
   * 获取系统版本号
   * @returns 系统版本号
   */
  static getSystemVersion(): string {
    return deviceInfo.osFullName || "Unknown";
  }


  /**
   * 判断是否为高性能设备
   * @returns 是否为高性能设备
   */
  static isHighPerformanceDevice(): boolean {
    try {
      const maxMemory = 400 * 1024 * 1024; // 400MB in bytes
      // HarmonyOS没有直接对应的方法，这里简化判断
      return maxMemory > (400 * 1024 * 1024);
    } catch (error) {
      console.error("isHighPerformanceDevice error:", error);
      return false;
    }
  }

  /**
   * 字符串哈希函数
   * @param str 输入字符串
   * @returns 哈希值
   */
  private static hashCode(str: string): number {
    let hash = 0;
    if (str.length === 0) return hash;

    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = (hash << 5) - hash + char;
      hash &= hash; // Convert to 32-bit integer
    }
    return hash >>> 0; // Ensure non-negative
  }

  /**
   * 数字转为固定宽度的16进制字符串
   * @param num 数字
   * @param width 宽度
   * @returns 16进制字符串
   */
  private static toPaddedHex(num: number, width: number): string {
    const hex = num.toString(16);
    return hex.padStart(width, '0').slice(-width);
  }
}