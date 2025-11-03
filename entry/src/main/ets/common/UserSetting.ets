import { Setting } from "common/src/main/ets/Setting";
import { Context } from "@ohos.abilityAccessCtrl";
import { preferences } from "@kit.ArkData";

export class UserSetting extends Setting {

    constructor(context: Context) {
        super(context)
    }

    //账户
    private static readonly KEY_USE_NAME = "NAME";
    //密码
    private static readonly KEY_USE_PASSWOED = "PASSWOED";
    //第一次登录
    private static readonly KEY_USE_FIRST = "FIRST";
    //记住密码
    private static readonly KEY_USE_REMEMBER_PASSWORD = "REMEMBER_PASSWORD";
    //自动登录
    private static readonly KEY_USE_AUTO_LOGIN = "AUTOLOGIN";

    //用户访问数据接口的AccessToken令牌
    private static readonly KEY_USER_ACCESS_TOKEN = "USER_ACCESS_TOKEN";
    private static readonly KEY_USER_ACCESS_USER_ID = "USER_ACCESS_USER_ID";
    private static readonly KEY_USER_ACCESS_USER_COMPANY = "KEY_USER_ACCESS_USER_COMPANY";

    protected createPreferences(context: Context): preferences.Preferences {
        return preferences.getPreferencesSync(context, {name: "LoginSetting"})
    }

    public getUserName(){
        return this.getString(UserSetting.KEY_USE_NAME,'');
    }

    public async setUserName(userName: string): Promise<boolean> {
        await this.setString(UserSetting.KEY_USE_NAME,userName);
        return await this.commitChanges();
    }

    public getUserPassword(){
        return this.getString(UserSetting.KEY_USE_PASSWOED,'')
    }

    public async setUserPassword(password: string): Promise<boolean> {
        await this.setString(UserSetting.KEY_USE_PASSWOED,password);
        return await this.commitChanges();
    }

    public getIsFirstLogin(){
        return this.getBoolean(UserSetting.KEY_USE_FIRST,true);
    }

    public async setIsFirstLogin(first: boolean): Promise<boolean> {
        await this.setBoolean(UserSetting.KEY_USE_FIRST,first);
        return await this.commitChanges();
    }

    public getIsAutoLogin(){
        return this.getBoolean(UserSetting.KEY_USE_AUTO_LOGIN,false);
    }

    public async setIsAutoLogin(autologin: boolean): Promise<boolean> {
        await this.setBoolean(UserSetting.KEY_USE_AUTO_LOGIN,autologin);
        return await this.commitChanges();
    }

    public getIsRememberPassword(){
        return this.getBoolean(UserSetting.KEY_USE_REMEMBER_PASSWORD,true);
    }

    public async setIsRememberPassword(rememberPassword: boolean): Promise<boolean> {
        await this.setBoolean(UserSetting.KEY_USE_REMEMBER_PASSWORD,rememberPassword);
        return await this.commitChanges();
    }

    public getUserAccessToken() {
        return this.getString(UserSetting.KEY_USER_ACCESS_TOKEN, "");
    }

    public async setUserAccessToken(accessToken: string | null): Promise<boolean> {
        await this.setString(UserSetting.KEY_USER_ACCESS_TOKEN, accessToken || "");
        return await this.commitChanges();
    }

    public getUserId() {
        return this.getString(UserSetting.KEY_USER_ACCESS_USER_ID, "");
    }

    public async setUserId(userId: string | null): Promise<boolean> {
        await this.setString(UserSetting.KEY_USER_ACCESS_USER_ID, userId || "");
        return await this.commitChanges();
    }

    public getUserCompany() {
        return this.getString(UserSetting.KEY_USER_ACCESS_USER_COMPANY, null)
    }

    public async setUserCompany(userId: string): Promise<boolean> {
        await this.setString(UserSetting.KEY_USER_ACCESS_USER_COMPANY, userId);
        return await this.commitChanges();
    }

}