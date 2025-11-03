import { AbsProductManager } from "./AbsProductManager";
import { Component } from "@kit.TestKit";
import { IProductManageListener } from "./IProductManageListener";
import { DecodeResult, DecodeResultDTO } from "../models/json/DecodeResult";
import { TextUtils } from "@ohos/fastble/Index";
import { router } from "@kit.ArkUI";
import { EntryUtils } from "../EntryUtils";
import { WebViewType } from "../../pages/WebPage";

export class AppProductManager extends AbsProductManager {

    private _isQTCanStartProductActivity = true;//是否可以跳转到ProductActivity，如果 isQTCanStartProductActivity = true，则可以跳转到ProductActivity，如果 isQTCanStartProductActivity = false，则已经跳转到ProductActivity，不可以重复跳转

    public static readonly REQUEST_CODE_PRODUCT_ACTIVITY = 12801;

    //appCompatActivity?: Component,
    public constructor(handle: IProductManageListener | null) {
        super(handle!)
    }

    public processDecodeResult(decodeResult: DecodeResultDTO) {
        let productUrl = decodeResult.Url; // 直接访问Url属性
        console.log('aaaTest','进入processDecodeResult，Url：', productUrl);
        if (!TextUtils.isEmpty(productUrl)) {
            this.showUrl(productUrl);
        }
    }

    private showUrl(url: string) {
        console.log('aaaTest','进入showUrl，准备跳转：', url);
        if (this._isQTCanStartProductActivity) {
            this._isQTCanStartProductActivity = false;
            this.mProductManageListener!.onAppSuccess(url);

            // 这里就是跳转新界面了
            router.pushUrl({
                url: 'pages/WebPage',
                params:{
                    url: url,
                    type: WebViewType.DecodeResult
                }
            })
        }
    }


    public isQTCanStartProductActivity(isQTCanStartProductActivity: boolean) {
        this._isQTCanStartProductActivity = isQTCanStartProductActivity;
    }
}