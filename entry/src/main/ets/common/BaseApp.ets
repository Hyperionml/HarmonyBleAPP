import { AppSetting } from "./AppSetting";

export class BaseApp{

  private static setting:AppSetting;

  private static instance:BaseApp;

  //单例模式中获取唯一的MyApplication实例
  public static getInstance():BaseApp{
    if (undefined == BaseApp.instance) {
      BaseApp.instance = new BaseApp();
    }
    return BaseApp.instance;
  }

  public static getSetting(context: Context):AppSetting {
    if (BaseApp.setting == null) {
      BaseApp.setting = new AppSetting(context);
    }
    return BaseApp.setting;
  }
}