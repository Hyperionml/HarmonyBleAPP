import { LinkedList } from "@kit.ArkTS"
import { CommonDialogFragment } from "../DialogFragmentManege/CommonDialogFragment"
import { PopupManageType } from "./Type"
/**
 * 这是弹窗的管理类，可以在需要使用的地方创建实例来管理一个界面下的所有弹窗显示与关闭‘’
 *
 * 所有的弹窗都需要一个CommonDialogFragment类的包装类，这个包装类唯一必要的只有存储它对应的CommonDialogFragment实例
 *
 * 推荐参照ProgressDialog的设计思路，设计一个初始化方法并设计一个该弹窗类的一个参数传递类（是用于弹窗内容更新的），初始化方法中最好传递一个
 * 窗体消失的监听回调函数，然后该函数中最好书写PopupManage的hide方法来确保弹窗消失时一定会从弹窗栈mOpenedFloats中弹出
 *
 * 在包装好自定义弹窗类之后就可以开始使用了：
 * 1.在需要使用的界面里最好是aboutToAppear生命周期里初始化
 * 2.显示弹窗：popupManage.show(ProgressDialog.fragment!)
 *  其中的ProgressDialog.fragment就是上文提到的弹窗类必须包装的CommonDialogFragment成员变量
 * 3.关闭弹窗：popupManage.hide(ProgressDialog.fragment!)
 *
 * tip：在更新弹窗中的参数时一定要使用CommonDialogFragment中的contentNode对象，也可以把这个对象在初始化的时候直接存储在弹窗类中方便调用
 *  但是一定不要2次赋值，不然无法保证程序运行的正确性
 */
export class PopupManage {

    private static readonly TAG = 'PopupManage'

    mContext: Context | null = null
    mOpenedFloats: LinkedList<CommonDialogFragment> | null = null
    mType = PopupManageType.LIFO;

    private getOpenedFloat() {
        let openedFloat: CommonDialogFragment | null = null;
        if (this.mOpenedFloats!.length > 0) {
            if (this.mType == PopupManageType.FIFO) {
                openedFloat = this.mOpenedFloats!.removeFirst();
            } else {
                openedFloat = this.mOpenedFloats!.removeLast();
            }
        }
        return openedFloat;
    }

    public constructor(context: Context, type?: PopupManageType) {
        this.mContext = context
        this.mOpenedFloats = new LinkedList()
        this.mType = type !== undefined ? type : PopupManageType.LIFO
    }

    /**
     * 打开指定弹窗
     * @param vm
     */
    public show(vm: CommonDialogFragment) {
        vm.openDialog()
        this.addOpenedFloat(vm);
    }

    /**
     * 关闭指定弹窗
     * @param vm
     */
    public hide(vm: CommonDialogFragment) {
        if (this.mOpenedFloats?.has(vm)) {
            //vm.closeDialog()
            this.removeOpenedFloat(vm);
        }
    }

    private prHideAll() {
        let isHide = false;
        let openedFloat = this.getOpenedFloat();
        if (openedFloat != null) {
            openedFloat.closeDialog()
            this.removeOpenedFloat(openedFloat);
            isHide = true;
        }
        return isHide;
    }

    /**
     * 关闭所有弹窗
     */
    public hideAll() {
        let isContinue = true;
        while (isContinue) {
            isContinue = this.prHideAll();
        }
    }

    /**
     * 获取当前有几个弹窗正在弹出
     * @returns
     */
    public getShowSize() {
        return this.mOpenedFloats?.length === undefined ? 0 : this.mOpenedFloats?.length
    }

    public existDialogs():boolean { return this.getShowSize() > 0; }

    private addOpenedFloat(vm: CommonDialogFragment) {
        let index = this.mOpenedFloats?.getIndexOf(vm)
        if (index != -1){
            this.mOpenedFloats?.removeByIndex(index);
        }
        this.mOpenedFloats?.add(vm);
    }

    private removeOpenedFloat(vm: CommonDialogFragment) {
        let index = this.mOpenedFloats?.getIndexOf(vm);
        if (index != -1) {
            this.mOpenedFloats?.removeByIndex(index);
        }
    }

}