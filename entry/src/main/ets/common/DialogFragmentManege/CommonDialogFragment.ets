import { promptAction } from "@kit.ArkUI";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { BusinessError } from "@kit.BasicServicesKit";

export class CommonDialogFragment {

    public static readonly TAG = 'CommonDialogFragment'

    /**
     * 建议所有弹窗类都对该类进行包装，并在类中设计初始化操作并避免2次操作成员变量
     */
    ctx: UIContext | null = null
    contentNode: ComponentContent<Object> | null = null
    options: promptAction.BaseDialogOptions | null = null

    setContext(context: UIContext) {
        this.ctx = context;
    }

    setContentNode(node: ComponentContent<Object>) {
        this.contentNode = node;
    }

    setOptions(options: promptAction.BaseDialogOptions) {
        this.options = options;
    }

    /**
     * 如果使用了PopupManage管理弹窗则一定不要使用该方法操作弹窗
     */
    openDialog() {
        if (this.contentNode !== null) {
            this.ctx!.getPromptAction().openCustomDialog(this.contentNode, this.options)
                .then(() => {
                    hilog.info(0xFF00, 'TAG', 'OpenCustomDialog complete');
                })
                .catch((error: BusinessError) => {
                    let message = (error as BusinessError).message;
                    let code = (error as BusinessError).code;
                    hilog.info(0xFF00, 'TAG', `OpenCustomDialog args error code is ${code}, message is ${message}`);
                })
        }
    }

    /**
     * 如果使用了PopupManage管理弹窗则一定不要使用该方法操作弹窗
     */
    closeDialog() {
        if (this.contentNode !== null) {
            this.ctx!.getPromptAction().closeCustomDialog(this.contentNode)
                .then(() => {
                    hilog.info(0xFF00, 'TAG', 'CloseCustomDialog complete');
                })
                .catch((error: BusinessError) => {
                    let message = (error as BusinessError).message;
                    let code = (error as BusinessError).code;
                    hilog.info(0xFF00, 'TAG', `CloseCustomDialog args error code is ${code}, message is ${message}`);
                })
        }
    }

    /**
     * 如果使用了PopupManage管理弹窗则一定不要使用该方法操作弹窗
     */
    updateDialog(options: promptAction.BaseDialogOptions) {
        if (this.contentNode !== null) {
            this.ctx!.getPromptAction().updateCustomDialog(this.contentNode, options)
                .then(() => {
                    hilog.info(0xFF00, 'TAG', 'UpdateCustomDialog complete');
                })
                .catch((error: BusinessError) => {
                    let message = (error as BusinessError).message;
                    let code = (error as BusinessError).code;
                    hilog.info(0xFF00, 'TAG', `UpdateCustomDialog args error code is ${code}, message is ${message}`);
                })
        }
    }
}