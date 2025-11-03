export class RequestDynamicSettingData {
  //数据版本号
  private DataVersion: string = '';
  //手机IMEI
  private IMEI: string = '';
  //应用包名
  private PackageName: string = '';
  //平台
  private SystemName: string = '';
  //系统版本号
  private SystemVersion: string = '';
  //版本号
  private VersionCode: number = 0;
  //版本名
  private VersionName: string = '';
  //多语言
  private Language: string = '';
  //手机厂商
  private DeviceBrand: string = '';
  //设备CPU类型
  private ABIs: string = '';

  public setDataVersion(dataVersion: string): void {
    this.DataVersion = dataVersion;
  }

  public getDataVersion(): string {
    return this.DataVersion;
  }

  public getIMEI(): string {
    return this.IMEI;
  }

  public setIMEI(IMEI: string): void {
    this.IMEI = IMEI;
  }

  public getPackageName(): string {
    return this.PackageName;
  }

  public setPackageName(packageName: string): void {
    this.PackageName = packageName;
  }

  public getSystemName(): string {
    return this.SystemName;
  }

  public setSystemName(systemName: string): void {
    this.SystemName = systemName;
  }

  public getSystemVersion(): string {
    return this.SystemVersion;
  }

  public setSystemVersion(systemVersion: string): void {
    this.SystemVersion = systemVersion;
  }

  public getVersionCode(): number {
    return this.VersionCode;
  }

  public setVersionCode(versionCode: number): void {
    this.VersionCode = versionCode;
  }

  public getVersionName(): string {
    return this.VersionName;
  }

  public setVersionName(versionName: string): void {
    this.VersionName = versionName;
  }

  public getLanguage(): string {
    return this.Language;
  }

  public setLanguage(language: string): void {
    this.Language = language;
  }

  public getDeviceBrand(): string {
    return this.DeviceBrand;
  }

  public setDeviceBrand(deviceBrand: string): void {
    this.DeviceBrand = deviceBrand;
  }

  public getABIs(): string {
    return this.ABIs;
  }

  public setABIs(ABIs: string): void {
    this.ABIs = ABIs;
  }

  public toString(): string {
    return "RequestDynamicSettingData{" +
      " DataVersion='" + this.DataVersion + '\'' +
      ", IMEI='" + this.IMEI + '\'' +
      ", PackageName='" + this.PackageName + '\'' +
      ", SystemName='" + this.SystemName + '\'' +
      ", SystemVersion='" + this.SystemVersion + '\'' +
      ", VersionCode=" + this.VersionCode +
      ", VersionName='" + this.VersionName + '\'' +
      ", Language='" + this.Language + '\'' +
      ", DeviceBrand='" + this.DeviceBrand + '\'' +
      ", ABIs='" + this.ABIs + '\'' +
      '}';
  }
}