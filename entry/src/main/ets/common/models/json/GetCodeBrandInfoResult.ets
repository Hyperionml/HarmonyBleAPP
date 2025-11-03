import { CodeBrandInfo } from './CodeBrandInfo';

export class GetCodeBrandInfoResult {
  private IsSuccess: boolean = false;
  private ErrorMessage: string = '';
  private IsException: boolean = false;
  private Data: CodeBrandInfo | null = null;

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

  public getData(): CodeBrandInfo | null {
    return this.Data;
  }

  public setData(data: CodeBrandInfo | null): void {
    this.Data = data;
  }

  public toString(): string {
    return "GetCodeBrandInfoResult{" +
      "IsSuccess=" + this.IsSuccess +
      ", ErrorMessage='" + this.ErrorMessage + '\'' +
      ", IsException=" + this.IsException +
      ", Data=" + this.Data +
      '}';
  }
}