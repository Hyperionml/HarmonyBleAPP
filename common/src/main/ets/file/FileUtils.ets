/**
 * 如果在外部公共目录下操作文件，使用MediaStore接口 https://open.oppomobile.com/wiki/doc#id=10432
 */

import { Context } from '@kit.AbilityKit';
import { Log } from "../Log";
import { BusinessError } from "@kit.BasicServicesKit";
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';

// 定义lseek的模式常量
const SEEK_SET = 0;  // 从文件开头开始
const SEEK_CUR = 1;  // 从当前位置开始
const SEEK_END = 2;  // 从文件末尾开始

const TAG = 'FileUtil'
/**
 * 文件操作工具类
 */
export class FileUtils {
  public static listFiles(dir: string): string[] {
    try {
      // 1. 检查目录是否存在
      if (!FileUtils.isExist(dir)) {
        Log.e(TAG, `listFiles失败：目录不存在 ${dir}`);
        return [];
      }

      const stat = fs.statSync(dir);
      if (!stat.isDirectory()) {
        Log.e(TAG, `listFiles失败：${dir} 不是目录`);
        return [];
      }

      const files = fs.listFileSync(dir);

      return files.filter(fileName => typeof fileName === 'string');
    } catch (error) {
      Log.e(TAG, `listFiles异常：${(error as BusinessError).message}，目录：${dir}`);
      return [];
    }
  }

  //定义文件常量
  public static readonly ContentTypeImage = 'image/*';
  //华为应用安装包
  public static readonly ContentTypeHap = 'application/vnd.harmonyos.package-archive'; // 鸿蒙应用包
  public static readonly ContentTypePdf = 'application/pdf';
  public static readonly ContentTypeText = 'text/plain';
  public static readonly ContentTypeAudio = 'audio/*';
  public static readonly ContentTypeVideo = 'video/*';
  // 目录类型常量
  public static readonly AppFilesDir = 'files';
  public static readonly AppCacheDir = 'cache';

  /**
   * 获取应用专属缓存目录(优先采用external存储)
   *
   * @param context 上下文
   * @param type    文件夹类型 可以为空，为空则返回API得到的一级目录.可选(cache/files/...)
   * @return 缓存文件夹 如果没有SD卡或SD卡有问题则返回内存缓存目录，否则优先返回SD卡缓存目录
   */
  public static async getAppDirectory(context: common.UIAbilityContext, type: string): Promise<string | null> {
    let appDirUri: string | null = null;

    // 先获取外部存储目录
    appDirUri = await FileUtils.getAppExternalDirectory(context, type);
    // 如果外部存储获取失败，则获取内部存储目录
    if (appDirUri === null) {
      appDirUri = await FileUtils.getAppInternalDirectory(context, type);
    }

    if (appDirUri === null) {
      Log.e( TAG, "getAppDirectory fail, the reason is mobile phone unknown exception!");
      return null;
    }

    // 确保目录存在，如果不存在就创建
    try {
      fs.accessSync(appDirUri);
    } catch (error) {
      try {
        fs.mkdirSync(appDirUri, true);
      } catch (mkdirError) {
        Log.e( TAG, "getAppDirectory fail, the reason is make directory fail! URI: " + appDirUri);
        return null;
      }
    }
    return appDirUri;
  }

  /**
   * @deprecated 由于鸿蒙系统的安全性设计要求，无法直接获取外部存储的的地址，app只能操作沙箱内的文件
   * App 外部存储
   * @param context 上下文
   * @param type    为空时采用cache,可选参数:cache/files/...
   * @return 缓存目录文件夹 或 null（无SD卡或SD卡挂载失败）
   *
   */
  public static async getAppExternalDirectory(context: common.UIAbilityContext, type: string | null): Promise<string | null> {
    let appDirPath: string | null = null;

    try {
      // 检查外部存储状态
      let externalRootDir: string | null = null;
      // 先尝试公共外部目录
      if (type && type.toLowerCase() === FileUtils.AppFilesDir.toLowerCase()) {
        externalRootDir = context.filesDir; // 应用文件存储路径
      } else {
        externalRootDir = context.cacheDir;
      }

      // 2. 检查外部存储是否可用
      if (!externalRootDir) {
        Log.e(TAG, "External storage is unavailable (not mounted or no permission)");
        return null;
      }

      if (!type || type.toLowerCase() === FileUtils.AppCacheDir.toLowerCase()) {
        appDirPath = `${externalRootDir}/cache`;
      } else if (type.toLowerCase() === FileUtils.AppFilesDir.toLowerCase()) {
        appDirPath = externalRootDir;
      } else {
        appDirPath = `${externalRootDir}/${type}`;
      }

      try {
        fs.accessSync(appDirPath);
      } catch (error) {
        // 目录不存在创建
        try {
          fs.mkdirSync(appDirPath, true);
          Log.i(TAG, `Directory created successfully: ${appDirPath}`);
        } catch (mkdirErr) {
          Log.e(TAG, `Failed to create directory: ${(mkdirErr as BusinessError).message}, path: ${appDirPath}`);
          return null;
        }
      }

      const testFile = `${appDirPath}/.perm_test`;
      try {
        const fd = fs.openSync(testFile, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        fs.closeSync(fd);
        fs.unlinkSync(testFile);
        Log.i(TAG, `Directory permission verification passed: ${appDirPath}`);
      } catch (permErr) {
        Log.e(TAG, `Directory has no read/write permission:: ${(permErr as BusinessError).message}, 路径: ${appDirPath}`);
        return null;
      }

    } catch (ex) {
      Log.e(TAG, `getExternalDirectory fail: ${(ex as BusinessError).message}`);
      return null;
    }

    return appDirPath;
  }



  /**
   * @deprecated getExternalDirectory、不建议使用的没有迁移
   */

  /**
   * App内部私有目录
   *
   * @param type 子目录(cache/files)
   * @return 缓存目录文件夹 或 null（创建目录文件失败）
   * 注：该方法获取的目录是能供当前应用自己使用，外部应用没有读写权限，如 系统相机应用
   */
  public static async getAppInternalDirectory(context: common.UIAbilityContext, type: string = ''): Promise<string | null> {
    try {
      let internalRootDir: string;

      // 区分 cache/files 类型
      if (type.toLowerCase() === FileUtils.AppCacheDir.toLowerCase()) {
        internalRootDir = context.cacheDir; // 内部缓存目录
      } else if (type.toLowerCase() === FileUtils.AppFilesDir.toLowerCase()) {
        internalRootDir = context.filesDir; // 内部文件目录
      } else {
        internalRootDir = `${context.filesDir}/${type}`; // 自定义子目录
      }

      // 确保目录存在
      try {
        fs.accessSync(internalRootDir);
      } catch (error) {
        fs.mkdirSync(internalRootDir, true);
        Log.i(TAG, `Internal directory created successfully: ${internalRootDir}`);
      }
      return internalRootDir;

    } catch (error) {
      Log.e(TAG, `getAppInternalDirectory fail: ${(error as BusinessError).message}`);
      return null;
    }
  }

  /**
   * 文件操作：文件存在与删除、文件复制、文件重命名、文件写入
   */

  //判断文件是否存在
  public static isExist(filePath: string): boolean {
    try {
      fs.accessSync(filePath);
      return true;
    } catch (error) {
      return false;
    }
  }

  //删除文件
  public static delete(filePath: string): boolean {
    try {
      fs.unlinkSync(filePath);
      return true;
    } catch (error) {
      Log.e(TAG, `Delete file failed: ${(error as BusinessError).message}, path: ${filePath}`);
      return false;
    }
  }

  //文件复制
  public static copy(srcPath: string, dstPath: string): boolean {
    if (!FileUtils.isExist(srcPath)) {
      Log.e(TAG, `Source file not exist: ${srcPath}`);
      return false;
    }

    try {
      const srcStat = fs.statSync(srcPath);
      if (!srcStat.isFile()) {
        Log.e(TAG, `Source is not a file: ${srcPath}`);
        return false;
      }
    } catch (error) {
      Log.e(TAG, `Check source file failed: ${(error as BusinessError).message}`);
      return false;
    }

    const dstDir = dstPath.substring(0, dstPath.lastIndexOf('/'));
    if (!FileUtils.isExist(dstDir)) {
      try {
        fs.mkdirSync(dstDir, true);
      } catch (error) {
        Log.e(TAG, `Create destination directory failed: ${(error as BusinessError).message}`);
        return false;
      }
    }
    if (FileUtils.isExist(dstPath) && !FileUtils.delete(dstPath)) {
      Log.e(TAG, `Delete existing destination file failed: ${dstPath}`);
      return false;
    }

    let srcFd: number = -1;
    let dstFd: number = -1;
    try {
      const tempSrcFd = fs.openSync(srcPath, fs.OpenMode.READ_ONLY);
      const tempDstFd = fs.openSync(dstPath, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
      if (typeof tempSrcFd !== 'number' || typeof tempDstFd !== 'number') {
        throw new Error(`Invalid file descriptor type: ${typeof tempSrcFd}, ${typeof tempDstFd}`);
      }
      srcFd = tempSrcFd;
      dstFd = tempDstFd;

      const buffer = new ArrayBuffer(1024);
      let bytesRead: number;

      while ((bytesRead = fs.readSync(srcFd, buffer)) > 0) {
        fs.writeSync(dstFd, buffer, { offset: 0, length: bytesRead });
      }

      return true;
    } catch (error) {
      Log.e(TAG, `Copy file failed: ${(error as BusinessError).message}, src:${srcPath}, dst: ${dstPath}`);
      return false;
    } finally {
      if (srcFd !== -1) {
        try { fs.closeSync(srcFd); } catch (e) {}
      }
      if (dstFd !== -1) {
        try { fs.closeSync(dstFd); } catch (e) {}
      }
    }
  }

  //文件重命名:如果文件路径重复，则重命名为"文件(1).txt"之类的方式
  public static getRepeatName(filePath: string): string {
    if (!FileUtils.isExist(filePath)) {
      return filePath;
    }
    const extNameIndex = filePath.lastIndexOf('.');
    let extName = '';
    if (extNameIndex > 0) {
      extName = filePath.substring(extNameIndex);
    }
    const dirIndex = filePath.lastIndexOf('/');
    const dirPath = filePath.substring(0, dirIndex + 1);
    let fileName = filePath.substring(dirIndex + 1);
    if (extName.length > 0) {
      fileName = fileName.substring(0, fileName.length - extName.length);
    }
    let newPath: string;
    let count = 1;
    while (true) {
      newPath = `${dirPath}${fileName}(${count})${extName}`;
      if (!FileUtils.isExist(newPath)) {
        break;
      }
      count++;
    }
    return newPath;
  }

  //TODO 控制权限未迁移

  //TODO 浏览文件夹未迁移

  //TODO 打开指定格式文件

  //TODO 创建Uri指向文件

  //TODO 获取磁盘可用空间

  // 获取文件名 getFileNameWithoutPath
  public static getFileNameWithoutPath(path: string): string {
    // 用条件判断代替安卓的Assert.assertFalse(TextUtils.isEmpty(path))断言工具
    if (path === "" || path === undefined) {
      throw new Error("Path cannot be empty");
    }
    let index = path.lastIndexOf('/');
    if (index === -1) {
      index = path.lastIndexOf('\\');
    }
    if (index >= -1) {
      return path.substring(index + 1);
    }
    return path;
  }

  //TODO 获取文件扩展名

  //TODO 随机读取文件

  // 重载声明
  public static read(fd: number, skip: number, count: number): Uint8Array | null;
  public static read(filePath: string, skip: number, count: number): Uint8Array | null;
  public static read(fd: number, skip: number, buff: Uint8Array, offset: number, count: number): number;
  public static read(filePath: string, skip: number, buff: Uint8Array, offset: number, count: number): number;

  /**
   * 随机读取文件内容
   */
  public static read(arg1: number | string, skip: number, arg3: Uint8Array | number, offset?: number, count?: number): Uint8Array | null | number {
    // 从文件描述符读取指定数量的字节
    if (typeof arg1 === 'number' && typeof arg3 === 'number') {
      const fd = arg1;
      const byteCount = arg3;
      return FileUtils.readFromFd(fd, skip, byteCount);
    }

    // 从文件路径读取指定数量的字节
    else if (typeof arg1 === 'string' && typeof arg3 === 'number') {
      const filePath = arg1;
      const byteCount = arg3;
      return FileUtils.readFromFilePath(filePath, skip, byteCount);
    }

    // 从文件描述符读取到缓冲区
    else if (typeof arg1 === 'number' && arg3 instanceof Uint8Array && offset !== undefined && count !== undefined) {
      const fd = arg1;
      const buff = arg3;
      return FileUtils.readToBuffer(fd, skip, buff, offset, count);
    }

    // 从文件路径读取到缓冲区
    else if (typeof arg1 === 'string' && arg3 instanceof Uint8Array && offset !== undefined && count !== undefined) {
      const filePath = arg1;
      const buff = arg3;
      return FileUtils.readToBufferFromPath(filePath, skip, buff, offset, count);
    }

    Log.e(TAG, "Invalid parameters for read method");
    return -1;
  }

  /**
   * 从文件描述符读取指定数量的字节
   */
  private static readFromFd(fd: number, skip: number, count: number): Uint8Array | null {
    let buff = new Uint8Array(count);

    try {
      const readCount = FileUtils.readToBuffer(fd, skip, buff, 0, count);

      if (readCount > 0) {
        if (readCount < count) {
          // 如果实际读取的字节数小于请求的字节数，截断数组
          const temp = new Uint8Array(readCount);
          temp.set(buff.subarray(0, readCount));
          buff = temp;
        }
        return buff;
      } else {
        return null;
      }
    } catch (ex) {
      Log.e(TAG, `readFromFd failed: ${(ex as BusinessError).message}`);
      return null;
    }
  }

  /**
   * 从文件路径读取指定数量的字节
   */
  private static readFromFilePath(filePath: string, skip: number, count: number): Uint8Array | null {
    let fd: number | null = null;

    try {
      fd = FileUtils.openReadFile(filePath);
      if (fd !== null) {
        return FileUtils.read(fd, skip, count);
      } else {
        return null;
      }
    } catch (ex) {
      Log.e(TAG, `readFromFilePath failed: ${(ex as BusinessError).message}`);
      return null;
    } finally {
      if (fd !== null) {
        FileUtils.closeFile(fd);
      }
    }
  }

  /**
   * 从文件描述符读取数据到缓冲区
   */

  private static readToBuffer(fd: number, skip: number, buff: Uint8Array, offset: number, count: number): number {
    try {
      // 定位到指定位置
      fs.lseek(fd, skip, SEEK_SET);
      // 读取数据
      const bytesRead = fs.readSync(fd, buff, {
        offset: offset,
        length: Math.min(count, buff.length - offset)
      });

      return bytesRead;
    } catch (ex) {
      Log.e(TAG, `readToBuffer failed: ${(ex as BusinessError).message}`);
      return -1;
    }
  }


  /**
   * 从文件路径读取数据到缓冲区
   */
  private static readToBufferFromPath(filePath: string, skip: number, buff: Uint8Array, offset: number, count: number): number {
    let fd: number | null = null;

    try {
      fd = FileUtils.openReadFile(filePath);
      if (fd !== null) {
        return FileUtils.read(fd, skip, buff, offset, count);
      } else {
        return -1;
      }
    } catch (ex) {
      Log.e(TAG, `readToBufferFromPath failed: ${(ex as BusinessError).message}`);
      return -1;
    } finally {
      if (fd !== null) {
        FileUtils.closeFile(fd);
      }
    }
  }

  /**
   * 关闭文件
   */
  public static closeFile(fd: number): void {
    try {
      fs.closeSync(fd);
    } catch (ex) {
      Log.e(TAG, `closeFile failed: ${(ex as BusinessError).message}`);
    }
  }

  // 获取文件长度
  public static getFileLength(filePath: string): number {
    try {
      const stat = fs.statSync(filePath);
      return stat.size;
    } catch (error) {
      return 0;
    }
  }
  /**
   * 以只读模式打开文件，返回fd
   */
  public static openReadFile(filePath: string): number | null {
    if (!FileUtils.isExist(filePath)) {
      Log.e(TAG, `File not exists: ${filePath}`);
      return null;
    }

    try {
      //以只读模式打开文件
      const fd = fs.openSync(filePath, fs.OpenMode.READ_ONLY);

      // 验证文件描述符有效性
      if (typeof fd !== 'number') {
        Log.e(TAG, `Invalid file descriptor type: ${typeof fd}`);
        return null;
      }

      return fd;
    } catch (error) {
      // 处理异常
      const businessError = error as BusinessError;
      Log.e(TAG, `Failed to open file: ${businessError.message}, path: ${filePath}`);
      return null;
    }
  }

  //TODO 随机写入文件
  public static write(data: Uint8Array, filePath: string, canRename: boolean): string | null;
  public static write(fd: number, skip: number, buff: Uint8Array, offset: number, count: number): boolean;
  public static write(filePath: string, skip: number, buff: Uint8Array, offset: number, count: number): boolean;

  /**
   * 所有write方法的统一实现
   */
  public static write(
    arg1: Uint8Array | number | string,  // 第一个参数：数据/ fd / 文件路径
    arg2: string | number,               // 第二个参数：文件路径 / skip偏移量
    arg3: boolean | Uint8Array,          // 第三个参数：是否重命名 / 缓冲区
    arg4?: number,                       // 第四个参数：缓冲区偏移量
    arg5?: number                        // 第五个参数：写入字节数
  ): string | null | boolean {
    // 1：写入Uint8Array数据到文件
    if (arg1 instanceof Uint8Array && typeof arg2 === 'string' && typeof arg3 === 'boolean') {
      const data = arg1;
      let filePath = arg2;
      const canRename = arg3;

      if (FileUtils.isExist(filePath)) {
        if (canRename) {
          filePath = FileUtils.getRepeatName(filePath);
        } else {
          Log.e(TAG, `File already exists: ${filePath}`);
          return null;
        }
      }

      const dirPath = filePath.substring(0, filePath.lastIndexOf('/'));
      if (!FileUtils.isExist(dirPath)) {
        try {
          fs.mkdirSync(dirPath, true);
        } catch (error) {
          Log.e(TAG, `Failed to create directory: ${dirPath}, error: ${(error as BusinessError).message}`);
          return null;
        }
      }

      try {
        const fd = fs.openSync(filePath, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
        if (typeof fd !== 'number') {
          throw new Error(`Expected file descriptor (number), got ${typeof fd}`);
        }
        fs.writeSync(fd, data);
        fs.closeSync(fd);
        return filePath;
      } catch (error) {
        Log.e(TAG, `Write failed: ${filePath}, error: ${(error as BusinessError).message}`);
        return null;
      }
    }

    // 2：基于文件描述符（fd）的随机写入
    else if (typeof arg1 === 'number' && typeof arg2 === 'number' && arg3 instanceof Uint8Array && typeof arg4 === 'number' && typeof arg5 === 'number') {
      const fd = arg1;
      const skip = arg2;
      const buff = arg3;
      const offset = arg4;
      const count = arg5;

      try {
        Log.d(TAG, `准备写入文件: fd=${fd}, skip=${skip}, buff.length=${buff.length}, offset=${offset}, count=${count}`);
        // 检查参数有效性
        if (fd < 0) {  Log.e(TAG, `无效的文件描述符: ${fd}`);  return false; }
        if (skip < 0) {  Log.e(TAG, `无效的偏移量: ${skip}`);  return false;  }
        if (offset < 0 || offset >= buff.length) { Log.e(TAG, `无效的缓冲区偏移量: offset=${offset}, buff.length=${buff.length}`); return false; }
        if (count <= 0) { Log.e(TAG, `无效的写入长度: ${count}`); return false; }
        if (offset + count > buff.length) { Log.e(TAG, `写入范围超出缓冲区: offset=${offset}, count=${count}, buff.length=${buff.length}`); return false; }
        // 检查文件状态
          const stat = fs.statSync(fd);
          Log.d(TAG, `文件状态: size=${stat.size}, isFile=${stat.isFile()}`);

        // 定位到写入位置
        fs.lseek(fd, skip, SEEK_SET);
        // 写入缓冲区指定范围的数据
        const bytesToWrite = buff.subarray(offset, offset + count);
        Log.d(TAG, `实际写入字节数: ${bytesToWrite.length}`);
        
        // 转换为ArrayBuffer
        const arrayBuffer = bytesToWrite.buffer.slice(
          bytesToWrite.byteOffset,
          bytesToWrite.byteOffset + bytesToWrite.byteLength
        );
        fs.writeSync(fd, arrayBuffer);

        // 同步到磁盘
        fs.fsyncSync(fd);
        Log.d(TAG, `文件写入成功`);
        return true;
      } catch (error) {
        const businessError = error as BusinessError;
        Log.e(TAG, `write to fd failed: ${businessError.message}`);
        return false;
      }
    }

    // 3：基于文件路径的随机写入
    else if (typeof arg1 === 'string' && typeof arg2 === 'number' && arg3 instanceof Uint8Array && typeof arg4 === 'number' && typeof arg5 === 'number') {
      const filePath = arg1;
      const skip = arg2;
      const buff = arg3;
      const offset = arg4;
      const count = arg5;

      let fd: number | null = null;
      try {
        fd = FileUtils.createFile(filePath, -1);
        if (fd === null) {
          Log.e(TAG, `createFile failed for path: ${filePath}`);
          return false;
        }
        return FileUtils.write(fd, skip, buff, offset, count);
      } finally {
        if (fd !== null) {
          FileUtils.closeFile(fd);
        }
      }
    }

    // 无效参数处理
    else {
      Log.e(TAG, "Invalid parameters for write method");
      return false;
    }
  }

  /**
   * 创建可随机读写的文件，返回文件描述符fd
   * filePath 文件路径
   * fileLength:文件长度,-1表示不设置长度
   * @returns 文件描述符（number）或null（创建失败）
   */
  public static createFile(filePath: string, fileLength: number): number | null {
    try {
      Log.d(TAG, `开始创建文件: ${filePath}, 大小: ${fileLength}`);

      // 检查并创建父目录
      const dirPath = filePath.substring(0, filePath.lastIndexOf('/'));
      Log.d(TAG, `父目录路径: ${dirPath}`);

      if (!FileUtils.isExist(dirPath)) {
        Log.d(TAG, `目录不存在，尝试创建: ${dirPath}`);
        fs.mkdirSync(dirPath, true);
        Log.d(TAG, `目录创建成功`);
      } else {
        Log.d(TAG, `目录已存在`);
      }

      // 检查目录权限
      try {
        const testFile = `${dirPath}/.test_permission`;
        const testFd = fs.openSync(testFile, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
        fs.closeSync(testFd);
        fs.unlinkSync(testFile);
        Log.d(TAG, `目录写入权限验证成功`);
      } catch (permError) {
        Log.e(TAG, `目录无写入权限: ${(permError as Error).message}`);
        return null;
      }

      Log.d(TAG, `打开文件: ${filePath}`);
      const fd = fs.openSync(
        filePath,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE,
      );

      Log.d(TAG, `文件打开结果: fd = ${JSON.stringify(fd)}, 类型: ${typeof fd}`);

      let validFd: number | null = null;
      if (typeof fd === 'number' && fd >= 0) {
        validFd = fd;
        Log.d(TAG, `直接获取到数字文件描述符: ${validFd}`);
      } else if (typeof fd === 'object' && fd !== null) {
        try {
          // 访问fd属性，如果存在且为数字则使用
          const potentialFd = (fd as FdWrapper).fd;
          if (potentialFd !== undefined && typeof potentialFd === 'number' && potentialFd >= 0) {
            validFd = potentialFd;
            Log.d(TAG, `文件描述符: ${validFd}`);
          } else {
            Log.e(TAG, `没有有效的fd属性`);
            return null;
          }
        } catch (accessError) {
          Log.e(TAG, `访问fd失败: ${(accessError as Error).message}`);
          return null;
        }
      } else {
        Log.e(TAG, `文件描述符无效: 类型不正确`);
        return null;
      }

      // 设定文件长度
      if (fileLength > 0) {
        try {
          Log.d(TAG, `设置文件大小: ${fileLength}`);
          fs.truncateSync(validFd, fileLength);
          Log.d(TAG, `文件大小设置成功`);
        } catch (truncateError) {
          Log.e(TAG, `设置文件大小失败: ${(truncateError as Error).message}`);
          fs.closeSync(validFd);
          return null;
        }
      }

      Log.d(TAG, `文件创建成功: ${filePath}`);
      return validFd;

    } catch (error) {
      const businessError = error as BusinessError;
      Log.e(TAG, `createFile failed: ${businessError.message}, path: ${filePath}`);
      return null;
    }
  }

  public static getExtName(path: string): string | null {
    if(path === ''){
      throw new Error('path is empty')
    }

      let index = path.lastIndexOf(".");
      if(index < 0){
      return null;
    }
    return path.substring(index);
  }

  public static async getDownloadDir(): Promise<string | null> {
    try {
      const context = getContext() as common.UIAbilityContext;
      const filesDir = context.filesDir;
      if (!filesDir) {
        Log.e('FileUtils', 'filesDir is null');
        return null;
      }
      const downloadDir = `${filesDir}/download`;
      if (!FileUtils.isExist(downloadDir)) {
        fs.mkdirSync(downloadDir, true);
      }
      return downloadDir;
    } catch (ex) {
      Log.e('FileUtils', ex);
      return null;
    }
  }

  public static async readFileToPixelMap(filePath:string): Promise<PixelMap>{
    // 检查文件是否存在
    try {
      await fs.access(filePath);
    } catch (error) {
      console.error(`文件不存在: ${filePath}`);
    }
    // 获取文件信息
    const fileStat = await fs.stat(filePath);
    console.log(`文件大小: ${fileStat.size} 字节`);
    // 打开文件
    const file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
    // 创建缓冲区读取文件内容
    const buffer = new ArrayBuffer(fileStat.size);
    await fs.read(file.fd, buffer);

    const width = 400;
    const height = 400;
    let grayArray = new Uint8Array(buffer);
    // 关闭文件
    await fs.close(file.fd);
    let rgba = new Uint8Array(width * height * 4);
    for (let i = 0; i < grayArray.length; i++) {
      const v = grayArray[i];
      const offset = i * 4;
      rgba[offset] = v;       // R
      rgba[offset + 1] = v;   // G
      rgba[offset + 2] = v;   // B
      rgba[offset + 3] = 255; // A
    }
    const opts: image.InitializationOptions = {
      size: { width: width, height: height },
      pixelFormat: image.PixelMapFormat.RGBA_8888, // 常用格式
      editable: true,
    };
    return image.createPixelMapSync(rgba.buffer,opts);
  }
}
interface FdWrapper {
  fd?: number;
}
