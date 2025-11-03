import { bundleManager } from '@kit.AbilityKit';

export class GlobalContext {
  private static gScreenOn: boolean = false;
  private static gIsForeground: boolean = false;
  private static gContext: Context | null = null;
  private static gStartPackage: string | null = null;
  private static uiThreadId: number = -1;

  public static getContext(): Context | null {
    return GlobalContext.gContext;
  }

  public static setContext(context: Context): void {
    GlobalContext.gContext = context;
  }

  public static getPackageName(context: Context): string | null {
    if (GlobalContext.gStartPackage !== null) {
      return GlobalContext.gStartPackage;
    }
    return GlobalContext.loadPackageName();
  }

  private static loadPackageName(): string | null {
    if (GlobalContext.gStartPackage === null) {
        const bundleInfo = bundleManager.getBundleInfoSync(null, 0);
        GlobalContext.gStartPackage = bundleInfo.name;
    }
    return GlobalContext.gStartPackage;
  }

  public static setIsForeground(value: boolean): void {
    GlobalContext.gIsForeground = value;
  }

  public static setScreenOn(value: boolean): void {
    GlobalContext.gScreenOn = value;
  }

  public static getScreenOn(): boolean {
    return GlobalContext.gScreenOn;
  }

  public static getVisible(): boolean {
    return GlobalContext.gIsForeground && GlobalContext.gScreenOn;
  }
}