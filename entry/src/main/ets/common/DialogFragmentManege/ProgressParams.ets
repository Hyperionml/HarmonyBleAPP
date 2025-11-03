export class ProgressParams {
    text: ResourceStr = '';
    value: number = 0;

    constructor(text: ResourceStr, value: number) {
        this.text = text;
        this.value = value;
    }
}