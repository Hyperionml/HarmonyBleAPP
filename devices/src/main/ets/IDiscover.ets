import { AbsDevice } from "./AbsDevice"

export interface IDiscover {
    discoverStart: () => void
    discoverEnd: () => void
    discover: (device: AbsDevice) => void
}