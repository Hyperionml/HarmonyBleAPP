//纯组件+animation实现,效果不好
//矩形扫描框特效
//ljj (此文件已不再使用)需自定义主题色、位置、大小
@Component
export struct ScanningRectEffect {
  private readonly SCAN_BOX_SIZE: number = 250;
  private readonly CORNER_SIZE: number = 20;
  private readonly CORNER_WIDTH: number = 4;

  @State scanLineUp: boolean = false;
  @State radarAngle: number = 0;

  aboutToAppear() {
    setTimeout(() => {
      this.scanLineUp = true;
    }, 50);

    setTimeout(() => {
      this.radarAngle = 360;
    }, 100);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 半透明背景遮罩
      Column() {
        // 上方遮罩
        Rect()
          .backgroundColor(Color.Black)
          .opacity(0.5)
          .width('100%')
          .layoutWeight(1) // 自动占满剩余空间

        // 中间行：左遮罩 + 透明区 + 右遮罩
        Row() {
          // 左侧遮罩
          Rect()
            .backgroundColor(Color.Black)
            .opacity(0.5)
            .layoutWeight(1) // 自动占满剩余空间
            .height(this.SCAN_BOX_SIZE)

          // 中间透明区域
          Rect()
            .width(this.SCAN_BOX_SIZE)
            .height(this.SCAN_BOX_SIZE)
            .opacity(0)
            .backgroundColor(Color.Transparent)

          // 右侧遮罩
          Rect()
            .backgroundColor(Color.Black)
            .opacity(0.5)
            .layoutWeight(1) // 自动占满剩余空间
            .height(this.SCAN_BOX_SIZE)
        }
        .width('100%')

        // 下方遮罩
        Rect()
          .backgroundColor(Color.Black)
          .opacity(0.5)
          .width('100%')
          .layoutWeight(1) // 自动占满剩余空间
      }
      .width('100%')
      .height('100%')

      // 扫描区域
      Stack() {
        // 雷达扫描效果(未实现)
        // Circle()
        //   .width(this.SCAN_BOX_SIZE)
        //   .height(this.SCAN_BOX_SIZE)
        //   .sweepGradient({
        //     center: [0.5, 0.5],
        //     start: 0,
        //     end: 360,
        //     colors: [
        //       ['#00000000', 0.0],   // 完全透明（开始）
        //       ['#FF00FF00', 0.1],   // 鲜绿色扫描线（最亮）
        //       ['#8000FF00', 0.3],   // 半透明绿色（拖尾）
        //       ['#00000000', 1.0]    // 完全透明（结束）
        //     ]
        //   })
        //   .opacity(0.8)
        //   .rotate({ angle: this.radarAngle, centerX: '50%', centerY: '50%' })
        //   .animation({
        //     duration: 4000,
        //     curve: Curve.Linear,
        //     iterations: -1,
        //     playMode: PlayMode.Normal
        //   })

        // 扫描框边框
        // Rect()
        //   .width(this.SCAN_BOX_SIZE)
        //   .height(this.SCAN_BOX_SIZE)
        //   .stroke(Color.Green)
        //   .strokeWidth(2)
        //   .fill(Color.Transparent)

        // 扫描框四个角
        // 左上角
        Stack() {
          Rect().width(this.CORNER_SIZE).height(this.CORNER_WIDTH).fill(Color.Green)
          Rect().width(this.CORNER_WIDTH).height(this.CORNER_SIZE).fill(Color.Green)
        }
        .align(Alignment.TopStart)
        .position({ x: -1, y: -1 })

        // 右上角
        Stack() {
          Rect().width(this.CORNER_SIZE).height(this.CORNER_WIDTH).fill(Color.Green)
          Rect().width(this.CORNER_WIDTH).height(this.CORNER_SIZE).fill(Color.Green)
            .position({ x: this.CORNER_SIZE - this.CORNER_WIDTH, y: 0 })
        }
        .align(Alignment.TopEnd)
        .position({ x: this.SCAN_BOX_SIZE - this.CORNER_SIZE + 1, y: -1 })

        // 左下角
        Stack() {
          Rect().width(this.CORNER_WIDTH).height(this.CORNER_SIZE).fill(Color.Green)
          Rect().width(this.CORNER_SIZE).height(this.CORNER_WIDTH).fill(Color.Green)
            .position({ x: 0, y: this.CORNER_SIZE - this.CORNER_WIDTH })
        }
        .align(Alignment.BottomStart)
        .position({ x: -1, y: this.SCAN_BOX_SIZE - this.CORNER_SIZE + 1 })

        // 右下角
        Stack() {
          Rect().width(this.CORNER_WIDTH).height(this.CORNER_SIZE).fill(Color.Green)
            .position({ x: this.CORNER_SIZE - this.CORNER_WIDTH, y: 0 })
          Rect().width(this.CORNER_SIZE).height(this.CORNER_WIDTH).fill(Color.Green)
            .position({ x: 0, y: this.CORNER_SIZE - this.CORNER_WIDTH })
        }
        .align(Alignment.BottomEnd)
        .position({
          x: this.SCAN_BOX_SIZE - this.CORNER_SIZE + 1,
          y: this.SCAN_BOX_SIZE - this.CORNER_SIZE + 1
        })

        // 扫描线
        Rect()
          .width('100%')
          .height(2)
          .linearGradient({
            angle: 90,
            colors: [
              ['#00FF0000', 0.0],
              ['#FF00FF00', 0.5],
              ['#00FF0000', 1.0]
            ]
          })
          .offset({ y: this.scanLineUp ? (this.SCAN_BOX_SIZE / 2) : (-this.SCAN_BOX_SIZE / 2) })
          .animation({
            duration: 2000,
            curve: Curve.EaseInOut,
            iterations: -1,
            playMode: PlayMode.Normal
          })
      }
      .width(this.SCAN_BOX_SIZE)
      .height(this.SCAN_BOX_SIZE)
      .clip(true)
    }
    .width('100%')
    .height('100%')
  }
}