import { PrintQuality, PrintDeep, CodeTypes } from 'decoder';

export class QCResult {
  private PrintQuality: PrintQuality = null;
  private IsSuccess: boolean = false;
  private IsError: boolean = false;
  private PrintDeep: PrintDeep = null;
  private PrintError: PrintQuality = null;
  private NoGoodCount: number = 0;
  private NoGoodDotCount: number = 0;
  private Generation: CodeTypes = null;
  private IsDemo: boolean = false;
  private ErrorMessage: string = '';
  private CodeId: string = '';

  public getPrintQuality(): PrintQuality {
    return this.PrintQuality;
  }

  public setPrintQuality(printQuality: PrintQuality): void {
    this.PrintQuality = printQuality;
  }

  public isSuccess(): boolean {
    return this.IsSuccess;
  }

  public setSuccess(success: boolean): void {
    this.IsSuccess = success;
  }

  public getPrintDeep(): PrintDeep {
    return this.PrintDeep;
  }

  public setPrintDeep(printDeep: PrintDeep): void {
    this.PrintDeep = printDeep;
  }

  public getNoGoodCount(): number {
    return this.NoGoodCount;
  }

  public setNoGoodCount(noGoodCount: number): void {
    this.NoGoodCount = noGoodCount;
  }

  public getNoGoodDotCount(): number {
    return this.NoGoodDotCount;
  }

  public setNoGoodDotCount(noGoodDotCount: number): void {
    this.NoGoodDotCount = noGoodDotCount;
  }

  public getGeneration(): CodeTypes | undefined {
    return this.Generation;
  }

  public setGeneration(generation: CodeTypes | undefined): void {
    this.Generation = generation;
  }

  public isDemo(): boolean {
    return this.IsDemo;
  }

  public setDemo(demo: boolean): void {
    this.IsDemo = demo;
  }

  public getErrorMessage(): string {
    return this.ErrorMessage;
  }

  public setErrorMessage(errorMessage: string): void {
    this.ErrorMessage = errorMessage;
  }

  public getCodeId(): string {
    return this.CodeId;
  }

  public setCodeId(codeId: string): void {
    this.CodeId = codeId;
  }

  public isError(): boolean {
    return this.IsError;
  }

  public setError(error: boolean): void {
    this.IsError = error;
  }

  public getPrintError(): PrintQuality {
    return this.PrintError;
  }

  public setPrintError(printError: PrintQuality): void {
    this.PrintError = printError;
  }
}