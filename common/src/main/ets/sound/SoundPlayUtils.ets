import { media } from "@kit.MediaKit";
import { audio } from "@kit.AudioKit";
import { Sounds } from "./Sounds";
import { BusinessError } from "@kit.BasicServicesKit";
import { application, common } from "@kit.AbilityKit";

export class SoundPlayUtils{
    public static mSoundPlayer: media.SoundPool | null = null
    public static soundPlayUtils: SoundPlayUtils | null = null

    static mContext: Context

    private static sounds: number[] = []

    /**
     * 初始化
     * 初始化音乐池  播发喇叭的   BaseApplication初始化 方法里面用
     * @param context
     */
    public static async init(context: Context) {
        if (SoundPlayUtils.soundPlayUtils === null) {
            SoundPlayUtils.soundPlayUtils = new SoundPlayUtils();
        }
        // ljj 2025年10月14日 09:12:30 由于现在模块改成了har，不再需要application.createModuleContext获取跨HAP/HSP包应用资源
        //获取本应用中其他Module的Context
        // application.createModuleContext(context,'common').then(async (commonContext: common.Context) => {
        //     console.info(`CreateModuleContext success, data: ${JSON.stringify(commonContext)}`);
        //     if (commonContext !== null) {
        //         try {
                    let commonContext = context;
                    SoundPlayUtils.mSoundPlayer = await media.createSoundPool(10, {usage: audio.StreamUsage.STREAM_USAGE_NOTIFICATION, rendererFlags: 0})
                    // 初始化声音
                    SoundPlayUtils.mContext = commonContext;

                    let scanRaw = commonContext.resourceManager.getRawFdSync('scan.mp3')
                    let scanId = await SoundPlayUtils.mSoundPlayer.load(scanRaw.fd, scanRaw.offset, scanRaw.length)
                    SoundPlayUtils.sounds[Sounds.Scan] = scanId

                    let errorRaw = commonContext.resourceManager.getRawFdSync('error.wav')
                    let errorId = await SoundPlayUtils.mSoundPlayer.load(errorRaw.fd, errorRaw.offset, errorRaw.length);
                    SoundPlayUtils.sounds[Sounds.Error] = errorId

                    let succeedRaw = commonContext.resourceManager.getRawFdSync('succeed.wav')
                    let succeedId = await SoundPlayUtils.mSoundPlayer.load(succeedRaw.fd, succeedRaw.offset, succeedRaw.length);
                    SoundPlayUtils.sounds[Sounds.Succeed] = succeedId

                    let warningRaw = commonContext.resourceManager.getRawFdSync('warning.wav')
                    let warningId = await SoundPlayUtils.mSoundPlayer.load(warningRaw.fd, warningRaw.offset, warningRaw.length);
                    SoundPlayUtils.sounds[Sounds.Warning] = warningId
    //             }
    //             catch (e){
    //                 let error = e as BusinessError;
    //                 console.error(error.message)
    //             }
    //         }
    //     }).catch((err: BusinessError) => {
    //             console.error(`CreateModuleContext failed, err code:${err.code}, err msg: ${err.message}`);
    //         });
    }
    /**
     * 播放声音
     *
     * @param soundID  设置声音
     */
    public static play(soundID: number) {
        SoundPlayUtils.mSoundPlayer?.play(SoundPlayUtils.sounds[soundID])// 恰巧各个参数的默认值和原设定一模一样
    }
}