import { camera } from '@kit.CameraKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { IRelease } from './IRelease';
import { Logger } from 'common';
import OutputManager from './Api/OutputManager';
import { ICameraListener } from './AbsCamera';

const TAG = 'AbsCameraManager';

export abstract class AbsCameraManager implements IRelease {
  protected cameraManager: camera.CameraManager;
  session?: camera.PhotoSession | camera.VideoSession;
  protected cameraInput?: camera.CameraInput;
  protected outputManagers: OutputManager[] = [];

  constructor(context: Context, outputManagers: OutputManager[]) {
    // [Start cameraManager]
    this.cameraManager = camera.getCameraManager(context);
    // [End cameraManager]
    this.outputManagers = outputManagers;
    this.addCameraStatusListener();
  }

  addCameraStatusListener() {
    this.cameraManager.on('cameraStatus', (err: BusinessError, statusInfo: camera.CameraStatusInfo) => {
      if (err && err.message) {
        Logger.error(TAG, 'cameraStatus with errorMessage = ' + err.message);
        return;
      }
      Logger.info(TAG, `cameraStatusInfo: camera is ${statusInfo.camera.cameraId}, status is ${statusInfo.status}`);
    });
  }

  // 初始化相机
  //abstract init(xComponentSurfaceId: string, listener: ICameraListener): Promise<boolean>;

  // 释放资源
  abstract release(): void;
}