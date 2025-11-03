/**
 * 蓝牙设备电量信息模型
 * 用于封装管理蓝牙设备电池状态
 */

export class BTBattery{
  private batteryPercent: number = 0;  //电池百分比
  private isBatteryLow: boolean = false;  //是否低电量
  private isChangedToLow: boolean = false;  //是否转换成低电量

  //获取电量百分比
  public getBatteryPercent():number {
		return this.batteryPercent;
	}

  //设置变量百分比
  public setBatteryPercent(batteryPercent: number): void{
    this.batteryPercent = batteryPercent;
  }

  //判断是否处于低电量
  public IsBatteryLow():boolean {
    return this.isBatteryLow;
  }

  //设置低电量状态
  public setBatteryLow(isLow: boolean): void{
    this.isBatteryLow = isLow;
  }

  //判断转不转为低电量
  public IsChangedToLow(): boolean {
    return this.isChangedToLow;
  }

  //设置转为低电量
  public setChangedToLow(isChanged: boolean): void {
    this.isChangedToLow = isChanged;
  }
}

