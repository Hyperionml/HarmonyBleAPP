export class DynamicSettingData {
  //数据号版本
  private DataVersion: string = '';
  //App更新服务器
  private UpdateServer: string = '';
  //解码服务器
  private DecoderServer: string = '';
  //产品服务器
  private ProductServer: string = '';
  //请求是否成功
  private isSuccess: boolean = false;

  public setDataVersion(dataVersion: string): void {
    this.DataVersion = dataVersion;
  }

  public getDataVersion(): string {
    return this.DataVersion;
  }

  public getUpdateServer(): string {
    return this.UpdateServer;
  }

  public setUpdateServer(updateServer: string): void {
    this.UpdateServer = updateServer;
  }

  public getDecoderServer(): string {
    return this.DecoderServer;
  }

  public setDecoderServer(decoderServer: string): void {
    this.DecoderServer = decoderServer;
  }

  public getProductServer(): string {
    return this.ProductServer;
  }

  public setProductServer(productServer: string): void {
    this.ProductServer = productServer;
  }

  public IsSuccess(): boolean {
    return this.isSuccess;
  }

  public setSuccess(success: boolean): void {
    this.isSuccess = success;
  }

  public toString(): string {
    return "DynamicSettingData{" +
      " DataVersion='" + this.DataVersion + '\'' +
      ",UpdateServer ='" + this.UpdateServer + '\'' +
      ", DecoderServer='" + this.DecoderServer + '\'' +
      ", ProductServer='" + this.ProductServer + '\'' +
      ", isSuccess=" + this.isSuccess +
      '}';
  }
}