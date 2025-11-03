export class CrashLogRequest {
  private files: Uint8Array[] = [];
  private IMEI: string = '';
  private fileNames: string[] = [];

  public getFiles(): Uint8Array[] {
    return this.files;
  }

  public setFiles(data: Uint8Array[]): void {
    this.files = data;
  }

  public getIMEI(): string {
    return this.IMEI;
  }

  public setIMEI(IMEI: string): void {
    this.IMEI = IMEI;
  }

  public getFileNames(): string[] {
    return this.fileNames;
  }

  public setFileNames(fileNames: string[]): void {
    this.fileNames = fileNames;
  }
}