export class AbsDeviceHub{
    protected is_Discovering: boolean = false
    protected devices: object[] = []

    public startDiscover(): void{
        if(this.is_Discovering){
            return
        }
        this.is_Discovering = true
    }

    public stopDiscover(){}

    public isDiscovering(): boolean{
        return this.is_Discovering;
    }
}