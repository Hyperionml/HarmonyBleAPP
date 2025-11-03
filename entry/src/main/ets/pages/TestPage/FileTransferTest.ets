import { BluetoothFileReceiver } from 'devices/src/main/ets/bluetooth/BluetoothFileReceiver';
import { BTRequestFile } from 'devices/src/main/ets/model/BTRequestFile';
import { BTResponseFile } from 'devices/src/main/ets/model/BTResponseFile';
import { BTProtocol } from 'devices/src/main/ets/bluetooth/BTProtocol';
import { BTSection } from 'devices/src/main/ets/bluetooth/BTSection';
import { FileUtils, Log } from 'common';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { Utils as DUtils } from 'decoder';
import { BTSectionType } from 'devices/src/main/ets/bluetooth/BTSectionType';

const DOMAIN = 0x0001;

// 定义接口解决对象字面量类型问题
interface TamperScenario {
  name: string;
  position: number;
}

export class FileTransferTest {
  private context: common.UIAbilityContext;
  private testResults: string[] = [];

  constructor(context: common.UIAbilityContext) {
    if (!context) {
      throw new Error('初始化失败：UIAbilityContext不能为空');
    }
    this.context = context;
  }

  /**
   * 检查文件访问权限
   */
  private async checkFilePermissions(): Promise<boolean> {
    try {
      this.testResults.push('\n[权限检查]');

      // 根据官方文档，应用拥有对其沙箱目录的完全读写权限
      this.testResults.push(`- 应用文件目录: ${this.context.filesDir}`);
      this.testResults.push(`- 应用缓存目录: ${this.context.cacheDir}`);
      this.testResults.push(`- 根据官方文档，应用拥有对其沙箱目录的完全读写权限，无需申请额外权限`);

      // 检查应用内部目录是否存在
      try {
        const filesDirExists = FileUtils.isExist(this.context.filesDir);
        this.testResults.push(`- 文件目录存在: ${filesDirExists}`);

        const cacheDirExists = FileUtils.isExist(this.context.cacheDir);
        this.testResults.push(`- 缓存目录存在: ${cacheDirExists}`);

        // 如果目录不存在，尝试创建
        if (!filesDirExists) {
          try {
            fs.mkdirSync(this.context.filesDir, true);
            this.testResults.push(`- 文件目录创建成功`);
          } catch (mkdirError) {
            this.testResults.push(`- 文件目录创建失败: ${(mkdirError as Error).message}`);
          }
        }

        if (!cacheDirExists) {
          try {
            fs.mkdirSync(this.context.cacheDir, true);
            this.testResults.push(`- 缓存目录创建成功`);
          } catch (mkdirError) {
            this.testResults.push(`- 缓存目录创建失败: ${(mkdirError as Error).message}`);
          }
        }

        // 按照官方文档推荐方式测试文件读写
        const testFile = `${this.context.filesDir}/.permission_test`;
        try {
          this.testResults.push(`- 按照官方文档推荐方式测试文件读写...`);

          // 写入文件
          const file = await fs.open(testFile, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
          this.testResults.push(`- 测试文件打开成功: ${typeof file.fd === 'number' ? file.fd : JSON.stringify(file)}`);

          const testData = "Hello, HarmonyOS!";
          const data = new Uint8Array(testData.length);
          for (let i = 0; i < testData.length; i++) {
            data[i] = testData.charCodeAt(i);
          }

          const writeLen = await fs.write(file.fd, data.buffer);
          this.testResults.push(`- 写入 ${writeLen} 字节数据到测试文件`);

          await fs.close(file.fd);
          this.testResults.push(`- 测试文件写入并关闭成功`);

          // 删除测试文件
          fs.unlinkSync(testFile);
          this.testResults.push(`- 测试文件已清理`);

          this.testResults.push(`- 应用内部目录读写权限: 正常`);
        } catch (ioError) {
          this.testResults.push(`- 应用内部目录读写权限测试失败: ${(ioError as Error).message}`);
          // 尝试清理可能存在的测试文件
          try {
            if (FileUtils.isExist(testFile)) {
              fs.unlinkSync(testFile);
            }
          } catch (cleanupError) {
            // 忽略清理错误
          }
        }
      } catch (error) {
        this.testResults.push(`- 目录访问检查失败: ${(error as Error).message}`);
        return false;
      }

      return true;
    } catch (error) {
      this.testResults.push(`- 权限检查异常: ${(error as Error).message}`);
      return false;
    }
  }

  /**
   * 查看应用内部目录中的文件
   */
  private async diagnoseAppInternalDirectory(): Promise<void> {
    this.testResults.push('\n[应用内部目录文件查看]');

    try {
      // 列出内部文件目录中的文件
      try {
        const filesDirFiles = FileUtils.listFiles(this.context.filesDir);
        this.testResults.push(`\n[内部文件目录内容] (共${filesDirFiles.length}个文件/目录):`);
        if (filesDirFiles.length > 0) {
          filesDirFiles.forEach(file => {
            this.testResults.push(`  - ${file}`);
          });
        } else {
          this.testResults.push('  - 目录为空');
        }
      } catch (listError) {
        this.testResults.push(`- 列出内部文件目录内容失败: ${(listError as Error).message}`);
      }

      // 列出内部缓存目录中的文件
      try {
        const cacheDirFiles = FileUtils.listFiles(this.context.cacheDir);
        this.testResults.push(`\n[内部缓存目录内容] (共${cacheDirFiles.length}个文件/目录):`);
        if (cacheDirFiles.length > 0) {
          cacheDirFiles.forEach(file => {
            this.testResults.push(`  - ${file}`);
          });
        } else {
          this.testResults.push('  - 目录为空');
        }
      } catch (listError) {
        this.testResults.push(`- 列出内部缓存目录内容失败: ${(listError as Error).message}`);
      }

    } catch (error) {
      this.testResults.push(`- 内部目录查看异常: ${(error as Error).message}`);
    }
  }

  /**
   * 删除指定目录中的文件
   * @param directoryPath 目录路径
   * @param fileName 文件名
   */
  private async deleteFile(directoryPath: string, fileName: string): Promise<boolean> {
    try {
      const filePath = `${directoryPath}/${fileName}`;

      // 检查文件是否存在
      if (!FileUtils.isExist(filePath)) {
        this.testResults.push(`- 文件不存在: ${filePath}`);
        return false;
      }

      // 删除文件
      const result = FileUtils.delete(filePath);
      if (result) {
        this.testResults.push(`- 文件删除成功: ${filePath}`);
        return true;
      } else {
        this.testResults.push(`- 文件删除失败: ${filePath}`);
        return false;
      }
    } catch (error) {
      this.testResults.push(`- 文件删除异常: ${(error as Error).message}`);
      return false;
    }
  }

  /**
   * 批量删除目录中的文件
   * @param directoryPath 目录路径
   * @param fileNames 文件名数组
   */
  public async deleteFiles(directoryPath: string, fileNames: string[]): Promise<void> {
    this.testResults.push(`\n[删除文件操作]`);
    this.testResults.push(`- 目标目录: ${directoryPath}`);

    let successCount = 0;
    for (const fileName of fileNames) {
      const result = await this.deleteFile(directoryPath, fileName);
      if (result) {
        successCount++;
      }
    }

    this.testResults.push(`- 删除完成: 成功 ${successCount}/${fileNames.length} 个文件`);
  }

  public async runAllTests(): Promise<string> {
    this.testResults = [];
    this.testResults.push('=== 开始蓝牙文件传输功能测试 ===');

    try {
      await this.checkFilePermissions();
      await this.diagnoseAppInternalDirectory();

      // 删除特定文件
      // await this.deleteFiles(this.context.filesDir, ['test.txt', 'temp.dat']);

      await this.testProtocolEncoding();
      await this.testFileReceiverCreation();
      await this.testFileReceiving();
      await this.testFileRequestResponse();
      await this.testResumeTransfer();
      await this.testMD5Check();
      await this.testProtocolCRC();

      this.testResults.push('=== 所有测试执行完成 ===');
    } catch (error) {
      const err = error as Error;
      this.testResults.push(`[错误] 测试中断: ${err.message}`);
      Log.e('FileTransferTest', `测试中断: ${err.message}`);
    }

    return this.testResults.join('\n');
  }


  private async testProtocolEncoding(): Promise<void> {
    this.testResults.push('\n[测试1] 协议封装功能');

    try {
      const requestFile = new BTRequestFile();
      requestFile.setFileName('test.txt');
      requestFile.setBegin(0);
      requestFile.setRequestLength(1024);

      this.testResults.push(`- 请求参数: 文件名=${requestFile.getFileName()}, 起始位置=${requestFile.getBegin()}, 请求长度=${requestFile.getRequestLength()}`);

      const requestBuffer = BTProtocol.write(requestFile);
      this.testResults.push(`- 请求协议: 生成字节流长度=${requestBuffer ? requestBuffer.length + '字节' : 'null'}`);

      const responseFile = new BTResponseFile();
      responseFile.setFileName('response.txt');
      responseFile.setBegin(0);
      responseFile.setResponseLength(512);

      this.testResults.push(`- 响应参数: 文件名=${responseFile.getFileName()}, 起始位置=${responseFile.getBegin()}, 响应长度=${responseFile.getResponseLength()}`);

      const responseJson = JSON.stringify({
        fileName: responseFile.getFileName(),
        begin: responseFile.getBegin(),
        responseLength: responseFile.getResponseLength()
      });

      const responseBuffer = BTProtocol.writeJson(responseJson);
      this.testResults.push(`- 响应协议: JSON长度=${responseJson.length}字符, 生成字节流长度=${responseBuffer ? responseBuffer.length + '字节' : 'null'}`);

    } catch (error) {
      const err = error as Error;
      this.testResults.push(`[错误] 协议封装: ${err.message}`);
    }
  }

  private async testFileReceiverCreation(): Promise<void> {
    this.testResults.push('\n[测试2] 文件接收器创建');

    try {
      const testFileName = 'test_file.txt';
      const testFileType = 'txt';
      const testFileMD5 = 'd41d8cd98f00b204e9800998ecf8427e';
      const testFileSize = 1024;

      this.testResults.push(`- 创建参数: 文件名=${testFileName}, 类型=${testFileType}, MD5=${testFileMD5}, 大小=${testFileSize}字节`);

      const receiver = BluetoothFileReceiver.createFromContext(
        this.context,
        testFileName,
        testFileType,
        testFileMD5,
        testFileSize
      );

      if (receiver) {
        this.testResults.push(`- 接收器信息: 远程路径=${(await receiver).getRemotePath() || '未知'}, 本地路径=${(await receiver).getLocalPath() || '未知'}`);
        this.testResults.push(`- 初始状态: 总长度=${(await receiver).getTotalLength()}`);
      } else {
        this.testResults.push('- 接收器信息: 创建失败 (null)');
      }

    } catch (error) {
      const err = error as Error;
      this.testResults.push(`[错误] 接收器创建: ${err.message}`);
    }
  }

  private async testFileReceiving(): Promise<void> {
    this.testResults.push('\n[测试3] 文件数据接收');

    try {
      const testFileName = 'test_receive.txt';
      const testFileSize = 100;

      this.testResults.push(`- 测试参数: 文件名=${testFileName}, 总大小=${testFileSize}字节`);

      const receiver = await BluetoothFileReceiver.createFromContext(
        this.context,
        testFileName,
        'txt',
        'd41d8cd98f00b204e9800998ecf8427e',
        testFileSize
      );

      // 模拟多次接收直到文件完成
      let totalReceived = 0;
      let receiveSuccess = true;
      const chunkSize = 20; // 每次接收的字节

      while (totalReceived < testFileSize && receiveSuccess) {
        const remaining = testFileSize - totalReceived;
        const currentChunkSize = Math.min(chunkSize, remaining);
        // 动态生成测试数据
        const chunkData = new Uint8Array(currentChunkSize);
        for (let i = 0; i < currentChunkSize; i++) {
          // 生成不同的测试数据
          chunkData[i] = 65 + ((totalReceived + i) % 26);
        }

        receiveSuccess = await receiver.receive(chunkData, totalReceived, currentChunkSize);
        if (receiveSuccess) {
          totalReceived += currentChunkSize;
        }

        this.testResults.push(`- 接收进度: ${totalReceived}/${testFileSize}字节, 状态=${receiveSuccess}`);
      }

      this.testResults.push(`- 最终结果: 操作状态=${receiveSuccess}`);
      this.testResults.push(`- 进度信息: ${receiver.getProgress()}%, 完成状态=${receiver.isComplete()}`);

    } catch (error) {
      const err = error as Error;
      this.testResults.push(`[错误] 数据接收: ${err.message}`);
    }
  }

  private async testFileRequestResponse(): Promise<void> {
    this.testResults.push('\n[测试4] 文件请求和响应');

    try {

      const requestFile = new BTRequestFile();
      requestFile.setFileName('request_file.txt');
      requestFile.setBegin(0);
      requestFile.setRequestLength(1024);

      this.testResults.push(`- 请求参数: 文件名=${requestFile.getFileName()}, 起始位置=${requestFile.getBegin()}, 请求长度=${requestFile.getRequestLength()}`);

      const requestBuffer = BTProtocol.write(requestFile);
      this.testResults.push(`- 请求协议: 字节流长度=${requestBuffer ? requestBuffer.length + '字节' : 'null'}`);

      const responseFile = new BTResponseFile();
      responseFile.setFileName('response_file.txt');
      responseFile.setBegin(0);
      responseFile.setResponseLength(5);

      const responseJson = JSON.stringify({
        fileName: responseFile.getFileName(),
        begin: responseFile.getBegin(),
        responseLength: responseFile.getResponseLength()
      });

      const contentData = new Uint8Array([70, 71, 72, 73, 74]);

      this.testResults.push(`- 响应参数: JSON=${responseJson}, 数据长度=${contentData.length}字节, 数据内容=[${contentData.join(',')}]`);

      const section1 = new BTSection(1, responseJson.length);
      section1.setJson(responseJson);
      const section2 = new BTSection(2, contentData.length);
      section2.setContent(contentData);

      this.testResults.push(`- 协议结构: 数据段数量=${[section1, section2].length}`);
      this.testResults.push(`  数据段1: 类型=${section1.getSectionType().getTypeValue()}, JSON长度=${section1.getJson()?.length}字符`);
      this.testResults.push(`  数据段2: 类型=${section2.getSectionType().getTypeValue()}, 内容长度=${section2.getContent()?.length}字节`);
      if (section2.getContent()) {
        const contentStr = String.fromCharCode(...section2.getContent()!);
        this.testResults.push(`- 解析结果: 内容转换=${contentStr}`);
      }

    } catch (error) {
      const err = error as Error;
      this.testResults.push(`[错误] 请求响应: ${err.message}`);
    }
  }

  private async testResumeTransfer(): Promise<void> {
    this.testResults.push('\n[测试5] 断点续传功能');

    try {
      const testFileName = 'resume_test.txt';
      const testFileSize = 1000;

      this.testResults.push(`- 测试参数: 文件名=${testFileName}, 总大小=${testFileSize}字节`);

      const receiver = await BluetoothFileReceiver.createFromContext(
        this.context,
        testFileName,
        'txt',
        'd41d8cd98f00b204e9800998ecf8427e',
        testFileSize
      );

      // 模拟多次接收直到文件完成
      let totalReceived = 0;
      let receiveSuccess = true;
      const chunkSize = 300; // 每次接收的字节

      while (totalReceived < testFileSize && receiveSuccess) {
        const testData = new Uint8Array(chunkSize);
        testData.fill(65 + (totalReceived / chunkSize));

        receiveSuccess = await receiver.receive(testData, totalReceived, testData.length);

        if (receiveSuccess) {
          totalReceived += testData.length;
          this.testResults.push(`- 接收进度: ${totalReceived}/${testFileSize}字节, 状态=${receiveSuccess}, 进度=${receiver.getProgress()}%`);
        } else {
          this.testResults.push(`- 接收失败: 在${totalReceived}字节处`);
          break;
        }

        // 模拟断点续传的等待
        if (totalReceived < testFileSize) {
          const nextBegin = receiver.getBeginAndWait();
          this.testResults.push(`- 断点信息: 下一次起始位置=${nextBegin}`);
        }
      }

      this.testResults.push(`- 最终进度: ${receiver.getProgress()}%, 完成状态=${receiver.isComplete()}`);

    } catch (error) {
      const err = error as Error;
      this.testResults.push(`[错误] 断点续传: ${err.message}`);
    }
  }

  private async testMD5Check(): Promise<void> {
    this.testResults.push('\n[测试6] MD5校验功能');

    try {
      const testFileName = 'md5_test.txt';
      const testContent = "Hello, MD5 Test!";
      const filePath = this.context.filesDir + '/' + testFileName;

      // 写入测试文件
      const data = new Uint8Array(testContent.length);
      for (let i = 0; i < testContent.length; i++) {
        data[i] = testContent.charCodeAt(i);
      }

      const fd = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      await fs.write(fd.fd, data.buffer);
      fs.closeSync(fd);

      // 计算MD5
      let fileMd5 = DUtils.getMD5ofFile(filePath);
      if (fileMd5 === null) {
        this.testResults.push(`- MD5计算返回null`);
        return;
      }

      this.testResults.push(`- 测试文件MD5: ${fileMd5}`);

      // 创建接收器测试
      const receiver = await BluetoothFileReceiver.createFromContext(
        this.context,
        testFileName,
        'txt',
        fileMd5,
        testContent.length
      );

      // 写入数据
      const writeSuccess = await receiver.receive(data, 0, data.length);
      this.testResults.push(`- 文件写入: ${writeSuccess}`);
      this.testResults.push(`- 完成状态: ${receiver.isComplete()}`);

      // 检查MD5
      const md5CheckResult = await receiver.checkMd5();
      if (md5CheckResult) {
        this.testResults.push(`- MD5校验成功`);
      } else {
        this.testResults.push(`- MD5校验失败`);
      }

      // 清理测试文件
      fs.unlinkSync(filePath);

    } catch (error) {
      const err = error as Error;
      this.testResults.push(`[错误] MD5测试: ${err.message}`);
    }
  }


  /**
   * 计算协议头部长度
   */
  private static calculateHeaderLength(sectionCount: number): number {
    return 4    // 报文标志:QTBT
      + 4       // 报文总长度
      + 1       // 报文版本号(1byte)
      + 2       // 报文ID(2bytes)
      + 1       // 章节个数(1byte)
      + (sectionCount << 2);
  }

  /**
   * 测试: 验证协议解析时CRC校验是否生效
   */
  private async testProtocolCRC(): Promise<void> {
    this.testResults.push('\n[测试7] CRC校验测试');

    try {
      // 测试合法数据解析
      const validRequest = new BTRequestFile();
      validRequest.setFileName('parse_test.txt');
      validRequest.setBegin(0);
      validRequest.setRequestLength(512);
      const validBuffer = BTProtocol.write(validRequest);

      const validReport = BTProtocol.read(validBuffer, 0, validBuffer.length);
      if (validReport) {
        const sections = validReport.getSection();
        if (sections.length > 0) {
          const jsonSection = sections.find(s => s.getSectionType() === BTSectionType.Json);
          if (jsonSection) {
            const jsonContent = jsonSection.getJson();
            if (jsonContent && jsonContent.includes('parse_test.txt')) {
              this.testResults.push(`- 合法数据解析成功: 校验通过，解析出${sections.length}个数据段`);
            } else {
              this.testResults.push(`- 合法数据解析失败: 解析内容不正确`);
              return;
            }
          } else {
            this.testResults.push(`- 合法数据解析失败: 未找到JSON数据段`);
            return;
          }
        } else {
          this.testResults.push(`- 合法数据解析失败: 未解析出任何数据段`);
          return;
        }
      } else {
        this.testResults.push(`- 合法数据解析失败: 合法数据校验未通过`);
        return;
      }

      // 测试CRC错误的非法数据
      const invalidBuffer = new Uint8Array(validBuffer);
      const jsonStart = FileTransferTest.calculateHeaderLength(1);
      if (jsonStart + 5 < invalidBuffer.length - 1) {
        invalidBuffer[jsonStart + 5] = (invalidBuffer[jsonStart + 5] + 1) & 0xff;

        const invalidReport = BTProtocol.read(invalidBuffer, 0, invalidBuffer.length);
        if (!invalidReport) {
          this.testResults.push(`- 非法数据解析成功: 校验失败（符合预期）`);
        } else {
          this.testResults.push(`- 非法数据解析失败: 非法数据校验通过（不符合预期）`);
        }
      } else {
        this.testResults.push(`- 非法数据解析失败: 无效的篡改位置`);
      }
    } catch (error) {
      this.testResults.push(`- 协议解析CRC校验异常: ${(error as Error).message}`);
    }
  }
}