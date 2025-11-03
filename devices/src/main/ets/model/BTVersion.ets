export class BTVersion {
  private appVersion: string = ''
  private sysVersion: string = ''

  public getAppVersion(): string {
    return this.appVersion
  }

  public setAppVersion(appVersion: string): void {
    this.appVersion = appVersion
  }

  public getSysVersion(): string {
    return this.sysVersion
  }

  public setSysVersion(sysVersion: string): void {
    this.sysVersion = sysVersion
  }

}
