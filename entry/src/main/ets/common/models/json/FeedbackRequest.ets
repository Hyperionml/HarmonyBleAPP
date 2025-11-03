export class FeedbackRequest{
    //手机IMEI
    IMEI: string | null = null
    //应用包名
    PackageName: string | null = null
    //平台
    SystemName: string | null = null
    //系统版本号
    SystemVersion: string | null = null
    //版本号
    VersionCode: number | null = null
    //版本名
    VersionName: string | null = null
    //多语言
    Language: string | null = null
    //手机厂商
    DeviceBrand: string | null = null
    //Android 设备的CPU类型(通常称为”ABIs”)
    ABIs: string | null = null
    //反馈人电话号码
    Phone: string | null = null
    //反馈时间
    Date: string | null = null
    //选择多选框的反馈问题
    ChkQuestions: string[] | null = null
    //反馈图片url
    imageUrl: null | string = null
    //写在文本框的反馈问题
    TvQuestion: string | null = null
    //用户手机默认的语言(非程序设置语言)
    DefaultLanguage: string | null = null
    //用户手机区域
    DefaultCountry: string | null = null

    public toString() {
        return "FeedbackRequest{" +
            "IMEI='" + this.IMEI + '\'' +
            ", PackageName='" + this.PackageName + '\'' +
            ", SystemName='" + this.SystemName + '\'' +
            ", SystemVersion='" + this.SystemVersion + '\'' +
            ", VersionCode=" + this.VersionCode +
            ", VersionName='" + this.VersionName + '\'' +
            ", Language='" + this.Language + '\'' +
            ", DeviceBrand='" + this.DeviceBrand + '\'' +
            ", ABIs='" + this.ABIs + '\'' +
            ", Phone='" + this.Phone + '\'' +
            ", Date='" + this.Date + '\'' +
            ", ChkQuestions=" + this.ChkQuestions +
            ", TvQuestion='" + this.TvQuestion + '\'' +
            ", DefaultLanguage='" + this.DefaultLanguage + '\'' +
            ", DefaultCountry='" + this.DefaultCountry + '\'' +
            ", imageUrl='" + this.imageUrl + '\'' +
            '}';
    }
}