import { preferences } from "@kit.ArkData";
import { Context } from "@kit.AbilityKit";

const TAG : string = 'Setting';
/**
 * 对各类数据进行持久化存储/读取
 * 基本数据类型：字符串（String）、整数（Int）、浮点数（Float）、布尔值（Boolean）、长整型（Long）
 * 集合数据类型：字符串数组、复杂对象列表（JSON序列化）
 */
export abstract class Setting {
  private context : Context;
  private preferences : preferences.Preferences | null = null;  //存储简单键值对数据的核心类

  constructor(context: Context, key?: string) {
    this.context = context;  // 接受一个参数context，将传入的参数赋值给成员变量this.context
    if (key) {
      try {
        // 创建指定名称的Preferences
        // key是Preferences文件的名称，应用私有模式表示该文件只能被当前应用程序访问
        this.preferences = preferences.getPreferencesSync(context, { name: key });
      } catch (error) {
        console.error(`${TAG} constructor error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
        throw new Error(`${TAG} constructor error: ${error instanceof Error ? error.message : 'unknown error'}`);
      }
    } else {
      // 调用抽象的由子类实现的createPreferences(context) 方法来获取一个Preferences实例
      this.preferences = this.createPreferences(context);
      // 确保子类正确创建了preferences
      if (!this.preferences) {
        throw new Error(`${TAG} createPreferences must return a valid Preferences instance`);
      }
    }
  }

  // 抽象方法，具体实现由子类完成,这里定义了初始化流程
  protected abstract createPreferences(context: Context): preferences.Preferences;

  // 封装了对Preferences的直接操作，并添加了对基本的异常处理
  protected async getString(key: string, defValue: string | null): Promise<string> {
    if (!this.preferences) return defValue!;
    try {
      const value = await this.preferences.get(key, defValue);
      return value! as string;
    } catch (error) {
      console.error(`${TAG} getString error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
      return defValue!
    }
  }

  protected async getResourceColor(key: string, defValue: string | null) {
    if (!this.preferences) return defValue!;
    try {
      const value = await this.preferences.get(key, defValue);
      return value! as string;
    } catch (error) {
      console.error(`${TAG} getString error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
      return defValue!
    }
  }

  protected async setString(key: string, value: string | null): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(key, value);
      await this.preferences.flush();
    } catch (error) {
      console.error(`${TAG} setString error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
    }
  }

  protected async getInt(key: string, defValue: number): Promise<number> {
    if (!this.preferences) return defValue;
    try {
      const value = await this.preferences.get(key, defValue);
      return value as number;
    } catch (error) {
      console.error(`${TAG} getInt error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
      return defValue;
    }
  }
  protected getIntSync(key: string, defValue: number): number {
    if (!this.preferences) return defValue;
    try {
      const value = this.preferences.getSync(key, defValue);
      return value as number;
    } catch (error) {
      console.error(`${TAG} getInt error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
      return defValue;
    }
  }

  protected async setInt(key: string, value: number): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(key, value);
      await this.preferences.flush();
    } catch (error) {
      console.error(`${TAG} setInt error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
    }
  }

  protected async setResourceColor(key: string, value: ResourceColor): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(key, value);
      await this.preferences.flush();
    } catch (error) {
      console.error(`${TAG} setInt error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
    }
  }

  protected async getFloat(key: string, defValue: number): Promise<number> {
    if (!this.preferences) return defValue;
    try {
      const value = await this.preferences.get(key, defValue);
      return value as number;
    } catch (error) {
      console.error(`${TAG} getFloat error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
      return defValue;
    }
  }

  protected async setFloat(key: string, value: number): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(key, value);
      await this.preferences.flush();
    } catch (error) {
      console.error(`${TAG} setFloat error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
    }
  }

  protected async getBoolean(key: string, defValue: boolean): Promise<boolean> {
    if (!this.preferences) return defValue;
    try {
      const value = await this.preferences.get(key, defValue);
      return value as boolean;
    } catch (error) {
      console.error(`${TAG} getBoolean error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
      return defValue;
    }
  }
  protected getBooleanSync(key: string, defValue: boolean): boolean {
    if (!this.preferences) return defValue;
    try {
      const value = this.preferences.getSync(key, defValue);
      return value as boolean;
    } catch (error) {
      console.error(`${TAG} getBoolean error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
      return defValue;
    }
  }

  protected async setBoolean(key: string, value: boolean): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(key, value);
      await this.preferences.flush();
    } catch (error) {
      console.error(`${TAG} setBoolean error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
    }
  }

  protected async getLong(key: string, defValue: number): Promise<number> {
    if (!this.preferences) return defValue;
    try {
      const value = await this.preferences.get(key, defValue);
      return value as number;
    } catch (error) {
      console.error(`${TAG} getLong error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
      return defValue;
    }
  }

  protected async setLong(key: string, value: number): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(key, value);
      await this.preferences.flush();
    } catch (error) {
      console.error(`${TAG} setLong error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
    }
  }

  protected async getStringSet(key: string, defValue: Array<string> | null): Promise<Array<string>> {
    if (!this.preferences) return defValue!;
    try {
      const value = await this.preferences.get(key, defValue);
      return value! as Array<string>;
    } catch (error) {
      console.error(`${TAG} getStringSet error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
      return defValue!
    }
  }

  protected async setStringSet(key: string, value: Array<string>): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(key, value);
      await this.preferences.flush();
    } catch (error) {
      console.error(`${TAG} setStringSet error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
    }
  }

  // 复杂数据类型的读写
  protected async getList<T>(key: string): Promise<Array<T> | null> {
    if (!this.preferences) return null;
    try {
      const stringify = await this.preferences.get(key, '');
      if (stringify && typeof stringify === 'string' && stringify.length > 0) {
        const value = JSON.parse(stringify) as Array<T>;
        return value;
      }
      return null;
    } catch (error) {
      console.error(`${TAG} getList error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
      return null;
    }
  }

  protected async setList<T>(key: string, list: Array<T>): Promise<void> {
    if (!this.preferences) return;
    try {
      const stringify = JSON.stringify(list);
      await this.preferences.put(key, stringify);
      await this.preferences.flush();
    } catch (error) {
      console.error(`${TAG} setList error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
    }
  }

  //检查键是否存在
  protected async contains(key: string): Promise<boolean> {
    if (!this.preferences) return false;
    try {
      return await this.preferences.has(key);
    } catch (error) {
      console.error(`${TAG} contains error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
      return false;
    }
  }
  protected async existed(key: string): Promise<boolean> {
    return await this.contains(key);
  }

  //手动提交更改
  protected async commitChanges(): Promise<boolean> {
    if (!this.preferences) return false;
    try {
      await this.preferences.flush();
      return true;
    } catch (error) {
      console.error(`${TAG} commitChanges error: ${error instanceof Error ? error.message : JSON.stringify(error)}`);
      return false;
    }
  }
}
