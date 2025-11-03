/**
 * 蓝牙文件传输请求模型
 * 封装文件传输的请求参数
 */
export class BTRequestFile{
  private fileName: string = '';
  private begin: number = 0;
  private requestLength: number = 0;

  public getFileName(): string {
    return this.fileName;
  }

  public setFileName(fileName: string): void {
    this.fileName = fileName;
  }

  public getBegin(): number {
    return this.begin;
  }

  public setBegin(begin: number): void {
    this.begin = begin;
  }

  public getRequestLength(): number {
    return this.requestLength;
  }

  public setRequestLength(requestLength: number): void {
    this.requestLength = requestLength;
  }

}