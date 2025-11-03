import { BluetoothFileReceiverSetting } from "./BluetoothFileReceiverSetting";
import { common } from "@kit.AbilityKit";
import { Log, FileUtils } from "common";
import { process } from "@kit.ArkTS";
import { BusinessError } from "@kit.BasicServicesKit";
import { fileIo as fs } from '@kit.CoreFileKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { BuildConfig } from "../BuildConfig";
import { Utils as DUtils } from 'decoder';

const TAG = "BluetoothFileReceiver"
export class BluetoothFileReceiver {
  private setting : BluetoothFileReceiverSetting;
  private remotePath : string = "";
  private localPath : string = "";
  private fileType : string = "";
  private md5 : string = "";
  private totalLength : number = 0;
  private currentLength : number = 0;
  private fd : number | null = null;
  private isWaiting : boolean = false;
  private lastRequestTime: number = 0;
  private readonly REQUEST_TIMEOUT = 5000; // 5秒超时

  public static MaxRetryTime: number = 2;
  public static BlockLength: number = 102400;

  public constructor(setting:BluetoothFileReceiverSetting) {
    this.setting = setting;
  }

  //全新初始化（对应安卓带context的构造函数）
  public static async createFromContext(
    context: common.UIAbilityContext,
    remoteFile: string,
    fileType: string,
    md5: string,
    totalLength: number
  ): Promise<BluetoothFileReceiver> {
    const setting = BluetoothFileReceiverSetting.getInstance(context);
    const receiver = new BluetoothFileReceiver(setting);

    try {
      await setting.setRetryTime(0);
      await setting.setCreateTime(Date.now());
      receiver.setRemoteFile(remoteFile);

      // 根据BuildConfig.DEBUG判断环境
      let dir: string | null = null;
      if (BuildConfig.DEBUG) {
        dir = await FileUtils.getAppDirectory(context, FileUtils.AppFilesDir);
        Log.d(TAG, "开发环境用内部目录");
      } else {
        dir = await FileUtils.getAppExternalDirectory(context, FileUtils.AppFilesDir);
        Log.d(TAG, "生产环境用外部目录");
      }

      if (!dir) {
        throw new Error("获取目录失败");
      }

      const fileName = FileUtils.getFileNameWithoutPath(remoteFile);
      receiver.localPath = dir + "/" + fileName;

      console.log(`testtag receiver.localPath: ${receiver.localPath}`)
      await setting.setLocalPath(receiver.localPath);

      // 初始化currentLength为0
      receiver.currentLength = 0;
      await setting.setFileCurrentLength(0);

      receiver.totalLength = totalLength;
      receiver.md5 = md5;
      receiver.fileType = fileType;
      await setting.setFileTotalLength(totalLength);

      if (totalLength <= 0) {
        throw new Error("totalLength must be greater than 0");
      }

      receiver.initFile();

      // 检查文件描述符是否成功创建
      if (receiver.fd === null) {
        throw new Error("文件描述符创建失败");
      }
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      Log.e(TAG, error.message);
      receiver.closeFile();
      throw error;
    }

    return receiver;
  }

  //从配置恢复（对应安卓带setting的构造函数）
  public static async createFromSetting(setting: BluetoothFileReceiverSetting): Promise<BluetoothFileReceiver> {
    const receiver = new BluetoothFileReceiver(setting);
    try {
      // 明确获取 remotePath 并处理可能的 null 情况
      const remotePath = await setting.getRemotePath();
      if (remotePath === null || remotePath.trim() === "") {
        throw new Error("Assertion failed: remotePath is empty");
      }
      receiver.remotePath = remotePath;

      const retryTime = await setting.getRetryTime();
      if (retryTime >= BluetoothFileReceiver.MaxRetryTime) {
        throw new Error("Assertion failed: exceed max retry time");
      }
      await setting.setRetryTime(retryTime + 1);

      // 等待所有属性获取完成
      const localPath = await setting.getLocalPath();
      const totalLen = await setting.getFileTotalLength();
      const currentLen = await setting.getFileCurrentLength();
      const fileType = await setting.getFileType();
      const md5 = await setting.getFileMD5();

      receiver.localPath = localPath || "";
      receiver.totalLength = totalLen;

      // 从setting恢复currentLength
      receiver.currentLength = currentLen;
      if (receiver.currentLength < 0 || receiver.currentLength > receiver.totalLength) {
        Log.w(TAG, `恢复的currentLength异常: ${receiver.currentLength}, 重置为0`);
        receiver.currentLength = 0;
        await setting.setFileCurrentLength(0);
      }

      receiver.fileType = fileType || "";
      receiver.md5 = md5 || "";

      receiver.initFile();

      if (receiver.fd === null) {
        throw new Error("文件描述符创建失败");
      }
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      Log.e(TAG, error.message);
      receiver.closeFile();
      throw error;
    }
    return receiver;
  }

  // 接收文件数据
  public async receive(content: Uint8Array, begin: number, length: number): Promise<boolean> {
    let isOk = false;

    Log.d(TAG, `开始接收文件数据: begin=${begin}, length=${length}, content.length=${content.length}`);

    if (this.fd !== null) {
      console.log(TAG,`[receive] 准备写入文件`)
      Log.d(TAG, `调用FileUtils.write: fd=${this.fd}, begin=${begin}, content.length=${content.length}, offset=0, length=${length}`);
      const pureContent = new Uint8Array(content);
      isOk = FileUtils.write(this.fd, begin, pureContent, 0, length);

      if (isOk) {
        // 更新currentLength
        this.currentLength = begin + length;
        // 同步更新到setting
        await this.setting.setFileCurrentLength(this.currentLength);

        Log.d(TAG, `文件写入成功，更新当前长度为: ${this.currentLength}`);

        // 允许下一次获取起始位置
        this.isWaiting = false;
        console.log(TAG,`receive方法中重置isWaiting为false`);
        if (this.currentLength >= this.totalLength) {
          console.log(TAG,`文件传输完成: currentLength=${this.currentLength}, totalLength=${this.totalLength}`);
          this.closeFile();
        }
      } else {
        Log.e(TAG, `文件写入失败`);
        // 写入失败时也重置isWaiting标志，允许重试
        this.isWaiting = false;
        console.log(TAG,`receive方法中写入失败，重置isWaiting为false`);
      }
    } else {
      Log.e(TAG, "文件描述符无效，无法写入数据");
      // 文件描述符无效时也重置isWaiting标志
      this.isWaiting = false;
      console.log(TAG,`receive方法中文件描述符无效，重置isWaiting为false`);
      return false;
    }
    return isOk;
  }

  // 判断文件是否接收完成
  public isComplete(): boolean { return this.currentLength >= this.totalLength; }

  // checkMd5：文件完整后，检查MD5是否匹配
  public async checkMd5(): Promise<boolean> {
    if (!this.isComplete() || !this.localPath) {
      return false;
    }

    let isOk = false;
    try {
      const calculatedMd5 = DUtils.getMD5ofFile(this.localPath);
      if(calculatedMd5 === null){ return false; }
      isOk = calculatedMd5.toLowerCase() === this.md5.toLowerCase();

      if (isOk) {
        this.setting.setRemotePath("").catch((err: BusinessError) => {});
      } else {
        const deleteSuccess = await FileUtils.delete(this.localPath);
        if (deleteSuccess) {
          Log.e(TAG, "MD5 check failed, file deleted: " + this.localPath);
        }
      }
    } catch (ex) {
      Log.e(TAG, (ex as Error).message);
    }
    return isOk;
  }

  public getRemotePath(): string {return this.remotePath; }

  protected setLocalPath(localPath: string): void {
    this.localPath = localPath;
    this.setting.setLocalPath(localPath)
  }

  public getLocalPath(): string { return this.localPath; }

  protected setFileType(fileType: string): void {
    this.fileType = fileType;
    this.setting.setFileType(fileType)
  }

  public getFileType(): string { return this.fileType; }

  protected setMd5(md5: string): void {
    this.md5 = md5;
    this.setting.setFileMD5(md5)
  }

  public getMd5(): string { return this.md5; }

  protected setTotalLength(totalLength: number): void {
    this.totalLength = totalLength;
    this.setting.setFileTotalLength(totalLength)
  }

  public getTotalLength(): number { return this.totalLength; }

  public getCurrentLength(): number { return this.currentLength; }

  protected setCurrentLength(value: number): void {
    console.log(TAG,`currentLength: ${this.currentLength}, totalLength: ${this.totalLength}`)
    this.currentLength = value;
    this.setting.setFileCurrentLength(value)
  }

  private closeFile() {
    if (this.fd !== null) {
      FileUtils.closeFile(this.fd);
      this.fd = null;
    }
  }

  protected  setRemoteFile(remoteFile: string) : void{
    this.remotePath = remoteFile;
    this.setting.setRemotePath(remoteFile)
  }

  private initFile(): void {
    Log.d(TAG, `初始化文件，路径: ${this.localPath}, 长度: ${this.totalLength}`);
    this.fd = FileUtils.createFile(this.localPath, this.totalLength);
    Log.d(TAG, `FileUtils.createFile返回的文件描述符类型: ${typeof this.fd}`);
    if (this.fd === null) {
      Log.e(TAG, `初始化失败: 文件初始化失败：无法创建文件描述符（路径: ${this.localPath}）`);
    } else {
      Log.d(TAG, `文件初始化成功，文件描述符: ${this.fd}`);
    }
  }

  // 获取下一次接收起始位置
  public getBeginAndWait(): number {
    console.log(TAG,`getBeginAndWait调用: currentLength=${this.currentLength}, isComplete=${this.isComplete()}`);

    // 如果文件已完成，返回-1
    if (this.isComplete()) {
      console.log(TAG,`文件已完成，返回-1`);
      return -1;
    }

    this.isWaiting = true;
    console.log(TAG,`返回currentLength: ${this.currentLength}`);
    return this.currentLength;
  }

  // 获取进度
  public getProgress(): number {
    return this.totalLength > 0 ? (this.currentLength * 100.0) / this.totalLength : 0;
  }
}