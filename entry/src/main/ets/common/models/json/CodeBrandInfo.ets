export class CodeBrandInfo {
  private isDemo: boolean = false;
  private qtVersion: string = '';
  private brand: string = '';
  private dotCounts: number = 0;
  private minDotCounts: number = 0;
  private maxDotCounts: number = 0;
  private limitedErrorCounts: number = 0;

  constructor() { }

  public getIsDemo(): boolean {
    return this.isDemo;
  }

  public setIsDemo(demo: boolean): void {
    this.isDemo = demo;
  }

  public getQtVersion(): string {
    return this.qtVersion;
  }

  public setQtVersion(version: string): void {
    this.qtVersion = version;
  }

  public getBrand(): string {
    return this.brand;
  }

  public setBrand(brand: string): void {
    this.brand = brand;
  }

  public getDotCounts(): number {
    return this.dotCounts;
  }

  public setDotCounts(counts: number): void {
    this.dotCounts = counts;
  }

  public getMinDotCounts(): number {
    return this.minDotCounts;
  }

  public setMinDotCounts(counts: number): void {
    this.minDotCounts = counts;
  }

  public getMaxDotCounts(): number {
    return this.maxDotCounts;
  }

  public setMaxDotCounts(counts: number): void {
    this.maxDotCounts = counts;
  }

  public getLimitedErrorCounts(): number {
    return this.limitedErrorCounts;
  }

  public setLimitedErrorCounts(counts: number): void {
    this.limitedErrorCounts = counts;
  }
}