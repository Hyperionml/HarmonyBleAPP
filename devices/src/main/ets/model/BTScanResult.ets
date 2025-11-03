import { text } from "@kit.ArkGraphics2D"

/**
 * 蓝牙扫描结果
 */
export class BTScanResult{
  protected isSuccess: boolean = false
  protected code: string = ''
  protected text: string = ''
  protected elapsed: number = 0

  constructor() {
    // 保留空构造函数，与原Java类保持一致
  }

  public IsSuccess(): boolean {
    return this.isSuccess
  }

  public setSuccess(success: boolean): void {
    this.isSuccess = success
  }

  public getCode(): string {
    return this.code
  }

  public setCode(code: string): void {
    this.code = code
  }

  public getElapsed(): number {
    return this.elapsed
  }

  public setElapsed(elapsed: number): void {
    this.elapsed = elapsed
  }

  public getText(): string {
    return this.text
  }

  public setText(text: string): void {
    this.text = text
  }

  public toString(){
    return `BTScanResult: isSuccess: ${this.isSuccess}, code: ${this.code},
      text: ${this.text}, elapsed: ${this.elapsed}`
  }
}