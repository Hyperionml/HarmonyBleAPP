/**
 * 蓝牙数据段类型枚举
 */
export class BTSectionType{
  public static readonly Json:BTSectionType = new BTSectionType(1);
  public static readonly File:BTSectionType = new BTSectionType(2);
  private type : number;
  private constructor(type: number) {
    this.type = type;
  }

  public getTypeValue(): number {
    return this.type;
  }

  //根据数字类型获取对应BTSectionType实例
  public static get(type: number): BTSectionType {
    if (type === BTSectionType.Json.type) {
      return BTSectionType.Json;
    } else if (type === BTSectionType.File.type) {
      return BTSectionType.File;
    } else {
      throw new Error("Unsupported BTSectionType: " + type);
    }
  }
}