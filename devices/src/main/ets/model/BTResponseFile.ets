/**
 * 蓝牙文件传输响应模型
 * 封装设备对文件传输请求的回应参数
 */
export class BTResponseFile{
  private fileName: string = ''
  private begin: number = 0
  private responseLength: number = 0

  public getFileName(): string {
    return this.fileName
  }

  public setFileName(fileName: string): void {
    this.fileName = fileName
  }

  public getBegin(): number {
    return this.begin
  }

  public setBegin(begin: number): void {
    this.begin = begin
  }

  public getResponseLength(): number {
    return this.responseLength
  }

  public setResponseLength(responseLength: number): void {
    this.responseLength = responseLength
  }


}