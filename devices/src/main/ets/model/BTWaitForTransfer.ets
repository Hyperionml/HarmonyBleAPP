/**
 * 描述待传输文件基本信息：文件名、文件类型、MD5校验值、总大小
 */
export class BTWaitForTransfer {
  private fileName: string = ''
  private fileType: string = ''
  private md5: string = ''
  private totalLength: number = 0

  public getFileName(): string {
    return this.fileName
  }

  public setFileName(fileName: string): void {
    this.fileName = fileName
  }

  public getFileType(): string {
    return this.fileType
  }

  public setFileType(fileType: string): void {
    this.fileType = fileType
  }

  public getMD5(): string {
    return this.md5
  }

  public setMD5(md5: string): void {
    this.md5 = md5
  }

  public getTotalLength(): number {
    return this.totalLength
  }

  public setTotalLength(totalLength: number): void {
    this.totalLength = totalLength
  }
}