import { Component } from "@kit.TestKit";
import { DecodeResult, DecodeResultDTO } from "../models/json/DecodeResult";
import { IProductManageListener } from "./IProductManageListener";

export abstract class AbsProductManager{
    //protected mAppCompatActivity: Component | null = null
    protected mDecodeResult: DecodeResult | null = null
    protected mProductManageListener: IProductManageListener | null = null

    //appCompatActivity?: Component,
    public constructor(handle: IProductManageListener) {
        //this.mAppCompatActivity = appCompatActivity;
        this.mProductManageListener = handle;
    }

    public abstract processDecodeResult(decodeResult: DecodeResultDTO): void
}