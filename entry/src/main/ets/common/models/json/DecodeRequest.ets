/**
 * 解码请求数据模型
 */
export class DecodeRequest {
  private IMEI?: string;
  private Decodes?: number[][];
  private Longitude?: number;
  private Latitude?: number;
  private Code?: string;
  private Token?: string;
  private UserId?: string;
  private AppType?: string;

  public getIMEI(): string | undefined {
    return this.IMEI;
  }

  public setIMEI(IMEI: string): void {
    this.IMEI = IMEI;
  }

  public getDecodes(): number[][] | undefined {
    return this.Decodes;
  }

  public setDecodes(Decodes: number[][]): void {
    this.Decodes = Decodes;
  }

  public getLongitude(): number | undefined {
    return this.Longitude;
  }

  public setLongitude(Longitude: number): void {
    this.Longitude = Longitude;
  }

  public getLatitude(): number | undefined {
    return this.Latitude;
  }

  public setLatitude(Latitude: number): void {
    this.Latitude = Latitude;
  }

  public getCode(): string | undefined {
    return this.Code;
  }

  public setCode(Code: string): void {
    this.Code = Code;
  }

  public getToken(): string | undefined {
    return this.Token;
  }

  public setToken(Token: string): void {
    this.Token = Token;
  }

  public getUserId(): string | undefined {
    return this.UserId;
  }

  public setUserId(UserId: string): void {
    this.UserId = UserId;
  }

  public getAppType(): string | undefined {
    return this.AppType;
  }

  public setAppType(appType: string): void {
    this.AppType = appType;
  }
}
