import { Utils } from "common";

/**
 * 蓝牙设备电池监控器
 * 构造一个监测器，延迟启动5s启动之后传入一个回调接口，发送一个currentCallback.send()指令到蓝牙设备，同时记录下当前时间，
 * 通过currentCallback.checkReceive(currentTime)看蓝牙设备有没有响应，返回true就休眠，十分钟之后再次发起询问。返回false就告诉应用离线了。
 * 如果不调用stop（）就会一直每十分钟循环询问一次。调用了就会清除资源、清除定时器。
 */
export class BluetoothBatteryMonitor{
  //日志标签
  private static readonly TAG: string = BluetoothBatteryMonitor.name;
  private isStart: boolean = false;
  private callback: IBluetoothBatteryCallback | null = null;
  private loopTimer?: number;//控制循环的定时器
  private delay:number = 5000;//延迟启动

  //构造函数重载
  constructor();  //无参用默认值
  constructor(delay:number);
  constructor(delay?:number) {
    if(delay !== undefined){
      this.delay = delay;
    }
  }

  //启动监控@param callback蓝牙交互回调
  start(callback:IBluetoothBatteryCallback):void{
    if(this.isStart) return;
    this.isStart = true;
    this.callback = callback;
    this.starThread();
  }

  //循环
  private starThread():void {
    if(this.loopTimer) return;
    setTimeout(() => {
      this.loop();  //调用循环方法
    },this.delay)
  }

  private loop():void{
    //延迟启动
    try{
      if(!this.isStart){
        this.clearLoop();
        return;
      }
      //执行监控
      let currentCallback = this.callback;
      const currentTime = Utils.getTime();

      if(currentCallback){
        currentCallback.send();  //发送指令
      }
      currentCallback = this.callback;
      if(currentCallback){
        if(!currentCallback.checkReceive(currentTime)){
          currentCallback.offline();  //触发离线回调
        }
      }
      if(this.isStart){
        this.loopTimer = setTimeout(() => {
          this.loop();
        },this.getInterval());
      }
    }catch (ex){
      if(ex instanceof Error){
        console.error(`${BluetoothBatteryMonitor.TAG}:异常 - ${ex.message}`);
      }else {
        console.error(`${BluetoothBatteryMonitor.TAG}:未知异常`);
      }
      //发生异常后尝试继续循环
      if(this.isStart) {
        this.loopTimer = setTimeout(() => {
          this.loop();
        },this.getInterval())
      }
    }
  }

  //停止监控，清理资源
  stop(): void {
    if(this.isStart){
      this.isStart = false;
      this.callback = null;
      this.clearLoop();
    }
  }

  private getInterval(): number | undefined {
    return 600000;  //十分钟
  }

  //清除循环定时器
  private  clearLoop() {
    if(this.loopTimer){
      clearTimeout(this.loopTimer);
      this.loopTimer = undefined;
    }
  }
}

export interface IBluetoothBatteryCallback {
  send():void;
  checkReceive(time:number):boolean;
  offline():void;
}
