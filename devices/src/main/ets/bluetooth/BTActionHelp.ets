import { Utils } from 'common';
import { BTActions } from '../model/BTActions';
import { BTRequest } from '../model/BTRequest';

// 定义灯光颜色常量
export const LIGHT_YELLOW = "Y";
export const LIGHT_GREEN = "G";
export const LIGHT_BLUE = "B";

// 灯光状态常量
export const Light_ALLWAYS_ON: number = -1; // 常亮
export const Light_ALLWAYS_FLASH: number = 0x7FFF; // 持续闪烁

/**
 * 蓝牙设备交互的业务指令：封装蓝牙设备各类操作指令（震动、灯光控制、电量查询、版本查询等），生成业务对象（BTActions/BTRequest）
 */
export class BTActionHelp {
    /**
     * V表示震动，V后边接入数字，0或者负数表示不震动，正数表示震动多少毫秒
     * 不震动时，最好用0，而不是负数
     */
  public static makeVibrate(millSecond: number): string {
    return `V${millSecond}`;
  }

     /*
      * Y、G、B分别对应Yellow、Green、Blue灯
      * YGB后接入数字，负数表示常亮，0表示不亮，1到30000(含30000)表示闪烁多少毫秒；大于30000表示持续闪烁(不同于常亮)
      * */
  public static makeLight(light: string, millSecond: number): string {
    // 参数校验
    if (!light) {
      throw new Error("灯光颜色不能为空");
    }
    if (!(light === LIGHT_YELLOW || light === LIGHT_GREEN || light === LIGHT_BLUE)) {
      throw new Error("无效的灯光颜色，必须是Y、G或B");
    }
    return `${light}${millSecond}`;
  }

      /**
       * A后接入数字，0或负数表示不鸣叫，正数表示鸣叫多少毫秒
       * 不嗡鸣时，最好用0，而不是负数
       */
  public static makeNoice(millSecond: number): string {
    return `A${millSecond}`;
  }

  /**
   * 构建扫描成功动作
   */
  public static makeScanSuccessAction(): BTActions {
    const retVal: BTActions = new BTActions();
    retVal.setIsReboot(false); // 使用setter方法设置重启状态
    retVal.setConfigContent(""); // 使用setter方法设置配置内容
    const actions: string[] = [
      BTActionHelp.makeVibrate(200),
      BTActionHelp.makeLight(LIGHT_GREEN, 800)
    ];
    retVal.setActions(Utils.join(";", actions)); // 使用setter方法设置动作指令
    return retVal;
  }

  /**
   * 构建扫描错误动作
   */
  public static makeScanErrorAction(): BTActions {
    const retVal: BTActions = new BTActions();
    retVal.setIsReboot(false);
    retVal.setConfigContent("");
    const actions: string[] = [BTActionHelp.makeNoice(1000)];
    retVal.setActions(Utils.join(";", actions));
    return retVal;
  }

  /**
   * 构建电池状态请求
   */
  public static makeRequestBatteryAction(): BTRequest {
    const retVal: BTRequest = new BTRequest();
    retVal.setRequestType(BTRequest.TYPE_BATTERY); // 使用setter方法设置请求类型，明确是“电量查询”
    return retVal;
  }

  /**
   * 构建版本信息请求
   */
   public static makeRequestVersionAction(): BTRequest {
    const retVal: BTRequest = new BTRequest();
    retVal.setRequestType(BTRequest.TYPE_VERSION); // 使用setter方法设置请求类型，明确是“版本查询”
    return retVal;
  }
}
