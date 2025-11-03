import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import fs from '@ohos.file.fs';
import { http } from '@kit.NetworkKit';
import { BusinessError, emitter, systemDateTime } from '@kit.BasicServicesKit';
import { M8 } from '../main/ets/common/M8';
import { JSON, taskpool, uri } from '@kit.ArkTS';
import { EntryUtils } from '../main/ets/common/EntryUtils';
import { UserSetting } from '../main/ets/common/UserSetting';
import { i18n } from '@kit.LocalizationKit';
import ble from '@ohos.bluetooth.ble';
import { QTBle } from 'devices';
import { Event, EventManager, Level } from 'common';
import { AppEvent } from '../main/ets/common/event/AppEvent';
import { AppEventType } from '../main/ets/common/event/AppEventType';
import { common } from '@kit.AbilityKit';

export default function localUnitTest() {
  describe('localUnitTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    });
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    });
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    });
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    });

//https://baoshencode.gzbsit.com:10008
    it('assertContain', 0, async () => {


    });
  });


}

// async function getPublicDir(context: common.Context): Promise<string> {
//   try {
//     // 获取文件管理器能访问的目录
//     const dirs = context.filesDir; // 应用文件目录
//     // 或者使用外部存储目录
//     // const publicDir = await getExternalFilesDir('Documents');
//     return dirs;
//   } catch (error) {
//     console.error('获取公共目录失败:', error);
//     return '';
//   }
// }
//
// async function saveFileToPublicLocation(
//   context: common.Context,
//   sourceFilePath: string,
//   fileName: string
// ): Promise<boolean> {
//   try {
//     // 获取公共目录
//     const publicDir = await getPublicDir(context);
//     if (!publicDir) {
//       return false;
//     }
//
//     // 目标文件路径
//     const destPath = `${publicDir}/${fileName}`;
//
//     // 确保目录存在
//     await ensureDirectoryExists(publicDir);
//
//     // 复制文件到公共目录
//     const result = await copyFile(sourceFilePath, destPath);
//
//     if (result) {
//       console.log('文件保存成功:', destPath);
//       // 可以在这里触发媒体扫描，让文件立即出现在文件管理器中
//       await scanFile(context, destPath);
//       return true;
//     }
//     return false;
//   } catch (error) {
//     console.error('保存文件失败:', error);
//     return false;
//   }
// }
//
// // 确保目录存在
// async function ensureDirectoryExists(dirPath: string): Promise<void> {
//   try {
//     await fs.access(dirPath);
//   } catch (error) {
//     // 目录不存在，创建它
//     await fs.mkdir(dirPath, true);
//   }
// }
//
// // 复制文件
// async function copyFile(sourcePath: string, destPath: string): Promise<boolean> {
//   try {
//     const stat = await fs.stat(sourcePath);
//     if (!stat.isFile()) {
//       return false;
//     }
//
//     // 读取源文件
//     const sourceFile = await fs.open(sourcePath, fs.OpenMode.READ_ONLY);
//     const destFile = await fs.open(destPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
//
//     const buffer = new ArrayBuffer(1024 * 1024); // 1MB 缓冲区
//     let bytesRead = 0;
//
//     while ((bytesRead = await fs.read(sourceFile.fd, buffer)) > 0) {
//       await fs.write(destFile.fd, buffer, 0, bytesRead);
//     }
//
//     await fs.close(sourceFile.fd);
//     await fs.close(destFile.fd);
//
//     return true;
//   } catch (error) {
//     console.error('复制文件失败:', error);
//     return false;
//   }
// }