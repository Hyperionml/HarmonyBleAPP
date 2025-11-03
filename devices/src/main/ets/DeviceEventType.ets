export enum DeviceEventType {
  BluetoothCode = "BluetoothCode",
  BluetoothConnectionStarted = "BluetoothConnectionStarted",
  BluetoothConnectionSuccess = "BluetoothConnectionSuccess",
  BluetoothConnectionFailed = "BluetoothConnectionFailed",
  BluetoothDisconnected = "BluetoothDisconnected",
  BluetoothDiscoverStart = "BluetoothDiscoverStart",
  BluetoothDiscoverEnd = "BluetoothDiscoverEnd",
  BluetoothCancelDiscover = "BluetoothCancelDiscover",


  BluetoothQC = "BluetoothQC",


  //截屏
  TakePhoto = "TakePhoto",
  //蓝牙的版本号
  BluetoothVersion = "BluetoothVersion",
  //更新蓝牙
  CheckBluetoothVersion = "CheckBluetoothVersion",
  CheckBluetoothVersionEnd = "CheckBluetoothVersionEnd",

  //有新的升级包可以昂蓝牙升级
  BluetoothCanUpdate = "BluetoothCanUpdate",

  //设置蓝牙时间
  SetBluetoothSysTime = "SetBluetoothSysTime",

  //蓝牙电量
  BluetoothBattery = "BluetoothBattery",

  BluetoothBatteryUnknown = "BluetoothBatteryUnknown",

  //文件传输进度
  TransferProgress = "TransferProgress",

  //接受到文件
  ReceivedFile = "ReceivedFile",

  //自动连接蓝牙
  BluetoothAutoConnect = "BluetoothAutoConnect",
  BluetoothStateChanged = "BluetoothStateChanged"
}