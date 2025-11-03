/**
 * 测试代码
 * 无锁环形缓冲区（Lock-Free Ring Buffer）最简例子
 * buffer 是存所有帧的原始内存池(数据)，而 view 是这块内存池的访问窗口(指针),指针和数据分开两组SharedArrayBuffer和Uint8Array
 * 在多线程无锁缓冲区里，典型用法是：
 * 1.主线程分配一块 SharedArrayBuffer（一次分配固定大小）。
 * 2.每个线程都用 Uint8Array（或其他 TypedArray）创建视图访问这块共享内存。
 * 3.通过 Atomics 操作控制读写位置（防止线程覆盖未读数据）。
 * */
export interface SharedBuffers {
  data: SharedArrayBuffer;
  indexes: SharedArrayBuffer;
}
export class LockFreeRingBuffer{
  //环形缓冲区的长度
  private capacity: number;
  //单个数据长度
  private frameSize: number;

  // 数据区（帧内容）
  // 多个线程（Worker）之间共享的一块连续内存
  private buffer: SharedArrayBuffer;
  // 是 buffer 的一个“视图”，用来访问和读写 SharedArrayBuffer 中的内容（用 Uint8 存像素）
  private view: Uint8Array;

  // 指针区（控制信息）
  // 小块内存（存指针）
  private indexes: SharedArrayBuffer;
  // 视图，用 Int32 存指针（即writeIndex、readIndex）
  private indexView: Int32Array;

  /*
   * 按照处理视频帧作例子，capacity为最多保存多少帧，frameSize为每个数据的大小（每帧字节数）
   * 例如：
   * this.capacity = 8;           // 8 帧
   * this.frameSize = 1280 * 720 * 3; // YUV/RGB字节数
   * 或者
   * this.frameSize = 1280 * 720 * 4; //RGBA
   * */
  constructor(capacity: number, frameSize: number) {
    this.capacity = capacity;
    this.frameSize = frameSize;
    // 缓冲区容量 = 帧数 * 每帧字节数
    this.buffer = new SharedArrayBuffer(capacity * frameSize);
    this.view = new Uint8Array(this.buffer);

    // 指针缓冲区（2个 int32）
    // 一个 Int32 占 4 字节
    // 两个 Int32 就是 4 × 2 = 8 字节
    this.indexes = new SharedArrayBuffer(8);
    this.indexView = new Int32Array(this.indexes);
    this.indexView[0] = 0; // writeIndex
    this.indexView[1] = 0; // readIndex
  }

  write(frame: Uint8Array) {
    // 当前的写指针
    const writeIndex = Atomics.load(this.indexView, 0);
    // 计算下一个写入位置
    // (writeIndex + 1) 表示写指针向前走一步，即 如果 writeIndex 还没到末尾，就正常加一
    // % this.capacity 是取余运算，用来在环形缓冲区回绕，即 如果已经写到最后一个位置，再加一就会变成 0，回到缓冲区起点
    const nextIndex = (writeIndex + 1) % this.capacity;

    // 当前的读指针
    const readIndex = Atomics.load(this.indexView, 1);
    // 如果满了，覆盖最旧数据（也可以选择丢弃）
    // 即:如果 下一个要写的位置 等于 要读的位置 ，把 要读的位置 +1（读线程，你来不及读那一帧了，我直接覆盖它了。）
    if (nextIndex === readIndex) {
      Atomics.store(this.indexView, 1, (readIndex + 1) % this.capacity);
    }

    // 写入数据
    const frameSize = frame.length;
    const offset = writeIndex * frameSize;
    this.view.set(frame, offset);

    // 更新写指针
    Atomics.store(this.indexView, 0, nextIndex);
  }

  read(frameSize?: number): Uint8Array | null {
    frameSize ||= this.frameSize;
    // 当前的写指针
    const readIndex = Atomics.load(this.indexView, 1);
    // 当前的写指针
    const writeIndex = Atomics.load(this.indexView, 0);

    // 没有新数据被写入，或者写完之后全部都被读走了。即：缓冲区为空
    if (readIndex === writeIndex) {
      return null;
    }

    // 计算要读的位置
    const offset = readIndex * frameSize;
    // 创建要返回的Uint8Array
    const frame = new Uint8Array(frameSize);
    // 从view中读取数据写入frame中
    frame.set(this.view.subarray(offset, offset + frameSize));

    // 更新读指针
    Atomics.store(this.indexView, 1, (readIndex + 1) % this.capacity);
    return frame;
  }

  // 共享给 Worker
  getSharedBuffers() {
    return { data: this.buffer, indexes: this.indexes } as SharedBuffers;
  }
}