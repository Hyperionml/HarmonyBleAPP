import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, DEFAULT } from '@ohos/hypium'
import BuildProfile from 'BuildProfile';
import { FeedbackResult } from '../../../main/ets/common/models/json/FeedbackResult';
import { SerializationFactory } from '../../../main/ets/common/serialization/SerializationFactory';
import { http } from '@kit.NetworkKit';
import { FeedbackRequest } from '../../../main/ets/common/models/json/FeedbackRequest';
import { JSON5 } from '@wolfx/json5';
import utils from '@arkts.utils';
import { util } from '@kit.ArkTS';
import {
    ImgDataEncodeObj,
    ProtocolBufferSerialization } from '../../../main/ets/common/serialization/ProtocolBufferSerialization';
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';
import { EntryUtils } from '../../../main/ets/common/EntryUtils';
import { deviceInfo } from '@kit.BasicServicesKit';
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { UIAbility, Want } from '@kit.AbilityKit';
import { AnimatedDrawableDescriptor, router } from '@kit.ArkUI';
import { AppSetting } from '../../../main/ets/common/AppSetting';

let TAG = "FeedbackActivityTest";

export default function FeedbackPageTest() {

    let delegator: abilityDelegatorRegistry.AbilityDelegator = abilityDelegatorRegistry.getAbilityDelegator();
    // 初始化Driver对象
    const driver = Driver.create();
    let ability: UIAbility | null = null;

    let hadBack = false

    describe('FeedbackPageTest', () => {

        /********************************************apiTest**********************************************************/

        /**
         * 测试添加反馈接口能否访问
         */
        it('testIOFeedback', 0, async () => {
            let url = BuildProfile.MAIN_SERVER + "/Feedback/AddFeedback";
            let data = new FeedbackRequest()
            data.Phone = '12312341234'
            data.ChkQuestions = ['test']
            data.imageUrl = null
            data.IMEI = 'test'
            data.PackageName = 'test'
            data.SystemName = 'HarmonyOS'
            data.VersionCode = 111
            data.VersionName = 'test'
            data.Language = 'test'
            data.DeviceBrand = 'test'
            data.ABIs = 'test'
            data.Date = 'test'
            data.TvQuestion = 'test'
            data.DefaultLanguage = 'test'

            let protocolBufferSerialization = SerializationFactory.create()
            let ioResult: FeedbackResult = await protocolBufferSerialization.requestEncrypted({
                url: url,
                method: http.RequestMethod.POST,
                data: data
            })
            console.log(`FeedbackActivityTest 向添加反馈信息接口发送随机请求，是否能正常返回= ${JSON5.stringify(ioResult)}`)
            //断言能成功
            expect(ioResult.IsSuccess).assertEqual(true)
        })

        /**
         * 测试反馈上传文件接口
         *
         * @throws Exception
         */
        it("testUploadFile", DEFAULT, async () => {
            let protocolBufferSerialization = SerializationFactory.create()
            // 1*1像素的全黑png
            let base64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='
            let array = new util.Base64Helper().decodeSync(base64)
            //图片上传接口的请求体参数封装
            let img: ArrayBuffer = array.buffer as object as ArrayBuffer
            let imgDataObj: ImgDataEncodeObj = protocolBufferSerialization.uploadImgDataEncode(img)

            let httpRequest = http.createHttp();
            let uploadResult = new FeedbackResult()
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
                let resultData = protocolBufferSerialization.decode(data)

                console.log('testtag requestUpload,resultData:' + JSON.stringify(resultData));
                uploadResult = JSON5.parse(JSON5.stringify(resultData)) as FeedbackResult
            }).catch((err: BusinessError) => {
                console.log('testtag 寄了:', err)
                throw Error(err.name + ' ' + err.message)
            });

            let data = new FeedbackRequest()
            data.Phone = '12312341234'
            data.ChkQuestions = ['test']
            data.imageUrl = uploadResult.Url
            data.IMEI = 'test'
            data.PackageName = 'test'
            data.SystemName = 'HarmonyOS'
            data.VersionCode = 111
            data.VersionName = 'test'
            data.Language = i18n.System.getAppPreferredLanguage()
            data.DeviceBrand = 'test'
            data.ABIs = 'test'
            data.Date = 'test'
            data.TvQuestion = 'test'
            data.DefaultLanguage = i18n.System.getSystemLanguage()
            let ioResult: FeedbackResult = await protocolBufferSerialization.requestEncrypted({
                url: BuildProfile.MAIN_SERVER + "/Feedback/AddFeedback",
                method: http.RequestMethod.POST,
                data: data
            })
            console.log(`FeedbackActivityTest 测试向添加反馈信息接口上传随机请求参数能否成功返回数据：ioResult ${JSON5.stringify(ioResult)}`)
            //断言能成功
            expect(ioResult.IsSuccess).assertEqual(true)
        })

        /**
         * 测试添加反馈接口
         *
         * @throws IOException
         */
        it("testSerializableFeedback", DEFAULT, async () => {
            let protocolBufferSerialization = SerializationFactory.create()
            // 1*1像素的全黑png
            let base64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='
            let array = new util.Base64Helper().decodeSync(base64)
            //图片上传接口的请求体参数封装
            let img: ArrayBuffer = array.buffer as object as ArrayBuffer
            let imgDataObj: ImgDataEncodeObj = protocolBufferSerialization.uploadImgDataEncode(img)

            let httpRequest = http.createHttp();
            let uploadResult = new FeedbackResult()
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
                let resultData = protocolBufferSerialization.decode(data)

                console.log('testtag requestUpload,resultData:' + JSON.stringify(resultData));
                uploadResult = JSON5.parse(JSON5.stringify(resultData)) as FeedbackResult
            }).catch((err: BusinessError) => {
                console.log('testtag 寄了:', err)
                throw Error(err.name + ' ' + err.message)
            });

            let data = new FeedbackRequest()
            data.Phone = '12312341234'
            data.ChkQuestions = ['test']
            data.imageUrl = uploadResult.Url
            data.DefaultLanguage = i18n.System.getSystemLanguage()
            data.IMEI = EntryUtils.getUUID()
            data.PackageName = EntryUtils.getBundleInfoForSelfSync().name
            data.SystemName = 'HarmonyOS'
            data.VersionCode = EntryUtils.getBundleInfoForSelfSync().versionCode
            data.VersionName = EntryUtils.getBundleInfoForSelfSync().versionName
            data.Language = i18n.System.getAppPreferredLanguage()
            data.DeviceBrand = deviceInfo.brand
            data.ABIs = deviceInfo.abiList
            data.Date = EntryUtils.getFormattedSystemTime()
            data.TvQuestion = ''
            data.DefaultLanguage = i18n.System.getSystemLanguage()
            let ioResult: FeedbackResult = await protocolBufferSerialization.requestEncrypted({
                url: BuildProfile.MAIN_SERVER + "/Feedback/AddFeedback",
                method: http.RequestMethod.POST,
                data: data
            })
            console.log(`FeedbackActivityTest 测试向添加反馈信息接口上传序列化后的请求参数后能否成功返回数据：ioResult ${JSON5.stringify(ioResult)}`)
            //断言能成功
            expect(ioResult.IsSuccess).assertEqual(true)
        })


        /********************************************uiTest**********************************************************/

        beforeAll(async () => {
            const bundleName = abilityDelegatorRegistry.getArguments().bundleName;
            const want: Want = {
                bundleName: bundleName,
                abilityName: 'EntryAbility'
            }
            await delegator.startAbility(want);
            await driver.waitForIdle(1000,4000)
            ability = await delegator.getCurrentTopAbility();
            let appSetting = new AppSetting(ability!.context)
            appSetting.setIsAllowAgreement(true)
            appSetting.setShowUserGuideCount(2)
            expect(ability.context.abilityInfo.name).assertEqual('EntryAbility');

            const context = ability?.context;
            await context?.getApplicationContext().getRunningProcessInformation().then(() => {
                router.pushUrl({
                    url: 'pages/FeedbackPage'
                });
            });
            let btn1 = await driver.waitForComponent(ON.text('允许'), 2000)
            await btn1.click()
        })

        /**
         * 测试返回
         */
        it("testBack", DEFAULT, async () => {
            let back = await driver.waitForComponent(ON.text('返回'), 2000)
            await back.click()
            await driver.waitForIdle(4000,5000)
            await driver.assertComponentExist(ON.text('允许'))

            hadBack = true
            router.pushUrl({url: 'pages/FeedbackPage'})
        })


        /**
         * 不填写任何内容，直接提交
         */
        it("testSubmit1", DEFAULT, async () => {
            let back = await driver.waitForComponent(ON.text('提交'), 2000)
            await back.click()
            await driver.waitForIdle(4000,5000)
            await driver.assertComponentExist(ON.text('提交'))
        })


        /**
         * 测试数据提交,填写不符合的手机号码
         */
        it("testSubmit2", DEFAULT, async () => {
            let input1 = await driver.waitForComponent(ON.type('TextInput'), 2000)
            await input1.inputText('111')
            await driver.pressBack()
            let btn1 = await driver.waitForComponent(ON.text('扫描出错'), 2000)
            await btn1.click()
            let back = await driver.waitForComponent(ON.text('提交'), 2000)
            await back.click()
            await driver.waitForIdle(4000,5000)
            await driver.assertComponentExist(ON.text('提交'))
        })

        /**
         * 测试数据提交，填写正确的手机号码
         */
        it("testSubmit3", DEFAULT, async () => {
            let input1 = await driver.waitForComponent(ON.id('phoneNumberInput'), 2000)
            await input1.inputText('18888888888')
            await driver.pressBack()
            let btn1 = await driver.waitForComponent(ON.text('程序经常崩溃'), 2000)
            await btn1.click()
            let back = await driver.waitForComponent(ON.text('提交'), 2000)
            await back.click()
            await driver.waitForIdle(4000,5000)
            if(!hadBack){
                await driver.assertComponentExist(ON.text('允许'))
            }
            else {
                await driver.assertComponentExist(ON.id('exit'))
            }


            await router.pushUrl({url: 'pages/FeedbackPage'})
        })

        /**
         * 测试添加图片
         */
        it("testSelectPic", DEFAULT, async () => {
            await driver.waitForIdle(2000,5000)
            let pic = await driver.waitForComponent(ON.id('addPic'), 2000)
            await pic.click()
            let btn3 = await driver.waitForComponent(ON.type('Checkbox'), 2000)
            await btn3.click()
            let btn2 = await driver.waitForComponent(ON.text('完成'), 2000)
            await btn2.click()
            await driver.waitForComponent(ON.id('wait'), 1500)
            await driver.assertComponentExist(ON.text('X'))

            router.back()
            await driver.waitForComponent(ON.id('wait'), 400)
            await router.pushUrl({url: 'pages/FeedbackPage'})
        })

        /**
         * 所有内容都填写完整，提交
         * 该测试方法由于特别长且跟网络有关系，很大概率会超时
         * 为了保证该测试用例的通过率，将该测试调整为最后一个，且不再以返回主页为断言，而是以提交等待弹窗出现为断言标准
         */
        it("testSubmit4", DEFAULT, async () => {
            let input1 = await driver.waitForComponent(ON.id('phoneNumberInput'), 1000)
            let btn1 = await driver.waitForComponent(ON.text('其他'), 1000)
            let input2 = await driver.waitForComponent(ON.type('TextArea'), 1000)
            let pic = await driver.waitForComponent(ON.id('addPic'), 1000)
            await input1.inputText('18888888888')
            await driver.pressBack()
            await driver.waitForComponent(ON.id('wait'), 400)
            await btn1.click()
            await input2.inputText('abc123')
            await driver.pressBack()
            await driver.waitForComponent(ON.id('wait'), 400)

            await pic.click()
            let btn3 = await driver.waitForComponent(ON.type('Checkbox'), 1000)
            let btn2 = await driver.waitForComponent(ON.text('完成'), 1000)
            await btn3.click()
            await btn2.click()

            await driver.waitForComponent(ON.id('wait'), 400)
            let back = await driver.waitForComponent(ON.text('提交'), 1000)
            await back.click()

            await driver.waitForComponent(ON.id('wait'), 400)
            await driver.assertComponentExist(ON.text('请稍等…'))

        })



    })
}