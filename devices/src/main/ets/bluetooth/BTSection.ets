import { BTSectionType } from "./BTSectionType";

/**
 * 蓝牙数据段信息封装类，用于描述蓝牙数据中的一个数据段
 */
export class BTSection {
  private sectionType: BTSectionType;
  private offset: number;
  private length: number = 0;
  private json: string | null = null;
  private content: Uint8Array | null = null;
  sections?: BTSection[];

  constructor(sectionType: number, offset: number,length?: number) {
    this.sectionType = BTSectionType.get(sectionType);
    this.offset = offset;
    if (length !== undefined) {
      this.length = length;
    }
  }
  public getOffset(): number {
    return this.offset;
  }

  public getLength(): number {
    return this.length;
  }

  public setLength(length: number): void {
    this.length = length;
  }

  public getJson(): string | null {
    return this.json;
  }

  public setJson(json: string): void {
    this.json = json;
  }

  public getContent(): Uint8Array | null {
    return this.content;
  }

  public setContent(content: Uint8Array): void {
    this.content = content;
  }

  public getSectionType(): BTSectionType {
    return this.sectionType;
  }

}
