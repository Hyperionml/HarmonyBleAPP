import { Setting } from "./Setting";
import { Context } from "@ohos.abilityAccessCtrl";
import { preferences } from "@kit.ArkData";
import i18n from "@ohos.i18n";

export class SystemSetting extends Setting {

    protected static readonly KEY_THEME = "Theme";
    protected static readonly KEY_FULLSCREEN = "Fullscreen";
    protected static readonly KEY_LANGUAGE = "Language";

    protected static readonly KEY_USE_COUNT = "UseCount";
    protected static readonly KEY_ALLOW_AGREEMENT = "AllowAgreement";

    public static readonly LanguageChinese = 'zh';
    public static readonly LanguageEnglish = 'en';
    public static readonly LanguageFrench = 'fr';//法语
    public static readonly LanguageGerman = 'de';//德语
    public static readonly LanguageSpanish = "es";//西班牙语
    public static readonly LanguagePortuguese = "pt";//葡萄牙语
    public static readonly LanguageVietnamese = "vi";//越南语

    public static readonly Languages: string[] = [SystemSetting.LanguageChinese, SystemSetting.LanguageEnglish,
        SystemSetting.LanguageFrench, SystemSetting.LanguageGerman, SystemSetting.LanguageSpanish,
        SystemSetting.LanguagePortuguese, SystemSetting.LanguageVietnamese]

    public constructor(context: Context) {
        super(context);
    }

    protected createPreferences(context: Context): preferences.Preferences {
        return preferences.getPreferencesSync(context, {name: 'SystemSetting'})
    }

    public getTheme(): Promise<string> {
        return this.getResourceColor(SystemSetting.KEY_THEME, '');
    }

    public setTheme(value: string) {

        if(value === undefined || value === null || value.length === 0){
            throw new Error('value不合法')
        }

        this.setString(SystemSetting.KEY_THEME, value);
        return this.commitChanges();
    }

    public setThemeColor(value: ResourceColor) {

        if(value === undefined || value === null){
            throw new Error('value不合法')
        }

        this.setResourceColor(SystemSetting.KEY_THEME, value);
        return this.commitChanges();
    }

    public isFullscreen() {
        return this.getBoolean(SystemSetting.KEY_FULLSCREEN, false);
    }

    public setFullscreen(value: boolean) {
        this.setBoolean(SystemSetting.KEY_FULLSCREEN, value);
        return this.commitChanges();
    }

    public async getLanguage() {
        let language = await this.getString(SystemSetting.KEY_LANGUAGE, null);
        if (language === undefined || language === null || language.length === 0) {
            language = i18n.System.getSystemLanguage()
            if (language.length > 2) {
                language = language.substring(0, 2);
            }
        }
        let supported = false;
        if (language != null) {
            for (let item of SystemSetting.Languages) {
                if (item.toLowerCase() === language.toLowerCase()) {
                    supported = true
                    break
                }
            }
        }
        if (!supported) {
            language = SystemSetting.LanguageEnglish;//默认英文
        }
        return language;
    }

    public setLanguage(value: string) {
        if (value === undefined || value === null || value.length === 0) return false;
        this.setString(SystemSetting.KEY_LANGUAGE, value);
        i18n.System.setAppPreferredLanguage(value);
        return this.commitChanges();
    }

    public getUseCount() {
        return this.getInt(SystemSetting.KEY_USE_COUNT, 0);
    }

    public setUseCount(value: number) {
        if(value <= 0){
            throw new Error('值不合法')
        }

        this.setInt(SystemSetting.KEY_USE_COUNT, value);
        return this.commitChanges();
    }

    //允许隐私协议与软件
    public setIsAllowAgreement(value: boolean){
        this.setBoolean(SystemSetting.KEY_ALLOW_AGREEMENT,value);
        return this.commitChanges();
    }

    public getIsAllowAgreement(){
        return this.getBoolean(SystemSetting.KEY_ALLOW_AGREEMENT,false);
    }
    public getIsAllowAgreementSync(){
        return this.getBooleanSync(SystemSetting.KEY_ALLOW_AGREEMENT,false);
    }

    public reset() {
        //if (BuildConfig.DEBUG) {
        this.setInt(SystemSetting.KEY_USE_COUNT, 0);
        this.commitChanges();
        //}
    }
}