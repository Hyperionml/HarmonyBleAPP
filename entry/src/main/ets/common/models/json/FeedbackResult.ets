export class FeedbackResult{
    // 请求是否成功
    IsSuccess: boolean | null = null
    // 请求失败消息
    ErrorMessage: string | null = null
    //图片url
    Url: string | null = null

    public toString() {
        return "FeedbackResult{" +
            "isSuccess=" + this.IsSuccess +
            ", errorMessage='" + this.ErrorMessage + '\'' +
            ", url='" + this.Url + '\'' +
            '}';
    }
}