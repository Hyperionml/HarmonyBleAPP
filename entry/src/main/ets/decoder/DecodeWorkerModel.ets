import { DecodeResultBean, DecodeResultData } from "../bean/DecodeResultBean";
import { DecoderCameraParameters } from "./DecoderCameraParameters";
import { image, sendableImage } from "@kit.ImageKit";
import { Size } from "@ohos.arkui.node";

export enum WorkerPostMessageType {
  Init = 'Init',
  Start = 'Start',
  Stop = 'Stop',
  IsQT = 'IsQT',
  SetParams = 'SetParams',

  //测试sendableImage直接解码
  ImageData = 'ImageData',
}
export interface InitMsg {
  type:WorkerPostMessageType.Init;
  sab:SharedArrayBuffer;
  width: number;
  height: number;
  format: image.PixelMapFormat;
  successSleepTime:number;
  imageSize:Size|undefined;
  screenOrientation:number|undefined;
}
//配置参数
export interface SetParamsMsg {
  type:WorkerPostMessageType.SetParams;
  imageSize:Size;
  screenOrientation:number;
}
//变更模式
export interface IsQTMsg {
  type: WorkerPostMessageType.IsQT;
  isQT: boolean;
}
//开关（Start/Stop）
export interface SwitchMsg {
  type: WorkerPostMessageType.Start | WorkerPostMessageType.Stop;
}
//测试sendableImage直接解码
export interface ImageDataMsg {
  type: WorkerPostMessageType.ImageData;
  data: sendableImage.PixelMap
}
export type DecodeWorkerMsg = InitMsg | IsQTMsg |SetParamsMsg |SwitchMsg |ImageDataMsg;


export enum WorkerOnMessageType {
  DecodeResult = 'DecodeResult',
  WorkerReady = "WorkerReady",
  StateChanged = "StateChanged",
  Frame = "Frame"
}
export interface DecodeResultMsg {
  type:WorkerOnMessageType;
  ok:boolean;
  data: DecodeResultData;
  isWorking:boolean;
  frame:Uint8Array
}