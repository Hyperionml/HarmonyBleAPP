export enum AppEventType {
  // 系统级事件
  Ready = "Ready",
  LayoutChange = "LayoutChange",
  Permission = "Permission",
  BackPressed = "BackPressed",
  SystemLanguageChanged = "SystemLanguageChanged",

  // 相机相关事件
  CameraParamsEvents = "CameraParamsEvents",
  CameraStateEvents = "CameraStateEvents",
  CameraDeviceError = "CameraDeviceError",
  OpenCamera = "OpenCamera",

  // 设置相关事件
  CommonOpenSetting = "CommonOpenSetting",
  CommonShowSettingButton = "CommonShowSettingButton",
  SetLanguage = "SetLanguage",
  SaveLanguage = "SaveLanguage",
  SetUrl = "SetUrl",
  SetWifi = "SetWifi",
  SetSelfWifi = "SetSelfWifi",
  RequestWifiParam = "RequestWifiParam",

  // 界面相关事件
  OpenToolPanel = "OpenToolPanel",
  OpenResultPanel = "OpenResultPanel",
  OpenGuidePanel = "OpenGuidePanel",
  CloseFloatPanels = "CloseFloatPanels",
  ShowFragment = "ShowFragment",
  HideFragment = "HideFragment",
  ShowVideo = "ShowVideo",
  SetClose = "SetClose",
  ScanBoxInitted = "ScanBoxInitted",//扫描框渲染完成
  ScanBoxSafeArea = "ScanBoxSafeArea",//避开扫描框的安全区域
  PreviewReady = "PreviewReady",//Preview准备完成
  DisplayRotation = "DisplayRotation",//屏幕旋转事件

  // 扫描相关事件
  StartScan = "StartScan",
  StopScan = "StopScan",
  ScanResult = "ScanResult",
  QCScaned = "QCScaned",
  DestroyScaned = "DestroyScaned",

  // 系统功能事件
  Update = "Update",
  CheckUpdate = "CheckUpdate",
  InvokeVersionName = "InvokeVersionName",
  Reboot = "Reboot",

  // 服务相关事件
  DecodeService = "DecodeService",
  QCService = "QCService",
  ProductManager = "ProductManager",
  RequestLogin = "RequestLogin",

  // 用户交互事件
  ManualZoom = "ManualZoom",
  ManualFocus = "ManualFocus",
  Voice = "Voice",
  Shake = "Shake",
  TTS = "TTS",
  ScreenShot = "ScreenShot",
  ScreenShot2 = "ScreenShot2",
  ScreenShot3 = "ScreenShot3",

  // 状态相关事件
  ActivityJumpSucceed = "ActivityJumpSucceed",
  Battery = "Battery",
  BatteryWarning = "BatteryWarning",
  WaitingMask = "WaitingMask",
  CountZeroMask = "CountZeroMask",

  // 登录相关事件
  StartLogin = "StartLogin",
  LoginComplete = "LoginComplete",
  StartLogout = "StartLogout",
  LogoutComplete = "LogoutComplete"
}