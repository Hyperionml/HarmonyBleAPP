/**
 * 蓝牙协议类型枚举
 */
export class BTProtocolType {
  public static readonly Actions: BTProtocolType = new BTProtocolType("Actions", "\"Actions\":");
  public static readonly BatteryResult: BTProtocolType = new BTProtocolType("Battery", "\"BatteryPercent\":");
  public static readonly ScanResult: BTProtocolType = new BTProtocolType("ScanResult", "\"Code\":");
  public static readonly Request: BTProtocolType = new BTProtocolType("Request", "\"RequestType\":");
  public static readonly Version: BTProtocolType = new BTProtocolType("Version", "\"SysVersion\":");
  public static readonly WaitForTransfer: BTProtocolType = new BTProtocolType("WaitForTransfer", "\"FileType\":");
  public static readonly RequestFile: BTProtocolType = new BTProtocolType("File", "\"RequestLength\":");
  public static readonly ResponseFile: BTProtocolType = new BTProtocolType("File", "\"ResponseLength\":");
  public static readonly QCResult: BTProtocolType = new BTProtocolType("QCResult", "\"Score\":");

  private name: string;
  private symbol: string;

  private constructor(name: string, symbol: string) {
    this.name = name;
    this.symbol = symbol;
  }

  public getName(): string {
    return this.name;
  }
  // 尽量选择特殊符号，其他JSON结构中不会出现
  public getSymbol(): string {
    return this.symbol;
  }
}
