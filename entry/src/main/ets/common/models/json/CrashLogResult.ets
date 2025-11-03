export class CrashLogResult {
  //请求是否成功
  private isSuccess: boolean = false;
  //请求失败信息
  private errorMessage: string = '';

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

  public toString(): string {
    return "CrashLogResult{" +
      "isSuccess=" + this.isSuccess +
      ", errorMessage='" + this.errorMessage + '\'' +
      '}';  }
}