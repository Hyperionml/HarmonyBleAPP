import { Setting } from "common";
import { Context } from "@ohos.abilityAccessCtrl";
import { preferences } from "@kit.ArkData";
import { common } from "@kit.AbilityKit";

const TAG: string = 'DeviceSetting';
/**
 * 持久化存储蓝牙设备连接时间的工具类
 */
export class DeviceSetting extends Setting{

  private static INSTANCE: DeviceSetting | null = null;
  private static readonly SUFFIX_KEY_CONNECT_TIME: string = "ConnectTime";

  //通过父类初始化
  private constructor(context:Context) {
  super(context);
  }

  public static getInstance(context:Context): DeviceSetting {
    if(!context){
      throw new Error("Context cannot be null");
    }
    if(!DeviceSetting.INSTANCE){
      DeviceSetting.INSTANCE = new DeviceSetting(context);
    }
    return DeviceSetting.INSTANCE;
  }

  protected createPreferences(context: common.Context): preferences.Preferences {
    return preferences.getPreferencesSync(context, { name: "bluetooth" });
  }

  //设置记录设备连接成功的时间
  async setDeviceConnectTime(name: string, time: number): Promise<boolean> {
    if (!name || name.length === 0) {
      return false;
    }

    const key = name + DeviceSetting.SUFFIX_KEY_CONNECT_TIME;
    await super.setLong(key, time);
    return await this.commitChanges();
  }

  //获取记录设备连接成功的时间
  async getDeviceConnectTime(name: string): Promise<number> {
    if (!name || name.length === 0) {
      return 0;
    }

    const key = name + DeviceSetting.SUFFIX_KEY_CONNECT_TIME;
    return await super.getLong(key, 0);
  }
}