/**
 * 蓝牙设备控制指令模型
 * 用于封装发送给蓝牙设备的操作指令和配置信息
 */
export class BTActions {
  private isReboot: boolean = false;
  private actions: string = "";
  private configContent: string = "";

  //构造函数，初始化蓝牙指令参数
  constructor(isReboot: boolean = false, actions: string = "", configContent: string = "") {
    this.isReboot = isReboot;
    this.actions = actions;
    this.configContent = configContent;
  }

  //获取是否需要重启的状态
  public getIsReboot(): boolean {
    return this.isReboot;
  }

 //设置是否需要重启设备
  public setIsReboot(reboot: boolean): void {
    this.isReboot = reboot;
  }

  //获取操作指令字符串
  public getActions(): string {
    return this.actions;
  }

  //设置操作指令字符串
  public setActions(actions: string): void {
    this.actions = actions;
  }

  //获取额外配置内容
  public getConfigContent(): string {
    return this.configContent;
  }

  //设置额外配置内容
  public setConfigContent(configContent: string): void {
    this.configContent = configContent;
  }

}
