/**
 * 蓝牙QC操作结果模型
 * 封装QC操作的执行结果、消息和分数
 */
export class BTQCResult{
  private isSuccess: boolean = false;
  private Message: string = "";
  private Score: number = 0;

  //获取操作成功状态
  public IsSuccess():boolean {
    return this.isSuccess;
  }

  //设置操作成功状态
  public setSuccess(success: boolean): void{
    this.isSuccess = success;
  }

  //获取结果信息
  public getMessage(): string {
    return this.Message;
  }

  //设置结果信息
  public setMessage(message:string) {
    this.Message = message;
  }

  //获取评分结果
  public getScore(): number {
    return this.Score;
  }

  //设置评分结果
  public setScore(score:number){
    this.Score = score;
  }
}