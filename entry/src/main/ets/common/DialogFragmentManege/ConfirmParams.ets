export class ConfirmParams {
    text: ResourceStr = ''
    left: ResourceStr = ''
    right: ResourceStr = ''

    leftFun: () => void
    rightFun: () => void

    constructor(text: ResourceStr, left: ResourceStr, right: ResourceStr, leftFun: () => void, rightFun: () => void) {
        this.text = text
        this.left = left
        this.right = right
        this.leftFun = leftFun
        this.rightFun = rightFun
    }
}