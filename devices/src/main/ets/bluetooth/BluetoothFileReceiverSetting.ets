import { Setting } from 'common';
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
/**
 * 管理蓝牙文件接收器的设置和状态
 */

export class BluetoothFileReceiverSetting extends Setting {
  private static instance: BluetoothFileReceiverSetting | null = null;

  private static readonly KEY_REMOTE_PATH: string = "RemotePath";
  private static readonly KEY_LOCAL_PATH: string = "LocalPath";
  private static readonly KEY_FILE_TYPE: string = "FileType";
  private static readonly KEY_FILE_MD5: string = "FileMD5";
  private static readonly KEY_FILE_TOTAL_LENGTH: string = "FileTotalLength";
  private static readonly KEY_FILE_CURRENT_LENGTH: string = "FileCurrentLength";
  private static readonly KEY_RETRY_TIME: string = "RetryTime";
  private static readonly KEY_CREATE_TIME: string = "CreateTime";

  private constructor(context: common.Context) {
    super(context);
  }
  //创建全局唯一一个实例
  public static getInstance(context: common.Context): BluetoothFileReceiverSetting {
    if (!context) {
      throw new Error("Context cannot be null");
    }
    if (!BluetoothFileReceiverSetting.instance) {
      BluetoothFileReceiverSetting.instance = new BluetoothFileReceiverSetting(context);
    }
    return BluetoothFileReceiverSetting.instance;
  }

  protected createPreferences(context: common.Context): preferences.Preferences {
    return preferences.getPreferencesSync(context, { name: "receive" });
  }

  //路径管理方法：设置/获取远程/本地文件路径，记录文件来源和目的地
  async setRemotePath(value: string): Promise<boolean> {
    this.setString(BluetoothFileReceiverSetting.KEY_REMOTE_PATH, value);
    return await this.commitChanges();
  }
  async getRemotePath(): Promise<string | null> {
    return await this.getString(BluetoothFileReceiverSetting.KEY_REMOTE_PATH, "");
  }

  //设置/获取本地存储路今后
  async setLocalPath(value: string): Promise<boolean> {
    this.setString(BluetoothFileReceiverSetting.KEY_LOCAL_PATH, value);
    return await this.commitChanges();
  }
  async getLocalPath(): Promise<string | null> {
    return await this.getString(BluetoothFileReceiverSetting.KEY_LOCAL_PATH, " ");
  }

  //设置/获取文件类型/扩展名
  async setFileType(value: string): Promise<boolean> {
    this.setString(BluetoothFileReceiverSetting.KEY_FILE_TYPE, value);
    return await this.commitChanges();
  }
  async getFileType(): Promise<string | null> {
    return await this.getString(BluetoothFileReceiverSetting.KEY_FILE_TYPE, " ");
  }

  //文件信息方法：存储文件校验信息，记录文件类型
  async setFileMD5(value: string): Promise<boolean> {
    this.setString(BluetoothFileReceiverSetting.KEY_FILE_MD5, value);
    return await this.commitChanges();
  }
  async getFileMD5(): Promise<string | null> {
    return await this.getString(BluetoothFileReceiverSetting.KEY_FILE_MD5, " ");
  }

  //设置/获取文件总长度大小
  async setFileTotalLength(value: number): Promise<boolean> {
    this.setInt(BluetoothFileReceiverSetting.KEY_FILE_TOTAL_LENGTH, value);
    return await this.commitChanges();
  }
  async getFileTotalLength(): Promise<number> {
    return await this.getInt(BluetoothFileReceiverSetting.KEY_FILE_TOTAL_LENGTH, 0);
  }

  //传输状态方法：实时保存传输进度，支持断点续传
  async setFileCurrentLength(value: number): Promise<boolean> {
    this.setInt(BluetoothFileReceiverSetting.KEY_FILE_CURRENT_LENGTH, value);
    return await this.commitChanges();
  }
  async getFileCurrentLength(): Promise<number> {
    return await this.getInt(BluetoothFileReceiverSetting.KEY_FILE_CURRENT_LENGTH, 0);
  }

  //设置/获取重试时间：统计重试次数，实施重试机制
  async setRetryTime(value: number): Promise<boolean> {
    this.setInt(BluetoothFileReceiverSetting.KEY_RETRY_TIME, value);
    return await this.commitChanges();
  }
  async getRetryTime(): Promise<number> {
    return await this.getInt(BluetoothFileReceiverSetting.KEY_RETRY_TIME, 0);
  }

  //设置/获取创建文件开始时间
  async setCreateTime(value: number): Promise<boolean> {
    this.setLong(BluetoothFileReceiverSetting.KEY_CREATE_TIME, value);
    return await this.commitChanges();
  }
  async getCreateTime(): Promise<number> {
    return await this.getLong(BluetoothFileReceiverSetting.KEY_CREATE_TIME, 0);
  }
}