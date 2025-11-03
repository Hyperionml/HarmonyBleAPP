/**
 * 封装和管理编码类型
 */
export class BTSetCodeType{
  private codeType: number = 0;

  public getCodeType(): number {
    return this.codeType
  }

  public setCodeType(codeType: number): void {
    this.codeType = codeType
  }

}