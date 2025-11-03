export class DecodeResult {

  private IsSuccess: boolean = false
  private ErrorMessage: string = ''
  private Result: string = ''
  private URL: string = ''
  private Type: string = ''

  constructor(
    IsSuccess: boolean = false,
    ErrorMessage: string = '',
    Result: string = '',
    URL: string = '',
    Type: string = ''
  ) {
    this.IsSuccess = IsSuccess
    this.ErrorMessage = ErrorMessage
    this.Result = Result
    this.URL = URL
    this.Type = Type
  }

  public getIsSuccess(): boolean {
    return this.IsSuccess
  }

  public setIsSuccess(success: boolean): void {
    this.IsSuccess = success
  }

  public getErrorMessage(): string {
    return this.ErrorMessage
  }

  public setErrorMessage(ErrorMessage: string): void {
    this.ErrorMessage = ErrorMessage
  }

  public getResult(): string {
    return this.Result
  }

  public setResult(Result: string): void {
    this.Result = Result
  }

  public getUrl(): string {
    return this.URL
  }

  public setUrl(URL: string): void {
    this.URL = URL
  }

  public getType(): string {
    return this.Type
  }

  public setType(Type: string): void {
    this.Type = Type
  }

  public toString(): string {
    return `DecodeResult{isSuccess=${this.IsSuccess}, errorMessage='${this.ErrorMessage}', result='${this.Result}', type='${this.Type}', url='${this.URL}'}`
  }

  public toPlainObject(): DecodeResultDTO {
    return {
      IsSuccess: this.IsSuccess,
      ErrorMessage: this.ErrorMessage,
      Result: this.Result,
      Url: this.URL,
      Type: this.Type
    };
  }
}

export interface DecodeResultDTO {
  IsSuccess: boolean;
  ErrorMessage?: string;
  Result: string;
  Url: string;
  Type: string;
}