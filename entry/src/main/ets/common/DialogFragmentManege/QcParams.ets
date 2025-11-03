export class QcParams {
    quality: string = ''
    errorCountTip: string = ''
    deepTip: string = ''

    constructor(quality: string, errorCountTip: string, deepTip: string) {
        this.quality = quality;
        this.errorCountTip = errorCountTip;
        this.deepTip = deepTip
    }
}