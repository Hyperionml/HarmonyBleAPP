export interface IProductManageListener {
    onDestroySuccess(code: string[]): void

    onDestroyNOLogin(): void

    onDestroyPopdown(): void

    onAppSuccess(code: string): void

    onSecrecySuccess(code:string): void
}