import BuildProfile from "BuildProfile";

//产品类型枚举
export enum ProductType {
  // 面向所有人的通用版本
  Public = "Public",
  // 内部生成检测用的版本（QC版）
  Secrecy = "Secrecy",
  // 销毁码用的版本
  Destroy = "Destroy",
  // 预览版
  Preview = "Preview",
  // 普通版
  Normal = "Normal"
}


//获取当前产品类型
export function getCurrentProductType(): ProductType {
  // 如果是Destroy版，返回Destroy
  if (BuildProfile.APPLICATION_ID.includes("destroy")) {
    return ProductType.Destroy;
  }
  // 如果是QC版，返回Secrecy，否则返回Normal
  return BuildProfile.APPLICATION_ID.includes("secrecy")
    ? ProductType.Secrecy
    : ProductType.Normal;
}


//构建登录接口完整URL
export function buildLoginUrl(): string {
  const productType = getCurrentProductType();
  // 根据产品类型选择对应的接口路径，拼接完整URL
  let loginPath: string;
  switch (productType) {
    case ProductType.Secrecy:
      loginPath = BuildProfile.QC_LOGIN;
      break;
    case ProductType.Destroy:
    case ProductType.Normal:
    default:
      loginPath = BuildProfile.USER_LOGIN;
      break;
  }

  return BuildProfile.PRODUCT_SERVER + loginPath;
}

