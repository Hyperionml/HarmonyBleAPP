import { Event, Level } from "common";
import { DeviceEventType } from "./DeviceEventType";

export class DeviceEvent extends Event{
    protected type: DeviceEventType

    public constructor(type: DeviceEventType, level: Level = Level.Common, data: Object | null | string = null) {
        super();
        this.type = type;
        this.level = level;
        this.data = data;
    }

    /**
     * 消息类型
     */
    public getEventType(): DeviceEventType {
        return this.type;
    }

    public setEventType(type: DeviceEventType): void {
        this.type = type;
    }

}