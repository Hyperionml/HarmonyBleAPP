import { common } from "@kit.AbilityKit";
import { camera } from "@kit.CameraKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { image } from "@kit.ImageKit";
import CameraConstant from "./constants/CameraConstants";

export class CameraUtils{

  private static TAG :string = 'CameraUtils';

  /**
   * 获取适当的相机(Id),todo 无法实现，鸿蒙无法获取最小对焦距离，未确定能否返回实际的相机，还是只会返回前置和后置相机，网上现在有这两种说法
   * */
  public static getAppropriateCameraId(context: common.BaseContext):string {
    return '';
  }

  /**
   * 获取适当的相机能力，给getMinFocalDistanceOfMM使用，用于提示用户，例如：识别距离约为2.5厘米/1英寸 todo 鸿蒙Api文档未找到获取最小对焦距离
   * */
  public static getAppropriateCamera(context: common.BaseContext){

  }

  /**
   * 获取相机能力
   * */
  public static getCamera(context: common.BaseContext,cameraId:string){

  }

  /**
   * 获取相机的最小对焦距离 todo 鸿蒙Api文档未找到获取最小对焦距离
   * */
  public static getCameraMinFocalDistanceOrHyperFocalDistanceOfMM(context: common.BaseContext,cameraId:string):number {
    let result:number = -1;
    return result
  }

  //public static getPreviewSize(List<Size> list, Size displaySize, int minSize,double multiple, boolean biggerIsBetter)


  //鸿蒙官方Api
  /**
   * 获取cameraManager对象
   * @param context
   * @returns
   * */
  private static getCameraManager(context: common.BaseContext): camera.CameraManager | undefined {
    let cameraManager: camera.CameraManager;
    try {
      cameraManager = camera.getCameraManager(context);
    } catch (error) {
      let err = error as BusinessError;
      console.error(`getCameraManager error, errCode: ${err.code}`);
      return undefined;
    }
    return cameraManager;
  }

  /**
   * 当前设备支持的相机列表
   * @param cameraManager
   * @returns
   * */
  private static getCameraDevices(cameraManager: camera.CameraManager): Array<camera.CameraDevice> {
    let cameraArray: Array<camera.CameraDevice> = cameraManager.getSupportedCameras();
    if (cameraArray != undefined && cameraArray.length > 0) {
      for (let index = 0; index < cameraArray.length; index++) {
        console.info('cameraId : ' + cameraArray[index].cameraId);  // 获取相机ID。
        console.info('cameraPosition : ' + cameraArray[index].cameraPosition);  // 获取相机位置。
        console.info('cameraType : ' + cameraArray[index].cameraType);  // 获取相机类型。
        console.info('connectionType : ' + cameraArray[index].connectionType);  // 获取相机连接类型。
      }
      return cameraArray;
    } else {
      console.error("cameraManager.getSupportedCameras error");
      return [];
    }
  }

  /**
   * ljj 在这里计算裁剪区域，考虑了是否前置需要翻转，屏幕角度是否需要旋转，得到Rect裁剪区域供CameraImage.getRgba对buffer进行裁剪
   * @param previewSize       相机预览采用的尺寸(预览帧)
   * @param surfaceSize       预览控件的尺寸（xCompetent）
   * @param cameraOrientation 相机的方向(通常后置似乎90，前置是270)
   * @param screenOrientation 布局方向
   * @param frame             预览控件裁减区域大小(如果不需要裁减,则frame的大小等于surfaceSize)
   * @return 返回相机预览裁减出来的对应的区域
   */
  public static crop(previewSize:Size, surfaceSize:Size, cameraOrientation:number, screenOrientation:number, frame:image.Region, isFront:boolean):image.Region {
    let rotatedImageWidth = 0, rotatedImageHeight = 0;
    // //0°是正常竖屏，90°是设备向左倾倒；270°是向右倾倒
    if (screenOrientation % 180 == 0) {
      rotatedImageWidth = previewSize.height;
      rotatedImageHeight = previewSize.width;
    } else {
      rotatedImageWidth = previewSize.width;
      rotatedImageHeight = previewSize.height;
    }
    //预览帧宽度：控件宽度比例
    let widthScale = rotatedImageWidth / surfaceSize.width;
    //预览帧高度：控件高度比例
    let heightScale = rotatedImageHeight / surfaceSize.height;

    // region ljj ArkTS不用Rect结构，没必要计算四个方位
    // 裁剪框的 左右上下 换算成 视频帧的 上下左右
    // 先采用屏幕的方向来计算
    // let left = Math.round(frame.x * widthScale);
    // let right = Math.round((frame.x+frame.size.width) * widthScale);
    // let top = Math.round(frame.y * heightScale);
    // let bottom = Math.round((frame.y+frame.size.height) * heightScale);
    // endregion

    // 直接计算最终的位置和尺寸
    let x = Math.round(frame.x * widthScale);
    let y = Math.round(frame.y * heightScale);
    let width = Math.round(frame.size.width * widthScale);
    let height = Math.round(frame.size.height * heightScale);
    let rect: image.Region = {
      x: x,
      y: y,
      size: { width: width, height: height }
    };

    //屏幕方向跟相机方向的相差角度
    //let orientation = CameraUtils.getCameraDisplayOrientation(cameraOrientation, screenOrientation, isFront);
    // region 安卓todo 跟上边的注释代码做下比较，也许是上方的正确
    // 根据旋转角度调整坐标
    // switch (orientation) {
    //   case 90:
    //     // 90度旋转：(x,y) -> (y, width-x)
    //     rect = {
    //       x: top,
    //       y: rotatedImageWidth - right,
    //       size: { width: height, height: width }
    //     };
    //     break;
    //
    //   case 180:
    //     // 180度旋转：(x,y) -> (width-x, height-y)
    //     rect = {
    //       x: rotatedImageWidth - right,
    //       y: rotatedImageHeight - bottom,
    //       size: { width: width, height: height }
    //     };
    //     break;
    //
    //   case 270:
    //     // 270度旋转：(x,y) -> (height-y, x)
    //     rect = {
    //       x: rotatedImageHeight - bottom,
    //       y: left,
    //       size: { width: height, height: width }
    //     };
    //     break;
    //
    //   default: // 0度
    //     rect = {
    //       x: left,
    //       y: top,
    //       size: { width: width, height: height }
    //     };
    //     break;
    // }
    // endregion
    // region 鸿蒙的逻辑，如果需要考虑旋转，再进行坐标变换
    // switch (orientation) {
    //   case 90:
    //     return {
    //       x: y,
    //       y: rotatedImageWidth - x - width,
    //       size: { width: height, height: width }
    //     };
    //   case 180:
    //     return {
    //       x: rotatedImageWidth - x - width,
    //       y: rotatedImageHeight - y - height,
    //       size: { width: width, height: height }
    //     };
    //   case 270:
    //     return {
    //       x: rotatedImageHeight - y - height,
    //       y: x,
    //       size: { width: height, height: width }
    //     };
    //   default: // 0度
    //     return rect;
    // }
    // endregion
    return rect;
  }

  //摄像头跟屏幕保持一致，需要用的角度
  public static getCameraDisplayOrientation(cameraOrientation:number, screenOrientation:number,  isFront:boolean):number {
    switch (screenOrientation) {
      case 0:
      screenOrientation = 90;
      break;
      case 90:
        screenOrientation = 0;
      break;
      case 180:
        screenOrientation = 270;
      break;
      case 270:
        screenOrientation = 180;
      break;
    }
    let orientation = 0;
    if (isFront) {
      orientation = (cameraOrientation + screenOrientation + 90) % 360;
    } else {
      // back-facing
      orientation = (cameraOrientation + screenOrientation + 270) % 360;
    }
    return orientation;
  }

  /** 获取最适合的输出流 */
  public static getBestCapability(profile:camera.Profile,capability:camera.CameraOutputCapability):camera.Profile {
    const displayRatio = profile.size.width / profile.size.height;
    const profileWidth = profile.size.width;
    // 先过滤出格式匹配的
    const candidates = capability.previewProfiles.filter(
      pf => pf.format === profile.format
    );
    if (candidates.length === 0) {
      throw new Error("No matching format capability");
    }
    //先按宽度与期望宽度 profileWidth 的绝对差值升序排序
    candidates.sort((a, b) => Math.abs(a.size.width - profileWidth) - Math.abs(b.size.width - profileWidth))

    // 逐步放宽比例误差
    let diff = CameraConstant.PROFILE_DIFFERENCE;//1e-10
    while (diff <= 0.01) {
      //找到 比例差值 小于 误差系数的
      const found = candidates.find(pf =>
      Math.abs(pf.size.width / pf.size.height - displayRatio) <= diff
      );
      if (found)
        return found;
      diff *= 10; // 放大误差系数
    }

    // 宽度最接近 + 比例误差 ≤ 0.1的第一个
    for (const pf of candidates) {
      const ratioDiff = Math.abs(pf.size.width / pf.size.height - displayRatio);
      if (ratioDiff <= 0.1)
        return pf;
    }

    //实在没有，只能返回 宽度/比例(启用下面的代码会返回比例最接近) 最接近的那个
    candidates.sort((a, b) =>
    Math.abs((a.size.width / a.size.height)-displayRatio) -
    Math.abs((b.size.width / b.size.height)-displayRatio)
    )
    return candidates[0]
  }

  /** ljj 是否会返回一个分辨率很差的结果? */
  public static getBestCapability2(profile: camera.Profile, capability: camera.CameraOutputCapability): camera.Profile {
    const displayRatio = profile.size.width / profile.size.height;
    const profileWidth = profile.size.width;

    // 先过滤格式
    const candidates = capability.previewProfiles.filter(
      pf => pf.format === profile.format
    );
    if (candidates.length === 0) {
      throw new Error("No matching format capability");
    }

    // 优先比例接近，其次宽度接近
    const sortByRatioAndWidth = (a: camera.Profile, b: camera.Profile) => {
      const ratioDiffA = Math.abs(a.size.width / a.size.height - displayRatio);
      const ratioDiffB = Math.abs(b.size.width / b.size.height - displayRatio);
      if (ratioDiffA !== ratioDiffB) return ratioDiffA - ratioDiffB;
      return Math.abs(a.size.width - profileWidth) - Math.abs(b.size.width - profileWidth);
    };

    // 按比例误差逐步放宽
    let diff = CameraConstant.PROFILE_DIFFERENCE; // 1e-10
    while (diff <= 0.01) {
      const filtered = candidates.filter(
        pf => Math.abs(pf.size.width / pf.size.height - displayRatio) <= diff
      );
      if (filtered.length > 0) {
        return filtered.sort(sortByRatioAndWidth)[0];
      }
      diff *= 10;
    }

    // 放宽到 0.1
    const filtered = candidates.filter(
      pf => Math.abs(pf.size.width / pf.size.height - displayRatio) <= 0.1
    );
    if (filtered.length > 0) {
      return filtered.sort(sortByRatioAndWidth)[0];
    }

    // 实在没有，随便给个宽度最接近的
    return candidates.sort(
      (a, b) => Math.abs(a.size.width - profileWidth) - Math.abs(b.size.width - profileWidth)
    )[0];
  }

  /** 迁移安卓的逻辑,todo 需要改变xCompent的大小使其超出屏幕，才能使画面不变形，目前未实现 */
  public static getPreviewSize(profile: camera.Profile, capability: camera.CameraOutputCapability, minSize: number,
    multiple: number, biggerIsBetter: boolean): camera.Profile {
    let avalidSizeList: camera.Profile[] = capability.previewProfiles;
    if (biggerIsBetter) {
      // 取最大分辨率
      let maxSize = avalidSizeList[0];
      for (const item of avalidSizeList) {
        if (item.size.width * item.size.height > maxSize.size.width * maxSize.size.height) {
          maxSize = item;
        }
      }
      const cameraAspet = Math.min(maxSize.size.width, maxSize.size.height) /
      Math.max(maxSize.size.width, maxSize.size.height);

      const filtered: camera.Profile[] = [];
      for (const item of avalidSizeList) {
        const curAspet = Math.min(item.size.width, item.size.height) /
        Math.max(item.size.width, item.size.height);
        if (Math.abs(curAspet - cameraAspet) < 0.03) {
          filtered.push(item);
        }
      }
      avalidSizeList = filtered;
    }
    const displayWidth = Math.min(profile.size.width, profile.size.height);
    const displayHeight = Math.max(profile.size.width, profile.size.height);
    // ljj 保持原始的宽高，不重新定义
    // const displayWidth = profile.size.width;
    // const displayHeight = profile.size.height;
    const aspect = displayHeight / displayWidth;

    if (multiple > 0 && (multiple < 0.9999 || multiple > 1.0001)) {
      minSize = Math.floor(minSize * multiple);
    }

    const fixWidth = Math.min(displayWidth, minSize);
    const bestWidth = Math.max(displayWidth, minSize);
    const bestHeight = Math.ceil(bestWidth * aspect);

    const weights: number[] = [];
    for (const item of avalidSizeList) {
      const width = Math.min(item.size.width, item.size.height);
      const height = Math.max(item.size.width, item.size.height);
      // // ljj 保持原始的宽高，不重新定义
      // const width = item.size.width
      // const height = item.size.width

      let weight = 0;
      if (width >= bestWidth) {
        weight = 1000000;
      } else if (width >= fixWidth) {
        weight = 10000;
      } else {
        weight = 100;
      }

      let sizeRate: number;
      if (biggerIsBetter) {
        sizeRate = height / bestHeight;
      } else {
        if (height > bestHeight) sizeRate = bestHeight / height;
        else sizeRate = height / bestHeight;
      }

      let aspectRate: number;
      const previewSizeAspect = height / width;
      if (previewSizeAspect > aspect) {
        aspectRate = 1;
      } else {
        aspectRate = previewSizeAspect / aspect;
      }

      console.info(`height * width = ${height}*${width}  weight=${weight} sizeRate=${sizeRate} aspectRate=${aspectRate} height/width=${height / width} total=${weight * sizeRate * aspectRate}`);

      weights.push(weight * sizeRate * aspectRate);
    }

    let index = 0;
    let maxWeight = weights[0];
    for (let i = 1; i < weights.length; i++) {
      if (weights[i] > maxWeight) {
        maxWeight = weights[i];
        index = i;
      }
    }

    const previewSize = avalidSizeList[index];
    console.info(`previewSize width*height=${previewSize.size.width}*${previewSize.size.height}  height/width=${previewSize.size.width / previewSize.size.height}`);
    console.info(`displaySize width*height=${profile.size.width}*${profile.size.height}  height/width=${profile.size.width / profile.size.height}`);

    return previewSize;
  }
}