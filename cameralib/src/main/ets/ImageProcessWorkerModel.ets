import { sendableImage } from "@kit.ImageKit";

export enum ImageProcessMessageType{
  Init = 'Init',
  ProcessImage = 'ProcessImage'
}
export interface InitMsg {
  type:string,
  imageData:sendableImage.PixelMap,
  maxImageCount:number,
  cameraOrientation:number,
  isFront:boolean
}
export type ImageProcessMsg = InitMsg;

export enum ImageProcessStatus{
  None = 'None',
  Initted = 'Initted',
  //Running = 'Running'
}

