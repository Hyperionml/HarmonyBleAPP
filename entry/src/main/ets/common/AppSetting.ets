import { SystemSetting } from 'common/src/main/ets/SystemSetting'

export class AppSetting extends SystemSetting {
    public static readonly KEY_CAMERA_COUNT = "CameraCount";

    public static readonly KEY_SELECTED_CAMERA_ID = "SelectedCameraId";
    //    protected static final String KEY_IS_SUPPORT_FAR_AWAY_MODE = "IsSupportFarAwayMode";
    protected static readonly KEY_IS_HIGH_PERFORMANCE_DEVICE = "IsHighPerformanceDevice";
    protected static readonly KEY_IS_SHOW_DECODE_DETAILS = "IsShowDecodeDetails";
    protected static readonly KEY_IS_ENABLED_SCREENSHOT = "IsEnabledScreenshot";

    public static readonly ThemeBlue = "#559BE9";
    public static readonly ThemeGreen = "ThemeGreen";
    public static readonly ThemeOrange = "ThemeOrange";
    public static readonly ThemeRed = "ThemeRed";
    public static readonly ThemeYellow = "ThemeYellow";
    public static readonly ThemeGray = "ThemeGray";
    public static readonly ThemeDefault = AppSetting.ThemeBlue;
    public static readonly LastUpdateTime = "LastUpdateTime";
    public static readonly ShowUserGuideCount = "ShowUserGuideCount";
    public static readonly PreviewSize = "PreviewSize";

    protected static readonly KEY_DECODES = "Decodes";
    protected static readonly KEY_SOUND = "Sound";
    protected static readonly KEY_SHAKE = "Shake";
    protected static readonly KEY_SHOWQC = "ShowQC";

    protected static readonly KEY_API2 = "Api2";

    protected static readonly KEY_DISTRIBUTIONCHSNNEL = "DistributionChannel";
    protected static readonly KEY_UPDATEDIALOGINTERVAL = "UpdateDialogInterval";//软件更新弹框多久弹出一次
    protected static readonly KEY_UPDATETIMERPERIOD = "UpdateTimerPeriod";//软件更新定时器多久触发一次
    protected static readonly KEY_IS_FIXED_FOCUS_DISTANCE = "IsFixedFocusDistance";//固定对焦距离
    protected static readonly KEY_IS_SUPPORT_FIXED_FOCUS_DISTANCE = "IsSupportedFixedFocusDistance";
    protected static readonly KEY_CALCULATEPHYSICSWIDTHSCALE = "CalculatePhysicsWidthScale";//固定对焦距离
    protected static readonly KEY_SENSORPIXELSIZESCALE = "SensorPixelSizeScale";
    protected static readonly KEY_LAST_REQUIRE_PERMISSION = "LastRequirePermission";//最近一次主动获取权限的时间
    protected static readonly KEY_REQUIRE_PERMISSION_COUNT = "RequirePermissionCount";//请求权限的次数

    protected static readonly KEY_BATTERY_WARNING = "BatteryWarning";
    protected static readonly KEY_BLUETOOTH_SHOW_ON_MAIN = "BluetoothShowOnMain";
    protected static readonly KEY_AUTO_CONNECT_BLUETOOTH = "AutoConnectBluetooth";
    protected static readonly KEY_QC_MODE = "QCMode";
    protected static readonly KEY_BLUETOOTH_TEST_MODE_MODE = "BluetoothTestMode";
    protected static readonly KEY_IS_BLUETOOTH_SERVER = "IsBluetoothServer";
    protected static readonly KEY_LAST_BLUETOOTH = "LastBluetooth";
    protected static readonly KEY_IS_AUTO_DECODE_CAMERA = "IsAutoDecodeCamera";
    protected static readonly KEY_IS_ENABLED_HYPERFOCAL_DISTANCE = "IsEnabledHyperfocalDistance";
    protected static readonly KEY_IS_SUPPORT_MULTI_FOCAL_LENGTH = "IsSupportMultiFocalLength";

    public static ISENGINEERMODE = false;
    public static readonly OpenEngineerModeClickCount = 7;

    constructor(context: Context) {
        super(context)
    }

    /*
    * camera(cmos)的个数
    * */
    public getCameraCount(){
        return this.getInt(AppSetting.KEY_CAMERA_COUNT,0)
    }

    public setCameraCount(value: number) {
        this.setInt(AppSetting.KEY_CAMERA_COUNT, value);
        return this.commitChanges()
    }

    /**是否自动选择解码用的摄像头*/
    public getIsAutoDecodeCamera(){
        return this.getBoolean(AppSetting.KEY_IS_AUTO_DECODE_CAMERA,true);
    }

    public setIsAutoDecodeCamera(value: boolean) {
        this.setBoolean(AppSetting.KEY_IS_AUTO_DECODE_CAMERA, value);
        return this.commitChanges();
    }

    public existedIsAutoDecodeCamera(){
        return this.contains(AppSetting.KEY_IS_AUTO_DECODE_CAMERA);
    }

    /**选中的相机*/
    public getSelectedCameraId(){
        return this.getString(AppSetting.KEY_SELECTED_CAMERA_ID,"")
    }

    public setSelectedCameraId(value: string){
        this.setString(AppSetting.KEY_SELECTED_CAMERA_ID,value);
        return this.commitChanges()
    }

    public existedSelectedCameraId(){
        return this.contains(AppSetting.KEY_SELECTED_CAMERA_ID)
    }

    /**是否启用超焦距模式*/
    public getIsEnabledHyperfocalDistance(){
        return this.getBoolean(AppSetting.KEY_IS_ENABLED_HYPERFOCAL_DISTANCE,true);
    }

    public setIsEnabledHyperfocalDistance(value: boolean) {
        this.setBoolean(AppSetting.KEY_IS_ENABLED_HYPERFOCAL_DISTANCE, value);
        return this.commitChanges()
    }

    public existedIsEnabledHyperfocalDistance(){
        return this.contains(AppSetting.KEY_IS_ENABLED_HYPERFOCAL_DISTANCE);
    }

    /**是否高性能设备*/
    public getIsHighPerformanceDevice(){
        return this.getBoolean(AppSetting.KEY_IS_HIGH_PERFORMANCE_DEVICE,false)
    }

    public setIsHighPerformanceDevice(value: boolean) {
        this.setBoolean(AppSetting.KEY_IS_HIGH_PERFORMANCE_DEVICE, value);
        return this.commitChanges()
    }
    public existedIsHighPerformanceDevice(){
        return this.contains(AppSetting.KEY_IS_HIGH_PERFORMANCE_DEVICE);
    }

    /**是否固定焦距(仅光学变焦才有效果)*/
    public getIsSupportMultiFocalLength(){
        return this.getBoolean(AppSetting.KEY_IS_SUPPORT_MULTI_FOCAL_LENGTH,false)
    }
    public setIsSupportMultiFocalLength(value: boolean) {
        this.setBoolean(AppSetting.KEY_IS_SUPPORT_MULTI_FOCAL_LENGTH, value);
        return this.commitChanges();
    }

    /**是否显示解码详情*/
    public getIsShowDecodeDetails(){
        return this.getBoolean(AppSetting.KEY_IS_SHOW_DECODE_DETAILS,false)
    }
    public setIsShowDecodeDetails(value: boolean) {
        this.setBoolean(AppSetting.KEY_IS_SHOW_DECODE_DETAILS, value);
        return this.commitChanges()
    }

    /**是否允许截图*/
    public getIsEnabledScreenshot(){
        return this.getBoolean(AppSetting.KEY_IS_ENABLED_SCREENSHOT,true)
    }
    public setIsEnabledScreenshot(value: boolean) {
        this.setBoolean(AppSetting.KEY_IS_ENABLED_SCREENSHOT, value);
        return this.commitChanges()
    }

    public getTheme(): Promise<string> {
        return this.getResourceColor(AppSetting.KEY_THEME, AppSetting.ThemeDefault);
    }

    //打开引导界面的次数
    public getShowUserGuideCount() {
        return this.getInt(AppSetting.ShowUserGuideCount, 0);
    }
    public getShowUserGuideCountSync() {
        return this.getIntSync(AppSetting.ShowUserGuideCount, 0);
    }

    public setShowUserGuideCount(value: number) {
        this.setInt(AppSetting.ShowUserGuideCount, value);
        return this.commitChanges()
    }

    //最后一次弹出更新弹框的时间
    public getLastUpdateTime() {
        return this.getLong(AppSetting.LastUpdateTime, 0);
    }

    public setLastUpdateTime(value: number) {
        this.setLong(AppSetting.LastUpdateTime, value);
        return this.commitChanges();
    }

    /**
     * 是否忽略指定安装包
     *
     * @param key 安装包文件的MD5值
     * @return
     */
    public getIsIgnoreThisVersion(key: string) {
        return this.getBoolean(key, false);
    }

    public setIsIgnoreThisVersion(key: string, value: boolean) {
        this.setBoolean(key, value)
        return this.commitChanges()
    }

    //弹出软件更新弹框的最小时间间隔， （控制频繁<弹出弹框）
    // 即 newTime - getLastUpdateTime() < getUpdateDialogInterval()时，不弹出弹框
    public getUpdateDialogInterval() {
        let updateDialogInterval = this.getLong(AppSetting.KEY_UPDATEDIALOGINTERVAL, 1000 * 60 * 60 * 22)//22小时
        return updateDialogInterval;
    }

    public setUpdateDialogInterval(value: number) {
        this.setLong(AppSetting.KEY_UPDATEDIALOGINTERVAL, value);
        return this.commitChanges();
    }

    //软件更新定时器多久触发一次
    public getUpdateTimerPeriod() {
        return this.getLong(AppSetting.KEY_UPDATETIMERPERIOD, 1000 * 60 * 10)//10分钟
    }

    public setUpdateTimerPeriod(value: number) {
        this.setLong(AppSetting.KEY_UPDATETIMERPERIOD, value);
        return this.commitChanges()
    }

    //支持的解码类型
    public getDecodes() {
        return this.getStringSet(AppSetting.KEY_DECODES, null);
    }

    public setDecodes(value: string[]) {
        this.setStringSet(AppSetting.KEY_DECODES, value);
        return this.commitChanges()
    }

    //解码成功了，是否有提示音
    public getIsSound() {
        return this.getBoolean(AppSetting.KEY_SOUND, true);
    }

    public setIsSound(isSound: boolean) {
        this.setBoolean(AppSetting.KEY_SOUND, isSound);
        return this.commitChanges();
    }

    //解码成功了，是否震动
    public getIsShake() {
        return this.getBoolean(AppSetting.KEY_SHAKE, false);
    }

    public setIsShake(isShake: boolean) {
        this.setBoolean(AppSetting.KEY_SHAKE, isShake);
        return this.commitChanges();
    }

    //是否始终显示QC面板
    public getIsShowQC() {
        return this.getBoolean(AppSetting.KEY_SHOWQC, false);
    }

    public setIsShowQC(isShowQC: boolean) {
        this.setBoolean(AppSetting.KEY_SHOWQC, isShowQC);
        return this.commitChanges()
    }

    //发布渠道
    public getDistributionChannel() {
        return this.getString(AppSetting.KEY_DISTRIBUTIONCHSNNEL, "Xiaomi")//我也不知道这里为什么静态的xiaomi
    }

    public setDistributionChannel(value: string) {
        this.setString(AppSetting.KEY_DISTRIBUTIONCHSNNEL, value);
        return this.commitChanges()
    }

    /**是否支持固定对焦距离，仅有在相机支持手动控制，并且最近对焦距离合适的前提下，才允许，这是用来使用固定对焦距离功能的判断条件*/
    public getIsSupportFixedFocusDistance() {
        return this.getBoolean(AppSetting.KEY_IS_SUPPORT_FIXED_FOCUS_DISTANCE, false);
    }

    public setIsSupportFixedFocusDistance(isSupportFocusDistance: boolean) {
        this.setBoolean(AppSetting.KEY_IS_SUPPORT_FIXED_FOCUS_DISTANCE, isSupportFocusDistance);
        return this.commitChanges();
    }
    //是否手动设置CaptureRequest.Builder.set(CaptureRequest.LENS_FOCUS_DISTANCE, lensFocusDistanceOfDiopters)
    public getIsFixedFocusDistance() {
        //return getBoolean(KEY_FITFOCUSDISTANCE, getIsSupportFocusDistance());

        //目前改为不是固定焦距，好处是可以扫描屏幕，但可能会让使用者误解（我已经对焦清晰了，为什么无法识别，为了弥补这个问题，解码算法Dimensions使用了0.8跟1.2的模式）
        return this.getBoolean(AppSetting.KEY_IS_FIXED_FOCUS_DISTANCE, false);
    }

    public setIsFixedFocusDistance(isFitFocusDistance: boolean) {
        this.setBoolean(AppSetting.KEY_IS_FIXED_FOCUS_DISTANCE, isFitFocusDistance);
        return this.commitChanges()
    }

    //通过哪种方式计算 物长 / 物距，true则通过传感器尺寸计算，false则 物长/物距 = 108/83
    //当getIsManualSensor()为true时，getIsCalculatePhysicsWidthScale()可以为true也可以为false，
    //当getIsManualSensor()为false时，getIsFitFocusDistance()只能为false
    public getIsCalculatePhysicsWidthScale() {
        return this.getBoolean(AppSetting.KEY_CALCULATEPHYSICSWIDTHSCALE, false);
    }

    public setIsCalculatePhysicsWidthScale(isCalculatePhysicsWidthScale: boolean) {
        this.setBoolean(AppSetting.KEY_CALCULATEPHYSICSWIDTHSCALE, isCalculatePhysicsWidthScale);
        return this.commitChanges();
    }

    public getPreviewSizeIndex() {
        return this.getInt(AppSetting.PreviewSize, 0);
    }

    public setPreviewSizeIndex(value: number) {
        this.setInt(AppSetting.PreviewSize, value);
        return this.commitChanges()
    }

    public getIsApi2() {
        return this.getBoolean(AppSetting.KEY_API2, true);
    }

    public setIsApi2(isApi2: boolean) {
        this.setBoolean(AppSetting.KEY_API2, isApi2);
        return this.commitChanges()
    }

    public getLastRequirePermission(){
        return this.getLong(AppSetting.KEY_LAST_REQUIRE_PERMISSION,0);
    }
    public setLastRequirePermission(value: number){
        this.setLong(AppSetting.KEY_LAST_REQUIRE_PERMISSION,value);
        return this.commitChanges();
    }
    public getRequirePermissionCount(){
        return this.getInt(AppSetting.KEY_REQUIRE_PERMISSION_COUNT,0);
    }
    public setRequirePermissionCount(value: number){
        this.setInt(AppSetting.KEY_REQUIRE_PERMISSION_COUNT,value);
        return this.commitChanges()
    }
    //
    //    public Boolean getIsAutoConnectBluetooth() {
    //        //只有业务版才需要默认自动连接蓝牙，其他两个版本都不需要
    //        if (contains(KEY_AUTO_CONNECT_BLUETOOTH)) {
    //            return getBoolean(KEY_AUTO_CONNECT_BLUETOOTH, false);
    //        }
    //        return null;
    //    }
    //
    //    public boolean setIsAutoConnectBluetooth(boolean isAuto) {
    //        setBoolean(KEY_AUTO_CONNECT_BLUETOOTH, isAuto);
    //        return commitChanges();
    //    }

    public async getIsBluetoothShowOnMain() {
        if(await this.contains(AppSetting.KEY_BLUETOOTH_SHOW_ON_MAIN)) {
            return this.getBoolean(AppSetting.KEY_BLUETOOTH_SHOW_ON_MAIN, false)
        }
        return false
    }

    public setIsBluetoothShowOnMain(value: boolean) {
        this.setBoolean(AppSetting.KEY_BLUETOOTH_SHOW_ON_MAIN, value);
        return this.commitChanges();
    }
    public getIsQCMode() {
        return this.getBoolean(AppSetting.KEY_QC_MODE, false);
    }
    public setIsQCMode(isAuto: boolean) {
        this.setBoolean(AppSetting.KEY_QC_MODE, isAuto);
        return this.commitChanges();
    }
    public getIsBluetoothTestMode() {
        return this.getBoolean(AppSetting.KEY_BLUETOOTH_TEST_MODE_MODE, false);
        //        return getBoolean(KEY_BLUETOOTH_TEST_MODE_MODE, false);
    }
    public setIsBluetoothTestMode(isAuto: boolean) {
        this.setBoolean(AppSetting.KEY_BLUETOOTH_TEST_MODE_MODE, isAuto);
        return this.commitChanges()
    }

    public getIsBluetoothServer() {
        return this.getBoolean(AppSetting.KEY_IS_BLUETOOTH_SERVER,false);
    }

    public getLastBluetooth(){
        return this.getString(AppSetting.KEY_LAST_BLUETOOTH,null)
    }

    public setLastBluetooth(bluetooth: string){
        this.setString(AppSetting.KEY_LAST_BLUETOOTH,bluetooth);
        return this.commitChanges();
    }

    public getDPI(){
        return 812.79999;
    }

    public getBatteryWarning(){
        //        if(BuildConfig.DEBUG) {
        //            return getInt(KEY_BATTERY_WARNING, 99);
        //        }
        //        else{
        //            return getInt(KEY_BATTERY_WARNING,20);
        //        }
        return this.getInt(AppSetting.KEY_BATTERY_WARNING,20);
    }

    public setBatteryWarning(value: number){
        this.setInt(AppSetting.KEY_BATTERY_WARNING,value);
    }
}