import { WebDecodeError } from "./WebDecodeError";
import { DecodeResult, DecodeResultDTO } from "../common/models/json/DecodeResult";
export interface IWebDecodeResultHandle {
  onStartWebDecode:() => void;
  onEndWebDecode:( result:DecodeResultDTO, error:WebDecodeError) => void;
}