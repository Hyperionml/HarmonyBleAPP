import { FeedbackRequest } from "../models/json/FeedbackRequest";
import { http } from "@kit.NetworkKit";
import { FeedbackResult } from "../models/json/FeedbackResult";
import { BusinessError } from "@kit.BasicServicesKit";
import fs from '@ohos.file.fs';
import { M8 } from "../M8";
import { util } from "@kit.ArkTS";
import BuildProfile from "BuildProfile";

export class ProtocolBufferSerialization {
    private static readonly TAG = 'ProtocolBufferSerialization'

    private BLOCK_SIZE = 1024; // 与后端约定的块大小

    /**
     * 发起一个加密的微信小程序网络请求。
     * 该函数会自动处理：
     * 1. 将请求数据（data）序列化、分块和加密。
     * 2. 发送二进制数据到服务器。
     * 3. 接收服务器返回的加密二进制数据。
     * 4. 解密、解码并解析成JavaScript对象。
     *
     * @param {object} options - 请求配置对象，类似于 wx.request 的参数。
     * @param {string} options.url - 开发者服务器接口地址。
     * @param {object} options.data - 需要发送的请求数据，会被自动加密。
     * @param {string} [options.method='POST'] - HTTP 请求方法。
     * @param {object} [options.header] - 额外的请求头。
     * @returns {Promise<any>} 返回一个 Promise，成功时 resolve 解析后的响应数据，失败时 reject 错误信息。
     */
    async requestEncrypted<T>(options: RequestOptions): Promise<T> {
        let resData: T = await new Promise(async (resolve: Function) => {
            //加密过程包装了
            let finalData = this.encode(options.data as object)

            // --- 2. 发起 wx.request --- 
            let httpRequest = http.createHttp();
            await httpRequest.request(
                options.url,
                {
                    method: options.method,
                    header: {
                        'Content-Type': 'application/json',
                    },
                    extraData: finalData.buffer, // 关键：必须传递 ArrayBuffer
                    expectDataType: http.HttpDataType.ARRAY_BUFFER, // 关键：期望服务器返回二进制数据
                },
            ).then((data: http.HttpResponse) => {
                let resultData = this.decode(data)

                console.log('bailiml requestEncrypted,resultData:' + JSON.stringify(resultData));
                resolve(resultData)
            }).catch((err: BusinessError) => {
                console.log('寄了', err)
                resolve({ IsSuccess:false,ErrorMessage:err.message})
            })
        })

        return resData
    }

    /**
     * 上传反馈信息中的图片以获取图片在后端服务器存储之后的url
     * @param {string} imagePath 文件路径
     * @returns 返回一个 Promise，成功时 resolve 解析后的响应数据，失败时 reject 错误信息。
     */
    async uploadImg(imgUri: string): Promise<FeedbackResult> {
        let reImgResult: FeedbackResult = await new Promise(async (resolve: Function) => {

            //图片上传接口的请求体参数封装
            let img: ArrayBuffer = this.getImageBinaryFromUri(imgUri)
            let imgDataObj: ImgDataEncodeObj = this.uploadImgDataEncode(img)

            let httpRequest = http.createHttp();
            await httpRequest.request(
                BuildProfile.MAIN_SERVER + '/Feedback/Upload',
                {
                    method: http.RequestMethod.POST,
                    header: {
                        // 关键：Content-Type 必须是 multipart/form-data，并指定 boundary
                        'Content-Type': 'multipart/form-data; boundary=' + imgDataObj.boundary,
                        'Accept': 'application/json' // 你期望的返回类型
                    },
                    extraData: imgDataObj.imgBuffer,
                    //extraData: finalData.buffer,// 关键：必须传递 ArrayBuffer
                    expectDataType: http.HttpDataType.ARRAY_BUFFER, // 关键：期望服务器返回二进制数据
                },
            ).then((data: http.HttpResponse) => {
                let resultData = this.decode(data)

                console.log('testtag requestUpload,resultData:' + JSON.stringify(resultData));
                resolve(resultData)
            }).catch((err: BusinessError) => {
                console.log('testtag 寄了:', err)
                resolve({ IsSuccess:false,ErrorMessage:err.message})
            });
        })

        return reImgResult
    }

    // --- 辅助函数 ---
    /**
     * 合并多个 ArrayBuffer
     * @param {...ArrayBuffer} buffers
     * @returns {ArrayBuffer}
     */
    combineBuffers(...buffers: ArrayBuffer[]) {
        const totalLength = buffers.reduce((acc, buffer) => acc + buffer.byteLength, 0);
        const result = new Uint8Array(totalLength);
        let offset = 0;
        for (const buffer of buffers) {
            result.set(new Uint8Array(buffer), offset);
            offset += buffer.byteLength;
        }
        return result.buffer;
    }

    /**
     * 根据图片uri获取图片的ArrayBuffer，这里uri的格式是鸿蒙定义的
     * @param path 图片的uri
     * @returns 图片的ArrayBuffer
     */
    getImageBinaryFromUri(path: string): ArrayBuffer {
        // 打开文件
        const file = fs.openSync(path, fs.OpenMode.READ_ONLY);

        try {
            // 获取文件信息（主要是文件大小）
            let size = fs.statSync(file.fd).size;

            // 创建缓冲区
            let buffer = new ArrayBuffer(size);

            // 读取文件内容
            fs.readSync(file.fd, buffer)

            // 转换为 Uint8Array
            return buffer;
        } finally {
            // 确保关闭文件
            fs.closeSync(file);
        }
    }

    /**
     * data请求参数的加密过程
     * @param data 需要加密的参数
     * @returns 参数加密包装后的Uint8Array
     */
    encode(data: object): Uint8Array{
        // 序列化为 JSON 字符串
        const jsonString = JSON.stringify(data);
        console.log('bailiml JSON String: ' + jsonString);
        // 编码为 Uint8Array
        const buffer : Uint8Array = new Uint8Array(jsonString.length * 4) // 一定要足够大的缓存区
        const encodeInfo = new util.TextEncoder().encodeIntoUint8Array(jsonString, buffer) // 这个api不自动扩容

        // 从大的 buffer 中切出实际包含了编码数据的部分，得到 rawData
        const rawData = buffer.slice(0, encodeInfo.written)
        // 分块 & 加密
        const encryptedBlocks: Uint8Array[] = []
        for (let i = 0; i < rawData.length; i += this.BLOCK_SIZE) {
            const block = rawData.slice(i, i + this.BLOCK_SIZE);
            const encrypted = M8.encrypt(block);
            encryptedBlocks.push(encrypted);
        }

        // 如果原始数据为空（例如 dataObject = {}），则加密一个空块
        if (rawData.length === 0) {
            encryptedBlocks.push(M8.encrypt(new Uint8Array(0)));
        }

        // 合并加密块
        const totalLength = encryptedBlocks.reduce((sum, b) => sum + b.length, 0);
        const finalData = new Uint8Array(totalLength);
        let offset = 0;
        for (let b of encryptedBlocks) {
            finalData.set(b, offset);
            offset += b.length;
        }

        console.log('bailiml 加密请求体：' + finalData)
        return finalData
    }

    /**
     * 请求响应体的解密过程
     * @param data //请求响应体
     * @returns 解密之后的响应体
     */
    decode(data: http.HttpResponse){
        // --- 3. 处理成功的响应 (解密流程) ---
        const arrayBuffer: ArrayBuffer = data.result as ArrayBuffer;
        if (!arrayBuffer || arrayBuffer.byteLength === 0) {
            // 成功但响应体为空，根据业务决定是 resolve(null) 还是 reject
            console.warn('请求成功，但响应体为空。');
        }
        const uint8Array = new Uint8Array(arrayBuffer);

        // 解密
        const decryptedBytes = M8.decrypt(uint8Array);
        if (decryptedBytes === null) {
            // 解密失败，说明响应数据有问题
            throw new Error('响应数据解密失败，格式不正确。');
        }

        // 解码并解析
        const textDecoder = new util.TextDecoder();
        const decodedStr: string = textDecoder.decode(decryptedBytes);
        const resultData: object = JSON.parse(decodedStr);

        return resultData
    }

    /**
     * 上传图片接口的请求体参数封装函数，这里几乎完全按照小程序的逻辑
     * @param img
     * @returns
     */
    uploadImgDataEncode(img: ArrayBuffer): ImgDataEncodeObj{
        // 1. 定义一个随机的 boundary
        // 这个 boundary 字符串不能在文件内容中出现
        const boundary = '----WebKitFormBoundary' + new Date().getTime().toString(16);
        const boundaryPrefix = '--' + boundary + '\r\n';
        const boundarySuffix = '--' + boundary + '--\r\n';
        // 2. 定义文件上传的字段名和文件名
        // 这里的 'file' 必须和后端 Request.Files["file"] 中的 key 一致
        const fieldName = 'file';
        const fileName = 'feedback.jpg'; // 你可以自定义一个文件名
        const fileType = 'image/jpeg'; // 文件的 MIME 类型
        // 3. 构建 multipart 的头部信息 (字符串)
        const multipartHeader =
            boundaryPrefix +
                `Content-Disposition: form-data; name="${fieldName}"; filename="${fileName}"\r\n` +
                `Content-Type: ${fileType}\r\n\r\n`; // 注意头部和内容之间有两个换行符 \r\n\r\n

        // --- 关键步骤：将字符串和 ArrayBuffer 合并 ---
        // wx.request 的 data 只能是统一类型，所以我们需要把所有东西都转成 ArrayBuffer
        // a. 将字符串头部转为 ArrayBuffer
        // 这里我们用一个辅助函数来实现
        const textEncoder = new util.TextEncoder();
        const headerBuffer = textEncoder.encode(multipartHeader) as ArrayBuffer
        // b. 将字符串尾部转为 ArrayBuffer
        const footerBuffer = textEncoder.encode('\r\n' + boundarySuffix) as ArrayBuffer
        // c. 拼接所有 ArrayBuffer
        const requestBuffer = this.combineBuffers(headerBuffer, img, footerBuffer)

        let re: ImgDataEncodeObj = new ImgDataEncodeObj(requestBuffer, boundary)
        return re
    }
}

// 请求选项类型
interface RequestOptions {
    url: string
    data: FeedbackRequest | object
    method: http.RequestMethod
}

//图片上传接口的请求体加密过程需要返回俩个对象，故整个一个类
export class ImgDataEncodeObj{
    imgBuffer: ArrayBufferLike
    boundary: string

    constructor(imgBuffer: ArrayBufferLike, boundary: string) {
        this.imgBuffer = imgBuffer
        this.boundary = boundary
    }
}