import { a2dp } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Log } from 'common'

export class QTBluetoothDevice {
  private deviceAddress: string;
  private name: string;
  private connectTime: number;
  private lastConnectTime: number;

  // 构造函数重载
  constructor(deviceAddress: string);
  constructor(deviceAddress: string,name:string);
  constructor(deviceAddress: string,connectTime: number, lastConnectTime: number);
  constructor(deviceAddress: string,connectTimeOrName?: number|string, lastConnectTime?: number) {
    this.deviceAddress = deviceAddress;
    if(typeof connectTimeOrName == 'number'){
      this.connectTime = connectTimeOrName ?? 0;
      this.name = '';
    }else {
      this.connectTime = 0;
      this.name =connectTimeOrName ?? '';
    }
    this.lastConnectTime = lastConnectTime ?? 0;
  }

  public getDevice(): string {
    return this.deviceAddress;
  }

  public equals(other: Object): boolean {
    if (this === other) return true;
    if (!(other instanceof QTBluetoothDevice)) return false;
    const that = other as QTBluetoothDevice;
    // 用add作为唯一判断依据
    return this.deviceAddress === (other as QTBluetoothDevice).deviceAddress;
  }

  // 基于设备地址生成哈希
  public hashCode(): number {
    // 手动实现简单哈希
    let hash = 0;
    for (let i = 0; i < this.deviceAddress.length; i++) {
      hash = (hash * 31 + this.deviceAddress.charCodeAt(i)) | 0;
    }
    return hash;
  }

  public getName(): string {
    return this.name;
  }

  public getConnectTime(): number {
    return this.connectTime;
  }

  public setConnectTime(connectTime: number): void {
    this.connectTime = connectTime;
  }

  public getLastConnectTime(): number {
    return this.lastConnectTime;
  }

  public setLastConnectTime(lastConnectTime: number): void {
    this.lastConnectTime = lastConnectTime;
  }

  // @deprecated 不对，目前api没有查询连接状态，可能需要sppWrite()发送数据捕获异常来处理来判断
  // 使用BaseProfile.getConnectedDevices()传入地址
  public static getConnectedDevice(): QTBluetoothDevice[] {
    // 创建A2DP profile
    const a2dpSrc = a2dp.createA2dpSrcProfile();
    // 使用getConnectedDevices()获取地址数组
    const connectedAddress: string[] = a2dpSrc.getConnectedDevices();
    // 用地址创建QTBluetoothDevice对象
    return connectedAddress.map(address => new QTBluetoothDevice(address));
  }catch(err:Error){
    const error = err as BusinessError;
    Log.e('QTBluetoothDevice', `Error getting connected devices: ${error.code}, ${error.message}`);
    return [];
  }
}

