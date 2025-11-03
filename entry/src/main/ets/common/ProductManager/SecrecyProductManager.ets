import { AbsProductManager } from "./AbsProductManager";
import { Component } from "@kit.TestKit";
import { IProductManageListener } from "./IProductManageListener";
import { DecodeResult, DecodeResultDTO } from "../models/json/DecodeResult";
import { TextUtils } from "@ohos/fastble/Index";

export class SecrecyProductManager extends AbsProductManager{
    private appCompatActivity: Component;
    public constructor(appCompatActivity: Component, handle: IProductManageListener) {
        super(handle);
        this.appCompatActivity = appCompatActivity;
    }

    public processDecodeResult(decodeResult: DecodeResultDTO) {
        let code = decodeResult.Result
        if (!TextUtils.isEmpty(code)) {
            this.mProductManageListener!.onSecrecySuccess(code);
        }
    }
}