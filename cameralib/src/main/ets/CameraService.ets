//camera-worker demo
import { BusinessError } from '@kit.BasicServicesKit';
import { camera } from '@kit.CameraKit';
export class CameraService {
  private imageWidth: number = 1920;
  private imageHeight: number = 1080;
  private cameraManager: camera.CameraManager | undefined = undefined;
  private cameras: Array<camera.CameraDevice> | Array<camera.CameraDevice> = [];
  private cameraInput: camera.CameraInput | undefined = undefined;
  private previewOutput: camera.PreviewOutput | undefined = undefined;
  private photoOutput: camera.PhotoOutput | undefined = undefined;
  private session: camera.PhotoSession | camera.VideoSession | undefined = undefined;

  // 初始化相机。
  async initCamera(context: Context, surfaceId: string): Promise<void> {
    console.info(`initCamera surfaceId: ${surfaceId}`);
    try {
      await this.releaseCamera();
      // 获取相机管理器实例。
      this.cameraManager = camera.getCameraManager(context);
      if (this.cameraManager === undefined) {
        console.error('cameraManager is undefined');
        return;
      }
      this.cameras = this.cameraManager.getSupportedCameras();


      // 创建cameraInput输出对象。
      this.cameraInput = this.cameraManager.createCameraInput(this.cameras[0]);
      if (this.cameraInput === undefined) {
        console.error('Failed to create the camera input.');
        return;
      }
      // 打开相机。
      await this.cameraInput.open();


      let previewProfile: camera.Profile = {
        format: camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP,
        size: {
          width: this.imageWidth,
          height: this.imageHeight
        }
      };
      // 创建预览流输出。
      this.previewOutput = this.cameraManager.createPreviewOutput(previewProfile, surfaceId);
      if (this.previewOutput === undefined) {
        console.error('Failed to create the preview stream.');
        return;
      }


      let photoProfile: camera.Profile = {
        format: camera.CameraFormat.CAMERA_FORMAT_JPEG,
        size: {
          width: this.imageWidth,
          height: this.imageHeight
        }
      };
      // 创建拍照流输出。
      this.photoOutput = this.cameraManager.createPhotoOutput(photoProfile);
      if (this.photoOutput === undefined) {
        console.error('Failed to create the photoOutput.');
        return;
      }


      // 创建相机会话，启动会话。
      this.session = this.cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO) as camera.PhotoSession;
      this.session.beginConfig();
      this.session.addInput(this.cameraInput);
      this.session.addOutput(this.previewOutput);
      this.session.addOutput(this.photoOutput);
      await this.session.commitConfig();
      await this.session.start();
    } catch (error) {
      let err = error as BusinessError;
      console.error(`initCamera fail: ${err}`);
    }
  }

  // 释放相机资源。
  async releaseCamera(): Promise<void> {
    console.info('releaseCamera is called');
    try {
      await this.previewOutput?.release();
      await this.photoOutput?.release();
      await this.session?.release();
      await this.cameraInput?.close();
    } catch (error) {
      let err = error as BusinessError;
      console.error(`releaseCamera fail: error: ${err}`);
    } finally {
      this.previewOutput = undefined;
      this.photoOutput = undefined;
      this.cameraManager = undefined;
      this.session = undefined;
      this.cameraInput = undefined;
    }
    console.info('releaseCamera success');
  }
}