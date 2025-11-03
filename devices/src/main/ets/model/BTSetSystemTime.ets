/**
 * 封装蓝牙设备的系统时间设置请求
 * 构造时默认生成当前系统时间，作为蓝牙设备的时间同步参数
 */
export class BTSetSystemTime {
  constructor() {
    const date = new Date();
    const options: Intl.DateTimeFormatOptions = {
      year: 'numeric',       // 四位年份
      month: '2-digit',      // 两位数月份
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false          // 禁用12小时制，确保使用24小时制
    };
    const formatter = new Intl.DateTimeFormat('zh-CN', options);
    const formattedTime = formatter.format(date).replace(',', '');

    // 将格式化后的时间赋值给私有变量
    this.systemTime = formattedTime;
    console.log(formattedTime);
  }

  private systemTime: string = "";

  public getSystemTime(): string {
    return this.systemTime
  }

  public setSystemTime(systemTime: string): void {
    this.systemTime = systemTime
  }

}
