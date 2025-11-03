import { CustomTheme, CustomColors, ThemeControl } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { deviceInfo, systemDateTime } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit';
import { i18n, intl } from '@kit.LocalizationKit';


export class EntryUtils{

    static atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    static bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)

    /**
     * 仅检查是否拥有权限
     * @param context
     * @param arg1 需要检查的权限
     */
    static checkPermission(arg1: Permissions) {

        let re = EntryUtils.atManager.checkAccessTokenSync(EntryUtils.bundleInfo.appInfo.accessTokenId, arg1)

        return re === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
    }

    /**
     * 检查是否拥有权限，若没有则会发起弹窗请求
     * tip:不要用该方法去请求没有声明过得权限，且已经授权过得权限该方法不会调起弹窗只会返回true
     * @param context 应用上下文
     * @param arg1 权限列表
     */
    static async requestPermission(context: Context, arg1: Permissions[]) {
        let re = false
        let permissionRequestResult = await EntryUtils.atManager.requestPermissionsFromUser(context, arg1)
        console.log(`testtag authResults: ${permissionRequestResult.authResults}`)

        if(!permissionRequestResult.authResults.includes(-1) && !permissionRequestResult.authResults.includes(2)){
            re = true
        }

        return re
    }

    static getDataPreferences(context: Context | null | undefined) {
        try {
            let options: preferences.Options = { name: 'myStore' };
            return preferences.getPreferencesSync(context, options)
        } catch (e) {
            throw Error('未正常获取Preferences：' + e);
        }
    }

    static setThemeColor(color: ResourceColor){
        const theme = new PageCustomTheme(new Colors(color))
        ThemeControl.setDefaultTheme(theme)
    }

    static getLanguageCode(language: string): string{
        if(language === '简体中文') return 'zh'
        if(language === 'English') return 'en'
        if(language === 'Français') return 'fr'
        if(language === 'Deutsch') return 'de'
        if(language === 'Español') return 'es'
        if(language === 'Protuguês') return 'pt'
        return 'zh'
    }

    //将资源引用转换为实际的字符串
    static getStringByResourceManager(context: Context, resource: Resource): string {
        return context.resourceManager.getStringSync(resource.id);
    }

    /**
     * 获取一个不变和基本不重复的UUID
     * @return
     */
    static getUUID(){

        let serial: string = "fixed";

        let mSzDevIDShort = '35' +
            (deviceInfo.brand?.length ?? 0) % 10 +
            (deviceInfo.marketName?.length ?? 0) % 10 +
            (deviceInfo.productSeries?.length ?? 0) % 10 +
            (deviceInfo.productModel?.length ?? 0) % 10 +
            (deviceInfo.productModelAlias?.length ?? 0) % 10 +
            (deviceInfo.softwareModel?.length ?? 0) % 10 +
            (deviceInfo.hardwareModel?.length ?? 0) % 10 +
            (deviceInfo.hardwareProfile?.length ?? 0) % 10 +
            (deviceInfo.bootloaderVersion?.length ?? 0) % 10 +
            (deviceInfo.abiList?.length ?? 0) % 10 +
            (deviceInfo.securityPatchTag?.length ?? 0) % 10 +
            (deviceInfo.displayVersion?.length ?? 0) % 10 +
            (deviceInfo.osFullName?.length ?? 0) % 10

        // 3. 计算哈希值
        const hashHigh = hashCode(mSzDevIDShort);
        const hashLow = hashCode(serial);

        // 4. 组合为128位UUID（高位64位 + 低位64位）
        const hexHigh = toPaddedHex(hashHigh, 8); // 32位 -> 8位十六进制
        const hexLow = toPaddedHex(hashLow, 8);   // 32位 -> 8位十六进制

        // 5. 格式化为标准UUID
        return `00000000${hexHigh}00000000${hexLow}`.replace(
            /^(.{8})(.{4})(.{4})(.{4})(.{12})$/,
            '$1-$2-$3-$4-$5'
        );
    }

    /**
     * 获取包信息
     * @returns
     */
    static getBundleInfoForSelfSync(){
        return bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT)
    }

    // 获取格式化的系统时间函数
    static getFormattedSystemTime(): string {
        // 1. 获取当前时间戳（毫秒）
        const timestamp: number = systemDateTime.getTime();

        // 2. 创建Date对象
        const date = new Date(timestamp);

        if(deviceInfo.sdkApiVersion < 18 ){
            let formatter = new intl.DateTimeFormat('zh-CN', { dateStyle: 'short', timeStyle: 'medium', hourCycle: 'h24' });
            return formatter.format(date);
        }

        // 3. 使用DateTimeFormat进行格式化
        const formatter = i18n.getSimpleDateTimeFormatBySkeleton('yMdhms')

        // 4. 格式化并返回结果
        return formatter.format(date);
    }

}

export class Colors implements CustomColors {
    brand: ResourceColor
    fontPrimary: ResourceColor

    constructor(color: ResourceColor) {
        this.brand = color
        this.fontPrimary = color
    }
}

export class PageCustomTheme implements CustomTheme {
    static getPrimaryColor(): ResourceColor {
        throw new Error('Method not implemented.');
    }

    colors?: CustomColors;

    constructor(colors: CustomColors) {
        this.colors = colors;
    }

}

function hashCode(str: string): number {
    let hash = 0;
    if (str.length === 0) return hash;

    for (let i = 0; i < str.length; i++) {
        const char = str.charCodeAt(i);
        hash = (hash << 5) - hash + char;
        hash &= hash; // Convert to 32-bit integer
    }
    return hash >>> 0; // Ensure non-negative
}

function toPaddedHex(num: number, width: number): string {
    const hex = num.toString(16);
    return hex.padStart(width, '0').slice(-width);
}