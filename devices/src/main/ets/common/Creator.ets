import { Parcel } from "./Parcel";

export interface Creator<T> {
    createFromParcel: (source: Parcel) =>  T
    newArray: (size: number) => T[]
}