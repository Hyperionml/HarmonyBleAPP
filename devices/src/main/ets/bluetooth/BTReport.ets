import { BTSection } from "./BTSection";
/**
 * 存储蓝牙协议解析后的信息
 */
export class BTReport {
  private version: number;
  private id: number;
  private sections: BTSection[];

  constructor(version: number,id: number,sections: BTSection[]) {
    this.version = version;
    this.id = id;
    this.sections = sections;
  }

  public getSection(): BTSection[] {
    return this.sections;
  }

  public getVersion(): number {
    return this.version;
  }

  public getId(): number {
    return this.id;
  }

}