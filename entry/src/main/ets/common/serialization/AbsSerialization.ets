/**
 * 抽象序列化基类
 * 定义了序列化和反序列化的标准接口
 */
export abstract class AbsSerialization {
  /**
   * 将对象序列化为二进制数据
   * @param obj 要序列化的对象
   * @returns 序列化后的二进制数据
   */
  public abstract serialize<T>(obj: T): ArrayBuffer;

  /**
   * 将对象序列化为二进制数据（带类型参数）
   * @param obj 要序列化的对象
   * @param classOfT 目标类型名称
   * @returns 序列化后的二进制数据
   */
  public abstract serializeWithType<T1, T2>(obj: T1, classOfT: string): ArrayBuffer;

  /**
   * 从输入流反序列化对象
   * @param stream 输入流（ArrayBuffer）
   * @param classOfT 目标类型名称
   * @returns 反序列化后的对象
   */
  public abstract deserialize<T>(stream: ArrayBuffer, classOfT: string): T;

  /**
   * 从二进制数据反序列化对象
   * @param data 二进制数据
   * @param classOfT 目标类型名称
   * @returns 反序列化后的对象
   */
  public abstract deserializeFromData<T>(data: ArrayBuffer, classOfT: string): T;

  /**
   * 从输入流反序列化对象（返回指定结果类型）
   * @param stream 输入流（ArrayBuffer）
   * @param classOfT 源类型名称
   * @param resultClass 结果类型名称
   * @returns 反序列化后的结果对象
   */
  public abstract deserializeToResult<T, TResult>(stream: ArrayBuffer, classOfT: string, resultClass: string): TResult;
}