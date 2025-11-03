import { ProtocolBufferSerialization } from "./ProtocolBufferSerialization";

export class SerializationFactory{

    public static create(){
        return new ProtocolBufferSerialization()
    }
}