export class LoginResultData {
  private UserId: string = '';
  private UserName: string = '';
  private UserType: string = '';
  private CustomerId: string = '';
  private CustomerName: string = '';
  private CustomerAlias: string = '';
  private FactoryName: string = '';
  private AccessToken: string = '';
  private Company: string = '';
  private Id: number = 0;
  private DissociatePO: string = '';
  private BsnQcImageFtpHost: string = '';
  private BsnQcImageFtpPort: string = '';
  private BsnQcImageFtpUserName: string = '';
  private BsnQcImageFtpPassword: string = '';
  private BsnQcImageFtpWorkDirectory: string = '';

  public getUserId(): string {
    return this.UserId;
  }

  public setUserId(userId: string): void {
    this.UserId = userId;
  }

  public getUserName(): string {
    return this.UserName;
  }

  public setUserName(userName: string): void {
    this.UserName = userName;
  }

  public getUserType(): string {
    return this.UserType;
  }

  public setUserType(userType: string): void {
    this.UserType = userType;
  }

  public getCustomerId(): string {
    return this.CustomerId;
  }

  public setCustomerId(customerId: string): void {
    this.CustomerId = customerId;
  }

  public getCustomerName(): string {
    return this.CustomerName;
  }

  public setCustomerName(customerName: string): void {
    this.CustomerName = customerName;
  }

  public getCustomerAlias(): string {
    return this.CustomerAlias;
  }

  public setCustomerAlias(customerAlias: string): void {
    this.CustomerAlias = customerAlias;
  }

  public getFactoryName(): string {
    return this.FactoryName;
  }

  public setFactoryName(factoryName: string): void {
    this.FactoryName = factoryName;
  }

  public getAccessToken(): string {
    return this.AccessToken;
  }

  public setAccessToken(accessToken: string): void {
    this.AccessToken = accessToken;
  }

  public getCompany(): string {
    return this.Company;
  }

  public setCompany(company: string): void {
    this.Company = company;
  }

  public getId(): number {
    return this.Id;
  }

  public setId(id: number): void {
    this.Id = id;
  }

  public getDissociatePO(): string {
    return this.DissociatePO;
  }

  public setDissociatePO(dissociatePO: string): void {
    this.DissociatePO = dissociatePO;
  }

  public getBsnQcImageFtpHost(): string {
    return this.BsnQcImageFtpHost;
  }

  public setBsnQcImageFtpHost(bsnQcImageFtpHost: string): void {
    this.BsnQcImageFtpHost = bsnQcImageFtpHost;
  }

  public getBsnQcImageFtpPort(): string {
    return this.BsnQcImageFtpPort;
  }

  public setBsnQcImageFtpPort(bsnQcImageFtpPort: string): void {
    this.BsnQcImageFtpPort = bsnQcImageFtpPort;
  }

  public getBsnQcImageFtpUserName(): string {
    return this.BsnQcImageFtpUserName;
  }

  public setBsnQcImageFtpUserName(bsnQcImageFtpUserName: string): void {
    this.BsnQcImageFtpUserName = bsnQcImageFtpUserName;
  }

  public getBsnQcImageFtpPassword(): string {
    return this.BsnQcImageFtpPassword;
  }

  public setBsnQcImageFtpPassword(bsnQcImageFtpPassword: string): void {
    this.BsnQcImageFtpPassword = bsnQcImageFtpPassword;
  }

  public getBsnQcImageFtpWorkDirectory(): string {
    return this.BsnQcImageFtpWorkDirectory;
  }

  public setBsnQcImageFtpWorkDirectory(bsnQcImageFtpWorkDirectory: string): void {
    this.BsnQcImageFtpWorkDirectory = bsnQcImageFtpWorkDirectory;
  }

  public static fromPlainObject(data: Object): LoginResultData {
    const result = new LoginResultData();
    if (data && typeof data === 'object' && !Array.isArray(data)) {
      const jsonData = data as LoginResultDataJson;
      result.UserId = jsonData.UserId;
      result.UserName = jsonData.UserName;
      result.UserType = jsonData.UserType;
      result.CustomerId = jsonData.CustomerId;
      result.CustomerName = jsonData.CustomerName;
      result.CustomerAlias = jsonData.CustomerAlias;
      result.FactoryName = jsonData.FactoryName;
      result.AccessToken = jsonData.AccessToken;
      result.Company = jsonData.Company;
      result.Id = jsonData.Id || 0;
      result.DissociatePO = jsonData.DissociatePO;
      result.BsnQcImageFtpHost = jsonData.BsnQcImageFtpHost;
      result.BsnQcImageFtpPort = jsonData.BsnQcImageFtpPort;
      result.BsnQcImageFtpUserName = jsonData.BsnQcImageFtpUserName;
      result.BsnQcImageFtpPassword = jsonData.BsnQcImageFtpPassword;
      result.BsnQcImageFtpWorkDirectory = jsonData.BsnQcImageFtpWorkDirectory;
    }
    return result;
  }
}
export interface LoginResultDataJson {
  UserId: string;
  UserName: string;
  UserType: string;
  CustomerId: string;
  CustomerName: string;
  CustomerAlias: string;
  FactoryName: string;
  AccessToken: string;
  Company: string;
  Id: number;
  DissociatePO: string;
  BsnQcImageFtpHost: string;
  BsnQcImageFtpPort: string;
  BsnQcImageFtpUserName: string;
  BsnQcImageFtpPassword: string;
  BsnQcImageFtpWorkDirectory: string;
}
