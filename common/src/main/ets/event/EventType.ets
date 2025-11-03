export enum EventType {
  // 系统级事件
  SystemLanguageChanged = "SystemLanguageChanged",

  // 通用设置事件
  CommonSettingGetLanguage = "CommonSettingGetLanguage",
  CommonSettingSetLanguage = "CommonSettingSetLanguage",
  CommonOpenSetting = "CommonOpenSetting",
  CommonShowSettingButton = "CommonShowSettingButton",

  // 低级事件
  LowLoadUrl = "LowLoadUrl",
  LowSettingGetRfidPower = "LowSettingGetRfidPower",
  LowSettingSetRfidPower = "LowSettingSetRfidPower"
}