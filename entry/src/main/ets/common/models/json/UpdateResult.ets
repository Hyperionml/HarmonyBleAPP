
export class UpdateResult {
  private versionCode: number = 0;
  private versionName: string = '';
  private fileName: string = '';
  private updateMessage: string[] = [];
  private url: string = '';
  private MD5: string = '';
  private releaseDate: string = '';
  private isForced: boolean = false;
  private CRC: string = '';
  private isSuccess: boolean = false;
  private errorMessage: string = '';

  public getVersionCode(): number {
    return this.versionCode;
  }

  public setVersionCode(versionCode: number): void {
    this.versionCode = versionCode;
  }

  public getVersionName(): string {
    return this.versionName;
  }

  public setVersionName(versionName: string): void {
    this.versionName = versionName;
  }

  public getFileName(): string {
    return this.fileName;
  }

  public setFileName(fileName: string): void {
    this.fileName = fileName;
  }

  public getUpdateMessage(): string[] {
    return this.updateMessage;
  }

  public setUpdateMessage(updateMessage: string[]): void {
    this.updateMessage = updateMessage;
  }

  public getUrl(): string {
    return this.url;
  }

  public setUrl(url: string): void {
    this.url = url;
  }

  public getMD5(): string {
    return this.MD5;
  }

  public setMD5(MD5: string): void {
    this.MD5 = MD5;
  }

  public getReleaseDate(): string {
    return this.releaseDate;
  }

  public setReleaseDate(releaseDate: string): void {
    this.releaseDate = releaseDate;
  }

  public IsSuccess(): boolean {
    return this.isSuccess;
  }

  public setSuccess(success: boolean): void {
    this.isSuccess = success;
  }

  public getErrorMessage(): string {
    return this.errorMessage;
  }

  public setErrorMessage(errorMessage: string): void {
    this.errorMessage = errorMessage;
  }

  public IsForced(): boolean {
    return this.isForced;
  }

  public setForced(forced: boolean): void {
    this.isForced = forced;
  }

  public getCRC(): string {
    return this.CRC;
  }

  public setCRC(CRC: string): void {
    this.CRC = CRC;
  }

  public toString(): string {
    return "UpdateResult{" +
      "versionCode=" + this.versionCode +
      ", versionName='" + this.versionName + '\'' +
      ", fileName='" + this.fileName + '\'' +
      ", updateMessage=" + this.updateMessage +
      ", url='" + this.url + '\'' +
      ", MD5='" + this.MD5 + '\'' +
      ", releaseDate='" + this.releaseDate + '\'' +
      ", isForced=" + this.isForced +
      ", CRC='" + this.CRC + '\'' +
      ", isSuccess=" + this.isSuccess +
      ", errorMessage='" + this.errorMessage + '\'' +
      '}';
  }
}