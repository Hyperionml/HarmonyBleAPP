export class UpdateRequest {
  private IMEI: string = '';
  private packageName: string = '';
  private systemName: string = '';
  private systemVersion: string = '';
  private language: string = '';
  private versionCode: number = 0;
  private versionName: string = '';
  private deviceBrand: string = '';
  private ABIs: string = '';

  public getIMEI(): string {
    return this.IMEI;
  }

  public setIMEI(IMEI: string): void {
    this.IMEI = IMEI;
  }

  public getPackageName(): string {
    return this.packageName;
  }

  public setPackageName(packageName: string): void {
    this.packageName = packageName;
  }

  public getSystemName(): string {
    return this.systemName;
  }

  public setSystemName(systemName: string): void {
    this.systemName = systemName;
  }

  public getLanguage(): string {
    return this.language;
  }

  public setLanguage(language: string): void {
    this.language = language;
  }

  public getSystemVersion(): string {
    return this.systemVersion;
  }

  public setSystemVersion(systemVersion: string): void {
    this.systemVersion = systemVersion;
  }

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

  public getDeviceBrand(): string {
    return this.deviceBrand;
  }

  public setDeviceBrand(deviceBrand: string): void {
    this.deviceBrand = deviceBrand;
  }

  public getABIs(): string {
    return this.ABIs;
  }

  public setABIs(ABIs: string): void {
    this.ABIs = ABIs;
  }

  public toString(): string {
    return "UpdateRequest{" +
      "IMEI='" + this.IMEI + '\'' +
      ", packageName='" + this.packageName + '\'' +
      ", systemName='" + this.systemName + '\'' +
      ", systemVersion='" + this.systemVersion + '\'' +
      ", language='" + this.language + '\'' +
      ", versionCode=" + this.versionCode +
      ", versionName='" + this.versionName + '\'' +
      ", deviceBrand='" + this.deviceBrand + '\'' +
      ", ABIs='" + this.ABIs + '\'' +
      '}';
  }
}