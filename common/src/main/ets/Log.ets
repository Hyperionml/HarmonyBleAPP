import { hilog } from '@kit.PerformanceAnalysisKit';
import { BuildConfig } from './BuildConfig';
import { Environment } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';

/**
 * 在改日志类中原本的实现里存在使用反射api（具体为将class直接作为参数传递），鉴于这是日志工具类，我选择舍弃了那些方法
 */
export class Log {
    //0级，不输出任何Log
    public static readonly LEVEL_NONE = 10;
    //1级，重大致命异常
    public static readonly LEVEL_FATAL =  hilog.LogLevel.FATAL;
    //2级，错误信息
    public static readonly LEVEL_ERROR =  hilog.LogLevel.ERROR;
    //3级，非预期情况
    public static readonly LEVEL_WARN = hilog.LogLevel.WARN;
    //4级，普通信息
    public static readonly LEVEL_INFO = hilog.LogLevel.INFO;
    //5级，所有信息
    public static readonly LEVEL_DEBUG = hilog.LogLevel.DEBUG;

    //配置Log输出级别
    public static level = Log.LEVEL_DEBUG;

    public static d(tag: string,msg: string){
        Log.d2(tag, msg, Log.LEVEL_INFO);
    }

    public static d2(tag: string, msg: string, level: number){
        if(Log.check(level)) {
            hilog.debug(0x0001, tag, '%{public}s', msg);
        }
    }

    public static i(tag: string, msg: string){
        Log.i2(tag,msg,Log.LEVEL_INFO);
    }

    public static i2(tag: string, msg: string, level: number){
        if(Log.check(level)) {
            hilog.info(0x0002, tag, '%{public}s', msg);
        }
    }

    public static w(tag: string, msg: string){
        Log.w2(tag,msg,Log.LEVEL_WARN);
    }

    public static w2(tag: string, msg: string, level: number){
        if(Log.check(level)) {
            hilog.warn(0x0003, tag, '%{public}s', msg);
        }
    }

    public static e(tag: string, msg: string){
        Log.e2(tag,msg,Log.LEVEL_ERROR);
    }

    public static e2(tag: string, msg: string, level: number){
        if(Log.check(level)) {
            hilog.error(0x0004, tag, '%{public}s', msg);
        }
    }

    public static f(tag: string, msg: string){
        Log.f2(tag,msg,Log.LEVEL_FATAL);
    }

    public static f2(tag: string, msg: string, level: number){
        if(Log.check(level)) {
            hilog.fatal(0x0005, tag, '%{public}s', msg);
        }
    }

    private static check(level: number) {
        return level >= Log.level;
    }

    public static mark(mark: string) {
        if (BuildConfig.DEBUG)
        {
            let sb = ''
            let now = new Date();
            let dateFormat = new Intl.DateTimeFormat("yyyy-MM-dd HH:mm:ss");
            let FileName = dateFormat.format(now);
            sb += ("[" + FileName + "]\r\n");
            sb += (mark + "\r\n");

            // 获取上下文
            const context = getContext() as common.UIAbilityContext;

            // 获取下载目录路径
            const filesDir = context.filesDir;
            const filePath = `${filesDir}/qt_mark.txt`;

            // 文件操作
            try {
                const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
                fs.writeSync(file.fd, sb, { offset: fs.statSync(filePath).size });
                fs.closeSync(file);
            } catch (error) {
                console.error(`Mark failed: ${error.code}, ${error.message}`);
            }

        }
    }
}

export class Logger {
    private static readonly DOMAIN: number = 0xFF00;
    private static readonly TAG: string = 'com.baoshen.HiddenCode';
    private static readonly PREFIX: string = '[camera-log]';

    public static debug(logTag: string, messageFormat: string, ...args: Object[]): void {
        hilog.debug(Logger.DOMAIN, Logger.TAG, `${Logger.PREFIX} ${logTag}: ${messageFormat}`, args);
    }

    public static info(logTag: string, messageFormat: string, ...args: Object[]): void {
        hilog.info(Logger.DOMAIN, Logger.TAG, `${Logger.PREFIX} ${logTag}: ${messageFormat}`, args);
    }

    public static warn(logTag: string, messageFormat: string, ...args: Object[]): void {
        hilog.warn(Logger.DOMAIN, Logger.TAG, `${Logger.PREFIX} ${logTag}: ${messageFormat}`, args);
    }

    public static error(logTag: string, messageFormat: string, ...args: Object[]): void {
        hilog.error(Logger.DOMAIN, Logger.TAG, `${Logger.PREFIX} ${logTag}: ${messageFormat}`, args);
    }

    public static fatal(logTag: string, messageFormat: string, ...args: Object[]): void {
        hilog.fatal(Logger.DOMAIN, Logger.TAG, `${Logger.PREFIX} ${logTag}: ${messageFormat}`, args);
    }

    private constructor() {
    }
}