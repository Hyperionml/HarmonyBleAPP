export interface IDestroyFragmentListener{
    onEditSuccess(code: string[]): void

    onNoLogin(): void

    onPopdown(): void
}