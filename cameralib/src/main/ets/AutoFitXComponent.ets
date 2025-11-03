//自定义XComponent控件，相当于安卓的AutoFitTextureView，todo 双路预览是否需要setAspectRatio等调整方案
@Component
export struct AutoFitXComponent {
  @State private ratioWidth: number = 0
  @State private ratioHeight: number = 0
  @State private calculatedWidth: number = 0
  @State private calculatedHeight: number = 0

  // XComponent控制器
  private xComponentController: XComponentController = new XComponentController()

  // 回调函数，用于获取XComponent控制器
  onXComponentReady?: (controller: XComponentController) => void

  build() {
    XComponent({
      id: 'autoFitXComponent',
      type: XComponentType.SURFACE,
      controller: this.xComponentController
    })
      .width(this.calculatedWidth || '100%')
      .height(this.calculatedHeight || '100%')
      .onLoad(() => {
        // XComponent加载完成后，传递控制器给外部
        this.onXComponentReady?.(this.xComponentController)
      })
  }

  // 获取SurfaceId
  getSurfaceId(): string {
    return this.xComponentController.getXComponentSurfaceId()
  }

  // 设置宽高比（对应原版的setAspectRatio）
  setAspectRatio(width: number, height: number): void {
    if (width < 0 || height < 0) {
      throw new Error("Size cannot be negative.")
    }
    this.ratioWidth = width
    this.ratioHeight = height
    this.calculateSize()
  }

  // 计算实际显示尺寸
  private calculateSize(): void {
    // 获取父容器尺寸（需要在aboutToAppear或onAreaChange中调用）
    // todo 这里简化处理，实际使用时需要获取真实的容器尺寸
    const containerWidth = 300  // 示例值
    const containerHeight = 400 // 示例值

    if (this.ratioWidth === 0 || this.ratioHeight === 0) {
      this.calculatedWidth = containerWidth
      this.calculatedHeight = containerHeight
      return
    }

    const viewRatio = containerWidth / containerHeight
    const previewRatio = this.ratioWidth / this.ratioHeight

    if (Math.abs(viewRatio - previewRatio) < 0.01) {
      this.calculatedWidth = containerWidth
      this.calculatedHeight = containerHeight
      return
    }

    if (containerWidth < containerHeight * this.ratioWidth / this.ratioHeight) {
      // 拉宽
      this.calculatedWidth = containerHeight * this.ratioWidth / this.ratioHeight
      this.calculatedHeight = containerHeight
    } else {
      // 拉高
      this.calculatedWidth = containerWidth
      this.calculatedHeight = containerWidth * this.ratioHeight / this.ratioWidth
    }
  }
}