# IndexPage 重构指南

## 架构概述

基于 ArkUI 的 MVVM 架构和状态管理 V1 进行重构，将原有 1487 行的单文件拆分为多个独立组件。

## 架构分层

```
┌─────────────────────────────────────────┐
│           View Layer (UI)               │
│  ┌─────────────────────────────────┐   │
│  │  IndexPage (Entry Component)    │   │
│  │  - 生命周期管理                   │   │
│  │  - 业务逻辑调度                   │   │
│  │  - 事件处理                       │   │
│  └─────────────────────────────────┘   │
│         ▲                               │
│         │ @ObjectLink                   │
│         │                               │
│  ┌──────▼──────────────────────────┐   │
│  │  子组件 (Components)             │   │
│  │  - HeaderComponent               │   │
│  │  - PreviewComponent              │   │
│  │  - ScanBoxComponent              │   │
│  │  - ZoomSliderComponent           │   │
│  │  - ModeSwitchComponent           │   │
│  │  - BottomToolBarComponent        │   │
│  │  - LoadingComponent              │   │
│  │  - BluetoothIndicatorComponent   │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
                 │
                 │ 事件回调
                 ▼
┌─────────────────────────────────────────┐
│      ViewModel Layer (状态管理)         │
│  ┌─────────────────────────────────┐   │
│  │  IndexPageViewModel              │   │
│  │  - @Observed 状态管理            │   │
│  │  - UI 状态                       │   │
│  │  - 相机状态                       │   │
│  │  - 业务状态                       │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
                 │
                 │ 数据绑定
                 ▼
┌─────────────────────────────────────────┐
│      Business Layer (业务逻辑)          │
│  - DecodeBusiness (解码业务)            │
│  - WebDecodeService (网络解码)          │
│  - ProductManager (产品管理)            │
│  - EventManager (事件管理)              │
└─────────────────────────────────────────┘
```

## 文件结构

### 新增文件

```
entry/src/main/ets/
├── viewmodels/
│   └── IndexPageViewModel.ets          # 页面状态管理
├── components/
│   ├── HeaderComponent.ets             # 顶部导航栏
│   ├── PreviewComponent.ets            # 相机预览
│   ├── ScanBoxComponent.ets            # 扫描框
│   ├── ZoomSliderComponent.ets         # 缩放滑块
│   ├── ModeSwitchComponent.ets         # 模式切换
│   ├── BottomToolBarComponent.ets      # 底部工具栏
│   ├── LoadingComponent.ets            # 加载提示
│   └── BluetoothIndicatorComponent.ets # 蓝牙指示器
└── pages/
    ├── IndexPage.ets                   # 原文件（保留）
    └── IndexPage_Refactored_Example.ets # 重构示例
```

## 状态管理 V1 使用说明

### 1. ViewModel 定义

```typescript
@Observed
export class IndexPageViewModel {
  // UI状态
  public themeColor: ResourceColor = $r('app.color.ThemeColorBlue');
  public isLogin: boolean = false;
  
  // 状态更新方法
  updateThemeColor(color: ResourceColor): void {
    this.themeColor = color;
  }
}
```

### 2. Page 中使用 ViewModel

```typescript
@Entry
@Component
struct IndexPage {
  // 使用 @State 装饰 ViewModel 实例
  @State viewModel: IndexPageViewModel = new IndexPageViewModel();
  
  build() {
    Stack() {
      // 传递给子组件
      HeaderComponent({ viewModel: this.viewModel })
    }
  }
}
```

### 3. 子组件中绑定 ViewModel

```typescript
@Component
export struct HeaderComponent {
  // 使用 @ObjectLink 绑定父组件的 ViewModel
  @ObjectLink viewModel: IndexPageViewModel;
  
  build() {
    Row() {
      Image($r('app.media.icon'))
        .fillColor(this.viewModel.themeColor) // 自动响应式更新
    }
  }
}
```

## 组件拆分原则

### 1. 单一职责

每个组件只负责一个功能模块：
- `HeaderComponent`: 只负责顶部导航栏
- `ZoomSliderComponent`: 只负责缩放控制
- `PreviewComponent`: 只负责相机预览

### 2. 状态提升

所有状态统一管理在 `IndexPageViewModel` 中：
- UI 状态：主题色、加载状态、菜单显示等
- 相机状态：缩放值、闪光灯、聚焦等
- 业务状态：登录状态、蓝牙连接等

### 3. 事件回调

组件通过回调函数与父组件通信：

```typescript
@Component
export struct ZoomSliderComponent {
  @ObjectLink viewModel: IndexPageViewModel;
  onZoomChange?: (value: number) => void; // 回调函数
  
  build() {
    Slider({ value: this.viewModel.currentZoomValue })
      .onChange((value: number) => {
        this.viewModel.updateZoomValue(value);
        this.onZoomChange?.(value); // 触发回调
      });
  }
}
```

### 4. 业务逻辑隔离

业务逻辑保留在 Page 层：
- 相机控制
- 网络请求
- 事件监听
- 生命周期管理

## 重构步骤

### 步骤 1: 创建 ViewModel

1. 将所有 `@State` 变量迁移到 `IndexPageViewModel`
2. 添加状态更新方法
3. 使用 `@Observed` 装饰类

### 步骤 2: 拆分组件

1. 识别独立的 UI 模块
2. 创建独立的 `@Component`
3. 使用 `@ObjectLink` 绑定 ViewModel
4. 添加回调函数接口

### 步骤 3: 重构 Page

1. 将 ViewModel 改为 `@State`
2. 替换 `@Builder` 为独立组件
3. 实现事件处理方法
4. 保留业务逻辑

### 步骤 4: 测试验证

1. 验证状态响应式更新
2. 验证事件回调正常
3. 验证业务逻辑不受影响

## 优势对比

### 原架构问题

❌ 1487 行代码集中在一个文件
❌ 40+ 个 @State 变量混杂
❌ UI 和业务逻辑耦合
❌ 难以维护和测试
❌ 代码复用性差

### 新架构优势

✅ 文件拆分，职责清晰
✅ 状态统一管理
✅ UI 组件可复用
✅ 易于维护和测试
✅ 符合 MVVM 架构模式

## 状态管理对比

### V1 vs V2

**状态管理 V1（当前使用）**
- 使用 `@Observed` + `@ObjectLink`
- 轻量级，性能好
- 适合中小型应用
- 学习成本低

**状态管理 V2（可选升级）**
- 使用 `@ObservedV2` + `@Trace`
- 更细粒度的更新控制
- 适合大型复杂应用
- 性能更优

建议：当前项目使用 V1 即可满足需求，后续如有性能瓶颈可考虑升级 V2。

## 迁移注意事项

### 1. 注释保留

迁移时保留原有注释，确保业务逻辑清晰。

### 2. 事件处理

事件处理逻辑保留在 Page 层，组件只负责触发回调。

### 3. 生命周期

生命周期方法保留在 Page 层，不下沉到子组件。

### 4. 依赖注入

业务对象（如 `DecodeBusiness`）通过构造函数或方法注入，不在组件中创建。

### 5. 测试建议

- 单元测试：测试 ViewModel 的状态更新方法
- 组件测试：测试组件的 UI 渲染和事件触发
- 集成测试：测试 Page 层的业务逻辑

## 示例代码

完整示例见 `IndexPage_Refactored_Example.ets`

## 后续优化方向

1. **引入路由状态管理**：使用 `Router` 统一管理页面跳转
2. **抽离公共样式**：创建 `Styles` 工具类
3. **组件库封装**：将通用组件封装为可复用的组件库
4. **性能优化**：使用懒加载、虚拟滚动等技术
5. **单元测试**：为 ViewModel 和组件添加单元测试

## 参考资料

- [ArkUI 状态管理概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-state-management-overview-0000001774121202)
- [状态管理 V1](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-observed-and-objectlink-0000001774280886)
- [自定义组件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-create-custom-components-0000001774120810)
