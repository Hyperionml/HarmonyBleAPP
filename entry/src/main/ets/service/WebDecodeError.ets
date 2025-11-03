export enum WebDecodeError {
  None,                // 没有异常
  Cancel,              // 取消
  Unknown,             // 未知异常
  OffLine,             // 无法使用网络
  NoConnectedNetwork,  // 未打开网络
  NetPermissionDenied, // 需要网络权限
  ServerError,         // 服务器出错
  Destroy              // 码图被破坏，无法正常解码
}