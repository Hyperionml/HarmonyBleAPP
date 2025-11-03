
export class ValueUtils{
  public static max(array: number[]): number;
  public static max(list: number[][]): number;
  public static max(input: number[]  | number[][]): number {
    if(!input || input.length === 0){
      throw new Error("数据必须有成员");
    }
    const targetArray: number[] = Array.isArray(input[0]) ? (input as number[][]).flat() : (input as number[]);
    let max = targetArray[0];
    for (const item of targetArray) {
      if(item > max) max = item;
    }
    return max;
  }

  public static sort(list: number[]): void{
    list.sort((d1,d2) => d1 - d2);
  }

  public static toList<T>(...array:T[]): T[];
  public static toList<T>(array:number[]): number[];
  public static toList<T>(...input:T[] | [T[]]): T[] {
    const list: T[] = [];
    if(input.length === 1 && Array.isArray(input[0])){
      (input[0] as T[]).forEach(item => list.push(item));
    }else {
      (input as T[]).forEach(item => list.push(item));
    }
    return list;
  }

  public static paged<T>(list: T[], skip: number, count: number): T[] {
    if(skip < 1) throw new Error("参数skip取值范围大于0");
    if(!list || list.length < skip + count) throw new Error("skip过长");

    const newList: T[] = [];
    for (let i = skip; i < skip + count; i++) {
      newList.push(list[i]);
    }
    return newList;
  }

  public static toArray<T>(list: T[]): T[] {
    const array: T[] = new Array(list.length);
    list.forEach((item,i) => array[i] = item);
    return array;
  }

  public static sum(array: number[]): number;
  public static sum(input: number[]): number {
    let total = 0;
    input.forEach(item => total += item);
    return total;
  }

     public static ChangeDigitRate(
             src: Uint8Array,
             dstDigit: number,
             srcDigit: number
     ): Uint8Array {
         if (srcDigit <= 0 || srcDigit >= 9) throw new Error("srcDigit取值范围不正确");
         if (dstDigit <= 0 || dstDigit >= 9) throw new Error("dstDigit取值范围不正确");

     const intsLength = Math.ceil((src.length * srcDigit) / dstDigit);
     const ints: number[] = new Array(intsLength).fill(0);

         let srcIndex = 0, srcRemainBits = srcDigit;
         let dstRemainBits = dstDigit, dstIndex = 0;

         while (srcIndex < src.length) {
             if (srcRemainBits > 0) {
         const dstItem = ints[dstIndex];
         const srcItem = src[srcIndex] & 0xff;
         const readBits = srcRemainBits > dstRemainBits ? dstRemainBits : srcRemainBits;

                 let newDstItem = dstItem << readBits;
                 newDstItem |= (((srcItem >>> (srcRemainBits - readBits))
                         << (32 - readBits)) >>> (32 - readBits));

                 srcRemainBits -= readBits;
                 dstRemainBits -= readBits;
                 ints[dstIndex] = newDstItem;

                 if (dstRemainBits === 0) {
                     dstIndex++;
                     dstRemainBits = dstDigit;
                 }
             } else {
                 srcIndex++;
                 srcRemainBits = srcDigit;
             }
         }

     const dst = new Uint8Array(ints.length);
         ints.forEach((item, i) => dst[i] = item & 0xff);

     const mol = (src.length * srcDigit) % dstDigit;
         if (mol !== 0 && dst.length > 0) {
             dst[dst.length - 1] <<= (dstDigit - mol);
             dst[dst.length - 1] &= 0xff;
         }

         return dst;
     }

  public static getLength(planar: number[][], dimension: number): number;
  public static getLength(planar: boolean[][], dimension: number): number;
  public static getLength(planar: number[][] | boolean[][], dimension: number): number {
    if (dimension === 0) {
      return Array.isArray(planar[0]) && typeof planar[0][0] === 'number'
        ? (planar as number[][]).length
        : (planar as boolean[][]).length;
    }
    if (dimension === 1) {
      const firstRow = planar[0];
      return firstRow ? firstRow.length : 0;
    }
    throw new Error("不支持的维度");
  }

     public static createPlanar(rows: number,cols:number): number[][] {
       const planar: number[][] = new Array(rows);
       for (let i = 0;i < rows; i++) {
         planar[i] = new Array(cols);
       }
       return planar;
     }

     public static createPlanarOfBoolean(rows:number, cols:number): boolean[][] {
       const planar: boolean[][] = new Array(rows);
       for (let i = 0;i < rows; i++) {
         planar[i] = new Array(cols);
       }
       return planar;
     }

     public static toLong(bytes: Uint8Array): number;
     public static toLong(bytes: Uint8Array, offset: number, byteCount: number): number;
     public static toLong(bytes: Uint8Array, offset?: number, byteCount?: number): number {
         if (offset === undefined || byteCount === undefined) {
             if (!bytes || bytes.length >= 9) throw new Error("参数长度不正确");
             return ValueUtils.toLong(bytes, 0, bytes.length);
         }

         let value = 0;
         for (let i = 0; i < byteCount; i++) {
             value <<= 8;
             value |= bytes[offset + i] & 0xff;
         }
         return value;
     }

     public static toInt(bytes: Uint8Array, offset: number, byteCount: number): number {
         let value = 0;
         for (let i = 0; i < byteCount; i++) {
             value <<= 8;
             value |= bytes[offset + i] & 0xff;
         }
         return value;
     }
}