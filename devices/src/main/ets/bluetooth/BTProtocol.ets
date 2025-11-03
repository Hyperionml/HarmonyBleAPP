import { BTActions } from "../model/BTActions";
import { BTRequest } from "../model/BTRequest";
import { BTSetCodeType } from "../model/BTSetCodeType";
import { BTSetSystemTime } from "../model/BTSetSystemTime";
import { BTWaitForTransfer } from "../model/BTWaitForTransfer";
import { BTSectionType } from "./BTSectionType";
import { BTRequestFile } from '../model/BTRequestFile';
import { ValueUtils, Log } from "common";
import { BuildConfig } from "../BuildConfig";
import { BTSection } from './BTSection';
import { util } from '@kit.ArkTS';
import { BTReport } from "./BTReport";
import { Utils as DUtils } from 'decoder';

const decoder = util.TextDecoder.create('utf-8');
/**
 * 蓝牙通信协议处理：应用和蓝牙设备之间的数据格式转换、协议封装/解析、
 * 封装：
 */
export class BTProtocol {
  private static uniqueId : number = 0;
  private static readonly textEncoder: util.TextEncoder = new util.TextEncoder('utf-8');

  /**
   * 解析蓝牙协议数据：BluetoothReader从蓝牙设备读取到Uint8Array后，
   * 调用BTProtocol.read将其解析成应用可以处理的BTRequest对象
   * 从报文中提取所有数据段的位置和范围就可以确定每个数据段的内容
   */
  public static read(buffer: Uint8Array, offset: number, length: number): BTReport | null {
    const crc =  DUtils.getCrc(buffer, offset, length - 1);  //CRC校验
    console.log(`testtag crc: ${crc}`)

    if (crc !== (buffer[length - 1] & 0xff)) {
      return null;
    }

    //初始化变量
    const sections: BTSection[] = [];
    let index = offset + 8; // 跳过Flag跟总长度
    const version: number = buffer[index++];
    const id: number = ValueUtils.toInt(buffer, index, 2);
    index += 2;
    //创建BTReport对象，协议解析结果统一封装
    const report: BTReport = new BTReport(version, id, sections);
    const sectionCount: number = buffer[index++] & 0xFF;  //数据段数量

    // 解析所有节
    for (let i = 0; i < sectionCount; i++) {
      const sectionTypeValue: number = buffer[index++] & 0xFF;
      const sectionOffset: number = ValueUtils.toInt(buffer, index, 3);  //数据段在报文的偏移量
      index += 3;

      try {
        const section = new BTSection(sectionTypeValue, sectionOffset, 0);
        sections.push(section);
      } catch (error) {
        return null;
      }
    }

    // 处理节内容
    for (let i = 0; i < sections.length; i++) {
      const cur: BTSection = sections[i];

      if (i < sections.length - 1) {
        const next: BTSection = sections[i + 1];
        cur.setLength(next.getOffset() - cur.getOffset());
      } else {
        cur.setLength(length - 1 - cur.getOffset());
      }

      // 提取内容
      const content: Uint8Array = new Uint8Array(cur.getLength());
      content.set(buffer.slice(cur.getOffset(), cur.getOffset() + cur.getLength()));
      //根据数据段类型转换为对应格式储存
      if (cur.getSectionType() === BTSectionType.Json) {
        cur.setJson(decoder.decodeToString(content));
      } else if (cur.getSectionType() === BTSectionType.File) {
        cur.setContent(content); // 保留字节内容
      }
    }
    return report;
  }

  /**
   * 写入蓝牙协议数据
   */
  public static write(action: BTActions): Uint8Array;
  public static write(request: BTRequest): Uint8Array;
  public static write(request: BTRequestFile): Uint8Array;
  public static write(request: BTWaitForTransfer): Uint8Array;
  public static write(request: BTSetSystemTime): Uint8Array;
  public static write(request: BTSetCodeType): Uint8Array;
  public static write(request: BTActions | BTRequest | BTRequestFile | BTWaitForTransfer | BTSetSystemTime | BTSetCodeType): Uint8Array {
    // 模拟安卓的assert：在调试模式检查null
    if (BuildConfig.DEBUG && (request === null || request === undefined)) {
      throw new Error('Assertion failed: request != null');
    }
    const json: string = JSON.stringify(request); //将请求对象序列化为JSON字符串
    return BTProtocol.writeJson(json);
  }

  /**
   * 获取协议唯一ID：ID字段占2字节。
   */
  private static getProtocolId(): number {
    if (BTProtocol.uniqueId === 65535) {
      BTProtocol.uniqueId = 0;
    } else {
      BTProtocol.uniqueId++;
    }
    return BTProtocol.uniqueId;
  }

  public static writeJson(json: string): Uint8Array {
    return BTProtocol.writeContent(json, null);
  }

  /**
   * 计算头部长度
   */
  private static getHeaderLength(sectionCount: number): number {
    return 4    // 报文标志:QTBT
      + 4       // 报文总长度
      + 1       // 报文版本号(1byte)
      + 2       // 报文ID(2bytes)
      + 1       // 章节个数(1byte)
      + (sectionCount << 2);
  }

  //将JSON编码为Unit8Array二进制报文
  //固定格式：[QTBT][总长度][协议版本][唯一ID][数据段描述][实际数据][CRC校验]
  public static writeContent(json: string, content: Uint8Array | null): Uint8Array {
    if (!json) {
      throw new Error('null');
    }

    const version: number = 1;　　//协议固定版本号为1
    const id: number = BTProtocol.getProtocolId();　　//唯一ID通过getProtocolId()生成
    const contentLength: number = content?.length ?? 0;
    const sectionCount: number = contentLength === 0 ? 1 : 2;
    const headerLength: number = BTProtocol.getHeaderLength(sectionCount);

    // 计算JSON字节长度
    const utf8Bytes: Uint8Array = BTProtocol.textEncoder.encodeInto(json);
    const jsonLength: number = utf8Bytes.length;
    const sectionsLength: number = jsonLength + contentLength;
    const jsonStart: number = headerLength;
    const contentStart: number = jsonStart + jsonLength;
    const totalLength: number = headerLength + sectionsLength + 1;
    const buffer: Uint8Array = new Uint8Array(totalLength);

    let index: number = 0;

    // 写入报文头标志 QTBT
    buffer[index++] = 'Q'.charCodeAt(0);
    buffer[index++] = 'T'.charCodeAt(0);
    buffer[index++] = 'B'.charCodeAt(0);
    buffer[index++] = 'T'.charCodeAt(0);

    // 写入总长度
    buffer[index++] = (totalLength >> 24) & 0xff;
    buffer[index++] = (totalLength >> 16) & 0xff;
    buffer[index++] = (totalLength >> 8) & 0xff;
    buffer[index++] = totalLength & 0xff;

    // 写入版本号
    buffer[index++] = version;

    // 写入报文ID：将报文ID转成二进制之后在前面补0凑成16位，将16位的数拆分成前8位和后8位，各自转成10进制写入［　，　］
    buffer[index++] = (id >> 8) & 0xff;　//高8位
    buffer[index++] = id & 0xff;　　//低8位

    // 写入章节个数
    buffer[index++] = sectionCount;

    // 第一个章节（JSON）
    buffer[index++] = 1;
    buffer[index++] = (jsonStart >> 16) & 0xff;
    buffer[index++] = (jsonStart >> 8) & 0xff;
    buffer[index++] = jsonStart & 0xff;

    // 第二个章节（文件内容）
    if (contentLength > 0 && content) {
      buffer[index++] = 2;
      buffer[index++] = (contentStart >> 16) & 0xff;
      buffer[index++] = (contentStart >> 8) & 0xff;
      buffer[index++] = contentStart & 0xff;
    }

    // 写入JSON内容（UTF-8 编码后的字节）
    buffer.set(utf8Bytes, jsonStart);

    // 写入文件内容
    if (contentLength > 0 && content) {
      buffer.set(content, contentStart);
    }

    // 计算并写入CRC
    const crc: number =  DUtils.getCrc(buffer, 0, totalLength - 1);
    buffer[totalLength - 1] = crc & 0xff;

    if (BuildConfig.DEBUG) {
      let result = "";
      for (let i = 0; i < buffer.length; i++) {
        const temp = (buffer[i] & 0xff).toString(16);
        if (temp.length === 1) {
          result += "0" + temp;
        } else {
          result += temp;
        }
        result += " , ";
      }
      Log.d("BTProtocol", result);
    }

    return buffer;
  }
}

