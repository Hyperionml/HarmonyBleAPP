import { LoginResultData, LoginResultDataJson } from './LoginResultData';

export class LoginResult {
  private IsSuccess: boolean = false;
  private ErrorMessage: string = '';
  private IsException: boolean = false;
  private Data: LoginResultData | null = null;

  public isSuccess(): boolean {
    return this.IsSuccess;
  }

  public setSuccess(success: boolean): void {
    this.IsSuccess = success;
  }

  public getErrorMessage(): string {
    return this.ErrorMessage;
  }

  public setErrorMessage(errorMessage: string): void {
    this.ErrorMessage = errorMessage;
  }

  public isException(): boolean {
    return this.IsException;
  }

  public setException(exception: boolean): void {
    this.IsException = exception;
  }

  public getData(): LoginResultData | null {
    return this.Data;
  }

  public setData(data: LoginResultData | null): void {
    this.Data = data;
  }

  public static fromPlainObject(data: Object): LoginResult {
    const result = new LoginResult();
      const jsonData = data as LoginResultJson;
      result.IsSuccess = jsonData.IsSuccess;
      result.ErrorMessage = jsonData.ErrorMessage;
      result.IsException = jsonData.IsException;
      result.Data = jsonData.Data ? LoginResultData.fromPlainObject(jsonData.Data) : null;
    return result;
  }
}
export interface LoginResultJson {
  IsSuccess: boolean;
  ErrorMessage: string;
  IsException: boolean;
  Data: LoginResultDataJson | null;
}
