/**
 * 对应Android的ActivityState枚举，标识页面的生命周期状态
 */
export enum ActivityState {
  Unknow = 0,// 未知状态
  Created = 1,
  Started = 4,
  Resume = 8,// 已恢复:页面可见可交互
  Running = 16,// 运行中
  Paused = 32,// 已暂停：页面可见但不可交互
  Stop = 64,// 已停止：页面不可见
  Destroy = 128// 已销毁

}

export function getCode(state: ActivityState): number {
  return state;
}
