import { Configuration } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';
import { abilityAccessCtrl, bundleManager, Permissions,common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { EventManager, Level } from 'common';
import { AppEventType } from '../../common/event/AppEventType';
import { AppEvent } from '../../common/event/AppEvent';

/**
 * 安卓的BaseActivity
 * Activity基类 - 统一管理所有页面
 * 1.权限管理系统
 * 2.GPS定位服务
 * 3.生命周期状态管理ActivityState
 * 4.UI主题和多语言
 * 5.沉浸式状态栏
 * 6.对话框管理
 * 7.产品类型,获取ProductType,供ProductManager使用
 * */

@Component
export struct BasePage {

  onPageShow() {
    EventManager.async(this, new AppEvent(AppEventType.ActivityJumpSucceed, Level.High));
  }
  build() {}
}


// export class BasePage {
//     protected isForeground: boolean = false;//是否显示在屏幕中(返回系统界面等，会为false)
//     private progressDialog: CustomDialogController | null = null;
//     // 标记进度对话框是否正在显示
//     private isProgressDialogShowing: boolean = false;
//   private permissions: Array<Permissions> = ['ohos.permission.CAMERA'];//,'ohos.permission.APPROXIMATELY_LOCATION'
//   static reqPermissionsFromUser(permissions: Array<Permissions>, context: common.UIAbilityContext,callback: () => void): void {
//     let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
//     // requestPermissionsFromUser会判断权限的授权状态来决定是否唤起弹窗
//     atManager.requestPermissionsFromUser(context, permissions).then((data) => {
//       let grantStatus: Array<number> = data.authResults;
//       let length: number = grantStatus.length;
//       for (let i = 0; i < length; i++) {
//         if (grantStatus[i] === 0) {
//           // 用户授权，可以继续访问目标操作
//         } else {
//           // 用户拒绝授权，提示用户必须授权才能访问当前页面的功能，并引导用户到系统设置中打开相应的权限
//           return;
//         }
//       }
//       // 全部授权成功
//       if (callback) {
//         callback();
//       }
//     }).catch((err: BusinessError) => {
//       console.error(`Failed to request permissions from user. Code is ${err.code}, message is ${err.message}`);
//     })
//   }
//   /**
//    * 显示等待对话框
//    */
//   public showWaitingDialog(): boolean {
//     // 通过检查页面状态来判断是否可以显示对话框
//     const isForeground = true;
//     const isDestroyed = false;
//
//     if (!isForeground || isDestroyed) {
//       return false;
//     }
//
//     // 显示进度对话框
//     if (this.progressDialog) {
//       this.progressDialog.open();
//       this.isProgressDialogShowing = true;
//     }
//     return true;
//   }
//
//   /**
//    * 取消等待对话框
//    */
//   public cancelWaitingDialog(): boolean {
//     if (this.progressDialog != null && this.isProgressDialogShowing) {
//       try {
//         this.progressDialog.close();
//         this.isProgressDialogShowing = false;
//         return true;
//       } catch (error) {
//         return false;
//       }
//     }
//     return false;
//   }
//   static getResourceString(resource: Resource | string , __this: object): string {
//     if(!resource)
//       return ""
//     if(typeof resource == "string")
//       return resource
//     if (!resource.id){
//       return ""
//     }
//     //https://developer.huawei.com/consumer/cn/forum/topic/0201187523291680003?fid=0109140870620153026
//     //代码中涉及上下文、资源管理器时请使用真机或模拟器进行尝试
//     let resourceString = getContext(__this).resourceManager.getStringSync(resource) || 'test';
//     return resourceString;
//   }
// }