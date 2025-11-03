//AbsCameraImage（原安卓代码）不再需要，AbsCameraReader(当前文件)已经实现了相同的缓冲功能，裁剪实际使用的是CameraUtils.crop，鸿蒙裁剪有更高效的系统方法(如pixelMap.crop)，不一定要自己实现
//AbsCameraImage配合AbsCameraReader使用，AbsCameraReader管理多个AbsCameraImage对象
//每个AbsCameraImage相当于环形缓冲区的一个"槽位"
//生产者写入数据到 AbsCameraImage，消费者从中读取并解码
import { image } from "@kit.ImageKit"
import { Logger } from "common"
const TAG = 'AbsCameraReader'
//状态
export enum SlotState { None = 0, Writing = 1, Written = 2, Reading = 3 }
const OFF_HEAD = 0,   //读指针（下一次可读的槽位索引）
  OFF_TAIL = 1,       //写指针（下一次可写的槽位索引）
  OFF_CAP = 2,        //容量（槽位个数，通常为 maxImageCount+1）
  OFF_SLOT_BYTES = 3, //每个槽位的有效载荷字节数（单帧大小）
  OFF_COUNT = 4       //元信息区元素个数（上面4个字段的计数，用来 new Int32Array(sab, 0, OFF_COUNT) 和计算头部字节数）
/**
 * 槽位区槽头的由两个 32 位整数构成
 * 第1个 Int32：该槽位的状态 state（None/Writing/Written/Reading）
 * 第2个 Int32：该槽位本次有效数据长度 dataLen（字节数）
 */
const SLOT_HDR_I32 = 2
/**
 * 元信息头部所占字节数（HEAD/TAIL/CAP/SLOT_BYTES）* 4
 * */
function metaBytes(){ return OFF_COUNT * 4 }
/**
 * 槽位区槽头长度（state|dataLen 是2个 Int32，需要跳过 2 × 4 = 8byte，即1个int32占用4个byte,2个占用8个byte）
 * */
function slotHdrBytes(){ return SLOT_HDR_I32 * 4 }
/**
 * 第 idx 个槽位在整块 SharedArrayBuffer 中的起始位置
 * */
function slotOffset(meta: Int32Array, idx: number){
  const cap = meta[OFF_CAP], slotBytes = meta[OFF_SLOT_BYTES]
  return metaBytes() + idx * (slotHdrBytes() + slotBytes)
}
export interface WriteHandle {
  buffer: Uint8Array;
  commit: (bytes?: number) => void;
  cancel: () => void;
}
/**
 * SharedArrayBuffer完整布局如下：
 * 元信息区（Int32Array，固定4个int32）
 * - OFF_HEAD: 读指针
 * - OFF_TAIL: 写指针
 * - OFF_CAP: 槽位总数
 * - OFF_SLOT_BYTES: 每槽位负载字节数（单帧大小，固定）
 * 槽位区（重复 cap 次）
 * - 槽头（Int32Array，SLOT_HDR_I32=2 个int32）
 * - - state: 槽位状态（None/Writing/Written/Reading）
 * - - dataLen: 本次有效负载长度（字节，<= SLOT_BYTES）
 * - 负载区（数据区，Uint8Array，长度= SLOT_BYTES）
 * - - 实际帧数据（大小不超过 SLOT_BYTES；写完后用 dataLen 标注）
 * 示例：
 * [ Meta: HEAD | TAIL | CAP | SLOT_BYTES ]
 * [ Slot0: state | dataLen | payload(bytes... SLOT_BYTES) ]
 * [ Slot1: state | dataLen | payload(bytes... SLOT_BYTES) ]
 * ...
 * [ Slot(cap-1): state | dataLen | payload(bytes... SLOT_BYTES) ]
 * */
export class AbsCameraReader {
  // 共享内存
  private sab: SharedArrayBuffer; private meta: Int32Array
  private mImageWidth :number;
  private mImageHeight :number;
  private mImageFormat : image.PixelMapFormat;
  private mMaxCount :number;
  private mCameraOrientation :number;
  private mIsFront :boolean;

  private changed: boolean= false;
  public consumeChanged(): boolean {
    const v = this.changed;
    this.changed = false;
    return v;
  }

  //单例模式
  private static _instance: AbsCameraReader | null = null;
  private _cfgKey: string;
  private static makeKey(w:number,h:number,fmt:image.PixelMapFormat,max:number,ori:number,front:boolean){
    return `${w}x${h}-${fmt}-${max}-${ori}-${front}`;
  }
  public static getInstance(imageWidth:number,imageHeight:number,format:image.PixelMapFormat,maxImageCount:number,cameraOrientation:number,isFront:boolean, reuse:boolean=true):AbsCameraReader{
    //单例key
    const key = AbsCameraReader.makeKey(imageWidth,imageHeight,format,maxImageCount,cameraOrientation,isFront);
    //强制刷新，或者单例为空，或者参数改变
    if (!reuse || AbsCameraReader._instance === null || AbsCameraReader._instance._cfgKey !== key) {
      AbsCameraReader._instance = new AbsCameraReader(imageWidth,imageHeight,format,maxImageCount,cameraOrientation,isFront);
      AbsCameraReader._instance.changed = true;
    }else{
      AbsCameraReader._instance.changed = false;
    }
    return AbsCameraReader._instance;
  }
  public static destroyInstance(){
    AbsCameraReader._instance = null;
  }
  static instance():AbsCameraReader | null { return AbsCameraReader._instance }

  constructor( imageWidth:number,  imageHeight:number,  format:image.PixelMapFormat,  maxImageCount:number,
    cameraOrientation:number,  isFront:boolean) {
    if (!(maxImageCount > 0)) { throw new Error('最大可用数必须大于0') as Error }
    this.mImageWidth = imageWidth;
    this.mImageHeight = imageHeight;
    this.mImageFormat = format;
    this.mMaxCount = maxImageCount;
    this.mCameraOrientation = cameraOrientation;
    this.mIsFront = isFront;

    //帧数据长度
    const slotBytes = this.bytesPerFrame(imageWidth,imageHeight,format)
    const cap = maxImageCount + 1
    //分配SharedArrayBuffer空间
    this.sab = new SharedArrayBuffer(metaBytes() + cap * (slotHdrBytes() + slotBytes))

    //设置元信息区
    this.meta = new Int32Array(this.sab, 0, OFF_COUNT)
    this.meta[OFF_HEAD]=0;              //读指针初始为 0
    this.meta[OFF_TAIL]=0;              //写指针初始为 0
    this.meta[OFF_CAP]=cap;             //槽位数量
    this.meta[OFF_SLOT_BYTES]=slotBytes //每槽位载荷大小（每帧字节数）

    //单例key
    this._cfgKey = AbsCameraReader.makeKey(imageWidth,imageHeight,format,maxImageCount,cameraOrientation,isFront);
  }
  // 提供给 Worker 初始化共享（初始化时调用，一次性传递）
  public exportSharedBuffer(){
    return this.sab
  }

  public getWidth(){ return this.mImageWidth }
  public getHeight(){ return this.mImageHeight }
  public getCapacity(){ return this.mMaxCount + 1 }
  public getImageFormat(){ return this.mImageFormat }
  public getCameraOrientation(){ return this.mCameraOrientation }
  public isFront(){ return this.isFront }

  // 获取一个可写槽位；返回写视图与提交/取消接口
  acquireImageForWrite(): WriteHandle | undefined {
    const cap = this.meta[OFF_CAP]              //槽位数量
    const slotBytes = this.meta[OFF_SLOT_BYTES] //每帧字节数
    let tail = Atomics.load(this.meta, OFF_TAIL)//写指针
    let head = Atomics.load(this.meta, OFF_HEAD)//读指针

    // 满则丢最旧（前移 head），保证实时性
    if (((tail + 1) % cap) === head) {
      Atomics.store(this.meta, OFF_HEAD, (head + 1) % cap)
      //head = Atomics.load(this.meta, OFF_HEAD)
    }
    //写指针
    const idx = tail
    //计算当前index槽位的起始位置
    const off = slotOffset(this.meta, idx)
    //创建槽位区槽头Int32Array
    const hdr = new Int32Array(this.sab, off, SLOT_HDR_I32)
    //槽头状态位设置为 Writing
    Atomics.store(hdr,0,SlotState.Writing);
    //槽头长度位设置为 0
    Atomics.store(hdr,1,0)

    Logger.warn (TAG, `acquireImageForWrite(),当前写指针tail:${tail}`);

    //创建数据区Uint8Array（字节偏移用off + slotHdrBytes()，slotHdrBytes是两个int32的字节数）
    const payload = new Uint8Array(this.sab, off + slotHdrBytes(), slotBytes)
    let done = false
    const commit = (bytes?:number) => {
      //防重复提交
      if (done) return
      //计算本次有效长度 len：优先用入参 bytes，否则默认整槽大小；用 Math.min 防止越界。
      const len = bytes && bytes>0 ? Math.min(bytes, payload.byteLength) : payload.byteLength
      //把有效字节数写入槽头的 dataLen
      Atomics.store(hdr,1,len);
      //把槽位状态置为 Written，发布“可读”
      Atomics.store(hdr,0,SlotState.Written)
      //更新写指针
      Atomics.store(this.meta, OFF_TAIL, (idx + 1) % cap);
      //标记已提交，后续再调不会重复执行
      done = true
    }
    const cancel = () => { if (!done) Atomics.store(hdr,0,SlotState.None) }

    const handle: WriteHandle = { buffer: payload, commit, cancel };
    return handle;
  }

  // 读数据
  acquireImageForRead(): WriteHandle | undefined{
    if (!this.sab) return undefined
    //读取元信息区
    const meta = new Int32Array(this.sab, 0, OFF_COUNT)
    //槽位数量
    const cap = meta[OFF_CAP]
    //单帧字节数
    const slotBytes = meta[OFF_SLOT_BYTES]
    //读指针
    const head = Atomics.load(meta, OFF_HEAD)
    //写指针
    const tail = Atomics.load(meta, OFF_TAIL)
    //空，无数据或者已读完
    if (head === tail) return undefined
    //读取最新：定位到 写指针 的前一个slot（+cap %cap 是为了循环）
    const latest = (tail - 1 + cap) % cap
    //计算当前index槽位的起始位置
    const off = slotOffset(meta, latest)
    //创建槽头Int32Array（把那块内存“解释”成 2 个 32 位整数，写过就会有值）
    const hdr = new Int32Array(this.sab, off, SLOT_HDR_I32)
    //compareExchange
    //只有当 hdr[0] 当前值等于 SlotState.Written 时，才把它改成 SlotState.Reading，并返回原来的值；否则什么都不改，也返回原来的值。
    //即：只读Written的数据，且把Written改成Reading，否者返回undefined
    if (Atomics.compareExchange(hdr, 0, SlotState.Written, SlotState.Reading) !== SlotState.Written) return undefined
    //读取单帧字节长度
    const len = Math.min(Atomics.load(hdr,1), slotBytes)
    //读取数据区Uint8Array（字节偏移用off + slotHdrBytes()，slotHdrBytes是两个int32的字节数）
    const view = new Uint8Array(this.sab, off + slotHdrBytes(), len)

    Logger.info (TAG, `acquireImageForRead(),当前读指针latest:${latest}`);

    let done = false
    const commit = (bytes?:number) => {
      //防重复提交
      if (done) return
      //读完后状态设置成None
      Atomics.store(hdr,0,SlotState.None)
      //更新读指针到下一位
      Atomics.store(meta, OFF_HEAD, (latest + 1) % cap)
      //标记已提交，后续再调不会重复执行
      done = true
    }
    const cancel = () => { if (!done) Atomics.store(hdr,0,SlotState.Written) }
    const handle: WriteHandle = { buffer: view, commit, cancel };
    return handle;
  }

  // 读数据，停供给Worker使用的静态方法
  static readLatestForWorker(sab: SharedArrayBuffer| undefined): WriteHandle | undefined {
    if (!sab) return undefined
    //读取元信息区
    const meta = new Int32Array(sab, 0, OFF_COUNT)
    //槽位数量
    const cap = meta[OFF_CAP]
    //单帧字节数
    const slotBytes = meta[OFF_SLOT_BYTES]
    //读指针
    const head = Atomics.load(meta, OFF_HEAD)
    //写指针
    const tail = Atomics.load(meta, OFF_TAIL)
    //空，无数据或者已读完
    if (head === tail) {
      //Logger.warn (TAG, `readLatestForWorker(),无数据或者已读完`);
      return undefined
    }
    //读取最新：定位到 写指针 的前一个slot（+cap %cap 是为了循环）
    const latest = (tail - 1 + cap) % cap
    //计算当前index槽位的起始位置
    const off = slotOffset(meta, latest)
    //创建槽头Int32Array（把那块内存“解释”成 2 个 32 位整数，写过就会有值）
    const hdr = new Int32Array(sab, off, SLOT_HDR_I32)
    //compareExchange
    //只有当 hdr[0] 当前值等于 SlotState.Written 时，才把它改成 SlotState.Reading，并返回原来的值；否则什么都不改，也返回原来的值。
    //即：只读Written的数据，且把Written改成Reading，否者返回undefined
    if (Atomics.compareExchange(hdr, 0, SlotState.Written, SlotState.Reading) !== SlotState.Written) {
      Logger.warn (TAG, `已返回undefined（只读Written的数据，且把Written改成Reading，否者返回undefined）`);
      return undefined
    }
    //读取单帧字节长度
    const len = Math.min(Atomics.load(hdr,1), slotBytes)
    //读取数据区Uint8Array（字节偏移用off + slotHdrBytes()，slotHdrBytes是两个int32的字节数）
    const view = new Uint8Array(sab, off + slotHdrBytes(), len)

    Logger.info (TAG, `readLatestForWorker(),当前读指针latest:${latest}`);

    let done = false
    const commit = (bytes?:number) => {
      //防重复提交
      if (done) return
      //读完后状态设置成None
      Atomics.store(hdr,0,SlotState.None)
      //更新读指针到下一位
      Atomics.store(meta, OFF_HEAD, (latest + 1) % cap)
      //标记已提交，后续再调不会重复执行
      done = true
    }
    const cancel = () => { if (!done) Atomics.store(hdr,0,SlotState.Written) }
    const handle: WriteHandle = { buffer: view, commit, cancel };
    return handle;

    // //读完后状态设置成None
    // Atomics.store(hdr,0,SlotState.None)
    // //更新读指针到下一位
    // Atomics.store(meta, OFF_HEAD, (latest + 1) % cap)
    // Logger.warn (TAG, `readLatestForWorker(),当前读指针latest:${latest}`);
    // return view
  }

  // 清空槽位数据，防止下次解码时读到旧数据
  clearAllSlots(): void {
    if (!this.sab || !this.meta) return;

    const cap = this.meta[OFF_CAP];
    Logger.warn(TAG, `clearAllSlots() 开始清空所有槽位，总数: ${cap}`);

    // 重置读写指针
    Atomics.store(this.meta, OFF_HEAD, 0);
    Atomics.store(this.meta, OFF_TAIL, 0);

    // 清空所有槽位状态
    for (let i = 0; i < cap; i++) {
      const off = slotOffset(this.meta, i);
      const hdr = new Int32Array(this.sab, off, SLOT_HDR_I32);
      // 将状态设为None，数据长度设为0
      Atomics.store(hdr, 0, SlotState.None);
      Atomics.store(hdr, 1, 0);
    }

    Logger.warn(TAG, `clearAllSlots() 完成，所有槽位已重置`);
  }

  // 清空槽位数据，防止下次解码时读到旧数据，提供给Worker使用的静态清空方法
  static clearAllSlotsForWorker(sab: SharedArrayBuffer | undefined): void {
    if (!sab) return;

    const meta = new Int32Array(sab, 0, OFF_COUNT);
    const cap = meta[OFF_CAP];

    // 重置读写指针
    Atomics.store(meta, OFF_HEAD, 0);
    Atomics.store(meta, OFF_TAIL, 0);

    // 清空所有槽位状态
    for (let i = 0; i < cap; i++) {
      const off = slotOffset(meta, i);
      const hdr = new Int32Array(sab, off, SLOT_HDR_I32);
      // 将状态设为None，数据长度设为0
      Atomics.store(hdr, 0, SlotState.None);
      Atomics.store(hdr, 1, 0);
    }

    Logger.warn(TAG, `clearAllSlotsForWorker() 完成，所有槽位已重置`);
  }

  private bytesPerFrame(w:number,h:number,fmt:image.PixelMapFormat){
    if (fmt===image.PixelMapFormat.NV21 ||
      fmt===image.PixelMapFormat.RGB_565||
      fmt===image.PixelMapFormat.RGB_888||
      fmt===image.PixelMapFormat.NV12)
      return (w*h*3)>>1;//*3/2
    return w*h*4
  }
}