import { DecodeResult, DecodeResultDTO } from "../models/json/DecodeResult";
import { AbsProductManager } from "./AbsProductManager";
import { IProductManageListener } from "./IProductManageListener";

// todo 这个类似乎没法实现，FragmentManager之类的机制已经被鸿蒙弃用了
export class DestroyProductManager extends AbsProductManager {

    // private mManager: FragmentManager
    // private mDestroyFragment: DestroyFragment
    //
    //
    public constructor(handle: IProductManageListener) {
        super(handle);
    }

    public processDecodeResult(decodeResult: DecodeResultDTO): void {
        throw new Error("Method not implemented.");
    }

}