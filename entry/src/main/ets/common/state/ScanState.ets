export enum ScanState {
  /**
   * 基础状态
   * */
  IDLE = 'idle',
  /**
   * 正在请求权限
   * */
  PERMISSION_REQUESTING = 'permission_requesting',
  /**
   * 正在初始化
   * */
  INITTING = 'initting',
  /**
   * 初始化完毕，正在扫描
   * */
  SCANNING = 'scanning',

  /**
   * 收到扫描结果，进行网络解码，解码完成后再处理扫描结果
   * */
  WEB_DECODE = 'web_decode',

  /**
   * 切换模式，不处理解码等事件
   * */
  SWITCH_MODE = 'switch_mode',
  /**
   * 弹窗状态,有窗口弹出时，专注窗口业务，不处理解码等事件
   * */
  FLOAT_PANELS_SHOW = 'float_panels_show',
  /**
   * 正在跳转,不处理解码等事件
   * */
  JUMPING = 'jumping',
  /**
   * 已进入其他页面
   * */
  JUMPED_SUCCESS = 'jumped_success',

  /**
   * ERROR
   * */
  ERROR = 'error'
}