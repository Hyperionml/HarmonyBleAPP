/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 ("the License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { display, window } from '@kit.ArkUI';
import { EventManager, Level, Logger } from 'common';
import { AppEvent } from '../common/event/AppEvent';
import { AppEventType } from '../common/event/AppEventType';

const TAG = 'WindowUtil'
const ORIENTATION: Array<string> = ['垂直', '平', '反向垂直', '反向水平'];

class WindowUtil {
  static async enterImmersive(window: window.Window): Promise<void> {
    try {
      await window.setWindowLayoutFullScreen(true);
      await window.setWindowSystemBarEnable([]);
    } catch (exception) {
      Logger.error(TAG, 'Failed to enter immersive. Cause:', JSON.stringify(exception));
    }
  }

  static avoidArea: window.AvoidArea;
  static getAvoidArea(windowClass: window.Window){
    let type = window.AvoidAreaType.TYPE_SYSTEM;
    try {
      WindowUtil.avoidArea = windowClass.getWindowAvoidArea(type);
      console.log('规避区域:' + JSON.stringify(WindowUtil.avoidArea));
    } catch (exception) {
      console.error('Failed to obtain the area. Cause:' + JSON.stringify(exception));
    }
  }

  private static rotation :number|null = null;
  static setPreferredOrientation(windowClass: window.Window,orientation:window.Orientation){
    windowClass.setPreferredOrientation(orientation);
    let callback = async () => {
      let getDefaultDisplay = display.getDefaultDisplaySync();
      let rotation = getDefaultDisplay.rotation;
      if(WindowUtil.rotation == null){
        WindowUtil.rotation = rotation;
      } else if(rotation != WindowUtil.rotation){
        WindowUtil.rotation = rotation;
        let message = ORIENTATION[rotation];
        Logger.warn(TAG, '监听屏幕显示（横竖）方向变化: ' + message);
        EventManager.sync(TAG,new AppEvent(AppEventType.DisplayRotation,Level.High,message))
      }
    };
    try {
      display.on('change', callback);
    } catch (exception) {
      Logger.error(TAG, 'Failed to register callback. Code: ' + JSON.stringify(exception));
    }

    // rotationChange 需要 API19+
    // if(orientation == window.Orientation.AUTO_ROTATION){
    //   // 注册屏幕状态变化监听
    //   try {
    //     const callback = (info: window.RotationChangeInfo): window.RotationChangeResult | void => {
    //       EventManager.sync(TAG,new AppEvent(AppEventType.DisplayRotation,Level.High,info))
    //     }
    //     windowClass.on('rotationChange', callback);
    //   } catch (exception) {
    //     console.error(`Failed to register callback. Cause code: ${exception.code}, message: ${exception.message}`);
    //   }
    // }
  }

  // Given a ratio, obtain the maximum display width and height based on the screen width and height.
  static getMaxDisplaySize(): Size {
    const defaultDisplay: display.Display = display.getDefaultDisplaySync();
    const windowWidth: number = defaultDisplay.width;
    const windowHeight: number = defaultDisplay.height;
    return {
      width: windowWidth,
      height: windowHeight
    };
  }

  static getWindowRatio(): number {
    const defaultDisplay: display.Display = display.getDefaultDisplaySync();
    return defaultDisplay.height / defaultDisplay.width;
  }
}

export default WindowUtil;