/**
 *蓝牙请求类型模型
 *封装蓝牙通信中的请求类型
 */
export class BTRequest{
  //请求类型字段
  private RequestType : string = "";
  public static readonly TYPE_BATTERY : string = "Battery";//获取电池请求
  public static readonly TYPE_VERSION: string = "Version"; // 获取版本请求
  public static readonly TYPE_PHOTO: string = "Photo";     // 获取照片请求

  //获取当前请求类型
  public getRequestType(): string{
    return this.RequestType;
  }

  //设置请求类型
  public setRequestType(requestType:string){
    this.RequestType = requestType;
  }
}
