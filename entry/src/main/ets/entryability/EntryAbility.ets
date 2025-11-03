import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ThemeControl, window } from '@kit.ArkUI';
import { DeviceManager, QTBle } from 'devices'
import WindowUtil from '../utils/WindowUtil';
import { SoundPlayUtils } from 'common';
import BuildProfile from 'BuildProfile';
import { AppSetting } from '../common/AppSetting';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    //在启动应用是初始化
    if(BuildProfile.BLE_MODE){
      QTBle.init()
    }else {
      DeviceManager.init(this.context)
    }
    // 虽然不太可能在别的设备上运行该项目，但还是防止在不支持声音的设备上初始化
    // canIUse方法应该使用系统能力名称，需查阅鸿蒙api文档,例如:media.createSoundPool 的系统能力为 SystemCapability.Multimedia.Media.SoundPool
    if(canIUse('SystemCapability.Multimedia.Media.SoundPool')){
      SoundPlayUtils.init(this.context)
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    let win = windowStage.getMainWindowSync();
    //App全屏
    WindowUtil.enterImmersive(win);
    //避让区域
    WindowUtil.getAvoidArea(win);
    //强制横屏/竖屏/自动旋转
    WindowUtil.setPreferredOrientation(win, window.Orientation.UNSPECIFIED);// 竖屏: PORTRAIT ,横屏: LANDSCAPE ,自动旋转: AUTO_ROTATION ,表示未定义方向模式，由系统判定: UNSPECIFIED

    let page = 'pages/IndexPageRefactored';
    //let page = 'pages/IndexPage'
    let appSetting = new AppSetting(this.context)

    //SplashPage页调整到这里,增加SplashPage开关
    const isAllowAgreement = appSetting.getIsAllowAgreementSync()
    if(BuildProfile.UsingSplashPage && !isAllowAgreement){
      page = 'pages/SplashPage'
    }
    else{
      //首页获取获取显示引导页的次数调整到这里
      const showUserGuideCount = appSetting.getShowUserGuideCountSync();
      if(showUserGuideCount == 0)
        page = 'pages/GuidePage';
    }

    windowStage.loadContent(page, (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}