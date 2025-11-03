//done 需自定义主题色(已完成)、位置(已完成自定义Y轴位置)、大小（已实现用百分比,安卓为40%）
import { image } from "@kit.ImageKit";
import { EventManager, Level } from "common";
import { AppEvent } from "../../common/event/AppEvent";
import { AppEventType } from "../../common/event/AppEventType";
import BuildProfile from "BuildProfile";

/**
 * 相当于安卓ScanShapeView
 * ScanningEffectCanvas不再使用，已拆分成ScanningEffectCanvasStatic与ScanningEffectCanvasDynamic
 * todo 用Canvas可能会有性能问题，若出现性能问题只能改用底层C++实现
 *底层：相机预览
 *中层：动态 Canvas（只画扫描线与雷达）
 *顶层：静态 Canvas（半透明遮罩+六边形镂空+四角）
 * */
@Component
struct ScanningEffectCanvas {
  private readonly SCAN_BOX_SIZE: number = 250;
  private readonly CORNER_SIZE: number = 20;
  private readonly CORNER_WIDTH: number = 4;

  @State scanLinePosition: number = 0;
  @State radarAngle: number = 0;
  @State canvasWidth: number = 0;
  @State canvasHeight: number = 0;

  private renderingContext: CanvasRenderingContext2D = new CanvasRenderingContext2D();
  private scanIntervalId: number = -1;
  private radarIntervalId: number = -1;

  aboutToAppear() {
    // 60fps 左右的重绘定时器
    this.scanIntervalId = setInterval(() => {
      this.scanLinePosition += 2;
      if (this.scanLinePosition > this.SCAN_BOX_SIZE) {
        this.scanLinePosition = 0;
      }
      this.drawCanvas();
    }, 16);

    // 雷达角速度
    this.radarIntervalId = setInterval(() => {
      this.radarAngle += 10;//角速度改这里
      if (this.radarAngle >= 360) {
        this.radarAngle = 0;
      }
    }, 50);
  }

  aboutToDisappear() {
    if (this.scanIntervalId !== -1) {
      clearInterval(this.scanIntervalId);
      this.scanIntervalId = -1;
    }
    if (this.radarIntervalId !== -1) {
      clearInterval(this.radarIntervalId);
      this.radarIntervalId = -1;
    }
  }

  private drawCanvas() {
    if (!this.renderingContext || this.canvasWidth === 0 || this.canvasHeight === 0) {
      return;
    }
    const ctx = this.renderingContext;

    // 清空画布
    ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

    // 计算扫描框位置（居中）
    const centerX = this.canvasWidth / 2;
    const centerY = this.canvasHeight / 2;
    const scanBoxX = centerX - this.SCAN_BOX_SIZE / 2;
    const scanBoxY = centerY - this.SCAN_BOX_SIZE / 2;

    // 遮罩（整屏半透明）+ 清掉中间扫描框区域（镂空）
    this.drawMask(ctx, scanBoxX, scanBoxY);
    // 四角
    this.drawCorners(ctx, scanBoxX, scanBoxY);
    // 扫描线
    this.drawScanLine(ctx, scanBoxX, scanBoxY);


    // 遮罩
    this.drawMask_Hexagon(ctx, scanBoxX, scanBoxY)
    // 六边形雷达
    this.drawRadarEffect_Hexagon(ctx, centerX, centerY);
    // 圆形雷达
    // this.drawRadarEffect_Circle(ctx, centerX, centerY);
  }

  /**
   * 矩形遮罩
   * */
  private drawMask(ctx: CanvasRenderingContext2D, scanBoxX: number, scanBoxY: number) {
    // 画整屏半透明黑
    ctx.fillStyle = 'rgba(0, 0, 0, 0.5)';
    ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight);
    // 清掉扫描区域形成镂空（直接 clearRect，兼容性优于 destination-out）
    ctx.clearRect(scanBoxX, scanBoxY, this.SCAN_BOX_SIZE, this.SCAN_BOX_SIZE);
  }

  /**
   * 矩形四角
   * */
  private drawCorners(ctx: CanvasRenderingContext2D, scanBoxX: number, scanBoxY: number) {
    ctx.strokeStyle = '#00FF00';
    ctx.lineWidth = this.CORNER_WIDTH;
    ctx.lineCap = 'square';

    // 左上
    ctx.beginPath();
    ctx.moveTo(scanBoxX, scanBoxY + this.CORNER_SIZE);
    ctx.lineTo(scanBoxX, scanBoxY);
    ctx.lineTo(scanBoxX + this.CORNER_SIZE, scanBoxY);
    ctx.stroke();

    // 右上
    ctx.beginPath();
    ctx.moveTo(scanBoxX + this.SCAN_BOX_SIZE - this.CORNER_SIZE, scanBoxY);
    ctx.lineTo(scanBoxX + this.SCAN_BOX_SIZE, scanBoxY);
    ctx.lineTo(scanBoxX + this.SCAN_BOX_SIZE, scanBoxY + this.CORNER_SIZE);
    ctx.stroke();

    // 左下
    ctx.beginPath();
    ctx.moveTo(scanBoxX, scanBoxY + this.SCAN_BOX_SIZE - this.CORNER_SIZE);
    ctx.lineTo(scanBoxX, scanBoxY + this.SCAN_BOX_SIZE);
    ctx.lineTo(scanBoxX + this.CORNER_SIZE, scanBoxY + this.SCAN_BOX_SIZE);
    ctx.stroke();

    // 右下
    ctx.beginPath();
    ctx.moveTo(scanBoxX + this.SCAN_BOX_SIZE - this.CORNER_SIZE, scanBoxY + this.SCAN_BOX_SIZE);
    ctx.lineTo(scanBoxX + this.SCAN_BOX_SIZE, scanBoxY + this.SCAN_BOX_SIZE);
    ctx.lineTo(scanBoxX + this.SCAN_BOX_SIZE, scanBoxY + this.SCAN_BOX_SIZE - this.CORNER_SIZE);
    ctx.stroke();
  }

  /**
   * 矩形扫描框的扫描线
   * */
  private drawScanLine(ctx: CanvasRenderingContext2D, scanBoxX: number, scanBoxY: number) {
    const scanLineY = scanBoxY + this.scanLinePosition;
    const gradient = ctx.createLinearGradient(scanBoxX, scanLineY, scanBoxX + this.SCAN_BOX_SIZE, scanLineY);
    gradient.addColorStop(0, 'rgba(0, 255, 0, 0)');
    gradient.addColorStop(0.5, 'rgba(0, 255, 0, 1)');
    gradient.addColorStop(1, 'rgba(0, 255, 0, 0)');

    ctx.fillStyle = gradient;
    ctx.fillRect(scanBoxX, scanLineY, this.SCAN_BOX_SIZE, 2);
  }

  // 圆形雷达渐变
  private drawRadarEffect_Circle(ctx: CanvasRenderingContext2D, centerX: number, centerY: number) {
    const radius = this.SCAN_BOX_SIZE / 2;
    ctx.save();
    const gradient = ctx.createConicGradient(this.radarAngle * Math.PI / 180, centerX, centerY);
    gradient.addColorStop(0, 'rgba(0, 255, 0, 0)');
    gradient.addColorStop(0.1, 'rgba(0, 255, 0, 0.8)');
    gradient.addColorStop(0.3, 'rgba(0, 255, 0, 0.3)');
    gradient.addColorStop(1, 'rgba(0, 255, 0, 0)');
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
    ctx.fillStyle = gradient;
    ctx.fill();
    ctx.restore();
  }

  /**
   * 六边形遮罩
   * */
  private drawMask_Hexagon(ctx: CanvasRenderingContext2D, scanBoxX: number, scanBoxY: number) {
    const centerX = scanBoxX + this.SCAN_BOX_SIZE / 2;
    const centerY = scanBoxY + this.SCAN_BOX_SIZE / 2;
    const r = this.SCAN_BOX_SIZE / Math.sqrt(3); // 与六边形雷达半径一致

    ctx.save();
    // 先铺半透明遮罩
    ctx.fillStyle = 'rgba(0, 0, 0, 0.5)';
    ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight);

    // 使用 clip + clearRect 做六边形镂空（尖顶朝上）
    ctx.beginPath();
    for (let i = 0; i < 6; i++) {
      const angle = Math.PI / 6 + Math.PI / 3 * i;
      const x = centerX + r * Math.cos(angle);
      const y = centerY + r * Math.sin(angle);
      if (i === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    }
    ctx.closePath();
    ctx.clip(); // 仅影响六边形区域
    ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight); // 清出透明孔
    ctx.restore();
  }

  /**
   * 六边形雷达渐变
   * */
  private drawRadarEffect_Hexagon(ctx: CanvasRenderingContext2D, centerX: number, centerY: number) {
    //若想让六边形在垂直方向也更贴合方形区域：用 const r = this.SCAN_BOX_SIZE / Math.sqrt(3);
    //const r = this.SCAN_BOX_SIZE / 2; // 六边形外接圆半径（与原圆形等宽）
    const r = this.SCAN_BOX_SIZE / Math.sqrt(3);
    ctx.save();

    const gradient = ctx.createConicGradient(this.radarAngle * Math.PI / 180, centerX, centerY);
    gradient.addColorStop(0, 'rgba(0, 255, 0, 0)');
    gradient.addColorStop(0.1, 'rgba(0, 255, 0, 0.8)');
    gradient.addColorStop(0.3, 'rgba(0, 255, 0, 0.3)');
    gradient.addColorStop(1, 'rgba(0, 255, 0, 0)');

    // 正六边形（平顶），若要尖顶可在 angle 上加 Math.PI / 6 偏移
    ctx.beginPath();
    for (let i = 0; i < 6; i++) {
      //若想“尖顶”朝上：把 const angle = Math.PI / 3 * i; 改为 const angle = Math.PI / 6 + Math.PI / 3 * i;
      //const angle = Math.PI / 3 * i; // 0, 60, 120, ...
      const angle = Math.PI / 6 + Math.PI / 3 * i;
      const x = centerX + r * Math.cos(angle);
      const y = centerY + r * Math.sin(angle);
      if (i === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    }
    ctx.closePath();
    ctx.fillStyle = gradient;
    ctx.fill();

    ctx.restore();
  }

  build() {
    Canvas(this.renderingContext)
      .width('100%')
      .height('100%')
      .onReady(() => {
        this.drawCanvas();
      })
      .onAreaChange((_, newValue: Area) => {
        this.canvasWidth = newValue.width as number;
        this.canvasHeight = newValue.height as number;
        this.drawCanvas();
      })
  }
}

/**
 * 扫描框信息
 * */
export class ScanBoxInfo{
  private _width: number;
  private _height: number;
  private _top: number;
  private _left: number;
  private _canvasWidth: number;
  private _canvasHeight: number;

  constructor(width: number, height: number, top: number, left: number, canvasWidth: number = 0, canvasHeight: number = 0) {
    this._width = width;
    this._height = height;
    this._top = top;
    this._left = left;
    this._canvasWidth = canvasWidth;
    this._canvasHeight = canvasHeight;
  }

  get Width(): number { return this._width; }
  set Width(value: number) { this._width = value; }

  get Height(): number { return this._height; }
  set Height(value: number) { this._height = value; }

  get Top(): number { return this._top; }
  set Top(value: number) { this._top = value; }

  get Left(): number { return this._left; }
  set Left(value: number) { this._left = value; }

  get CanvasWidth(): number { return this._canvasWidth; }
  set CanvasWidth(value: number) { this._canvasWidth = value; }

  get CanvasHeight(): number { return this._canvasHeight; }
  set CanvasHeight(value: number) { this._canvasHeight = value; }
}

/**
 * 避开扫描框的安全区域
 * */
export class ScanBoxSafeArea {
  private static instance: ScanBoxSafeArea;

  public Top: image.Region;
  public Bottom: image.Region;
  public Left: image.Region;
  public Right: image.Region;

  private constructor(top: image.Region, bottom: image.Region, left: image.Region, right: image.Region) {
    this.Top = top;
    this.Bottom = bottom;
    this.Left = left;
    this.Right = right;
  }

  public static init(top: image.Region, bottom: image.Region, left: image.Region, right: image.Region) {
    ScanBoxSafeArea.instance = new ScanBoxSafeArea(top, bottom, left, right);
  }

  public static getInstance(): ScanBoxSafeArea {
    if (!ScanBoxSafeArea.instance) {
      throw new Error('ScanBoxSafeArea not initialized');
    }
    return ScanBoxSafeArea.instance;
  }
}

/**
 * 静态效果，矩形/六边形扫描框，遮罩层
 * */
@Component
export struct ScanningEffectCanvasStatic {
  //@Prop => @Param ,@Watch => @Monitor('isQT','themeColor')
  @Prop @Watch('drawCanvas') isQT: boolean = true;//@Watch('drawCanvas')
  @Prop @Watch('drawCanvas') themeColor: ResourceColor = '#007AFF';//@Watch('drawCanvas')
  @Prop centerY :number = 0.4;//百分比

  private SCAN_BOX_SIZE: number = 250;
  private SCAN_BOX_TOP: number = 250;
  private readonly CORNER_SIZE: number = 20;
  private readonly CORNER_WIDTH: number = 4;

  //@State => @Local
  @State scanLinePosition: number = 0;
  @State radarAngle: number = 0;
  @State canvasWidth: number = 0;
  @State canvasHeight: number = 0;

  //@Event scanBoxInfo: (val: ScanBoxInfo) => void;

  private renderingContext: CanvasRenderingContext2D = new CanvasRenderingContext2D();

  aboutToAppear() {
    //若使用单位px要转换
    //this.SCAN_BOX_SIZE = px2vp(this.scanBoxSize)
    //this.SCAN_BOX_SIZE = this.scanBoxSize
  }

  //@Monitor('isQT','themeColor')
  private drawCanvas() {
    if (!this.renderingContext || !this.canvasWidth || !this.canvasHeight) return;
    const ctx = this.renderingContext;

    const centerX = this.canvasWidth / 2;
    //const centerY = this.canvasHeight / 2;
    const centerY = this.SCAN_BOX_TOP;
    const scanBoxX = centerX - this.SCAN_BOX_SIZE / 2;
    const scanBoxY = centerY - this.SCAN_BOX_SIZE / 2;

    ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

   if(this.isQT){
      // 六边形遮罩
      this.drawMask_Hexagon(ctx, scanBoxX, scanBoxY);
      // 六边形边框
      this.drawHexagonBorder(ctx, centerX, centerY);
    }
    else {
      // 遮罩（整屏半透明）+ 清掉中间扫描框区域（镂空）
      this.drawMask(ctx, scanBoxX, scanBoxY);
      // 四角
      this.drawCorners(ctx, scanBoxX, scanBoxY);
    }
  }

  /**
   * 矩形遮罩
   * */
  private drawMask(ctx: CanvasRenderingContext2D, scanBoxX: number, scanBoxY: number) {
    // 画整屏半透明黑
    ctx.fillStyle = 'rgba(0, 0, 0, 0.5)';
    ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight);
    // 清掉扫描区域形成镂空（直接 clearRect，兼容性优于 destination-out）
    ctx.clearRect(scanBoxX, scanBoxY, this.SCAN_BOX_SIZE, this.SCAN_BOX_SIZE);
  }

  /**
   * 六边形遮罩
   * */
  private drawMask_Hexagon(ctx: CanvasRenderingContext2D, scanBoxX: number, scanBoxY: number) {
    const centerX = scanBoxX + this.SCAN_BOX_SIZE / 2;
    const centerY = scanBoxY + this.SCAN_BOX_SIZE / 2;
    const r = this.SCAN_BOX_SIZE / Math.sqrt(3);

    ctx.save();
    ctx.fillStyle = 'rgba(0, 0, 0, 0.5)';
    ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight);

    ctx.beginPath();
    for (let i = 0; i < 6; i++) {
      const a = Math.PI / 6 + Math.PI / 3 * i;
      const x = centerX + r * Math.cos(a);
      const y = centerY + r * Math.sin(a);
      i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
    }
    ctx.closePath();
    ctx.clip();
    ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    ctx.restore();
  }

  /**
   * 矩形四角
   * */
  private drawCorners(ctx: CanvasRenderingContext2D, scanBoxX: number, scanBoxY: number) {
    ctx.strokeStyle = this.themeColor.toString();
    ctx.lineWidth = this.CORNER_WIDTH;
    ctx.lineCap = 'square';

    // 左上
    ctx.beginPath();
    ctx.moveTo(scanBoxX, scanBoxY + this.CORNER_SIZE);
    ctx.lineTo(scanBoxX, scanBoxY);
    ctx.lineTo(scanBoxX + this.CORNER_SIZE, scanBoxY);
    ctx.stroke();

    // 右上
    ctx.beginPath();
    ctx.moveTo(scanBoxX + this.SCAN_BOX_SIZE - this.CORNER_SIZE, scanBoxY);
    ctx.lineTo(scanBoxX + this.SCAN_BOX_SIZE, scanBoxY);
    ctx.lineTo(scanBoxX + this.SCAN_BOX_SIZE, scanBoxY + this.CORNER_SIZE);
    ctx.stroke();

    // 左下
    ctx.beginPath();
    ctx.moveTo(scanBoxX, scanBoxY + this.SCAN_BOX_SIZE - this.CORNER_SIZE);
    ctx.lineTo(scanBoxX, scanBoxY + this.SCAN_BOX_SIZE);
    ctx.lineTo(scanBoxX + this.CORNER_SIZE, scanBoxY + this.SCAN_BOX_SIZE);
    ctx.stroke();

    // 右下
    ctx.beginPath();
    ctx.moveTo(scanBoxX + this.SCAN_BOX_SIZE - this.CORNER_SIZE, scanBoxY + this.SCAN_BOX_SIZE);
    ctx.lineTo(scanBoxX + this.SCAN_BOX_SIZE, scanBoxY + this.SCAN_BOX_SIZE);
    ctx.lineTo(scanBoxX + this.SCAN_BOX_SIZE, scanBoxY + this.SCAN_BOX_SIZE - this.CORNER_SIZE);
    ctx.stroke();
  }

  /**
   * 六边形边框
   */
  private drawHexagonBorder(ctx: CanvasRenderingContext2D, centerX: number, centerY: number) {
    const r = this.SCAN_BOX_SIZE / Math.sqrt(3);
    ctx.save();
    ctx.strokeStyle = this.themeColor.toString();
    ctx.lineWidth = this.CORNER_WIDTH;
    ctx.lineJoin = 'round';
    ctx.beginPath();
    for (let i = 0; i < 6; i++) {
      const a = Math.PI / 6 + Math.PI / 3 * i;
      const x = centerX + r * Math.cos(a);
      const y = centerY + r * Math.sin(a);
      i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
    }
    ctx.closePath();
    ctx.stroke();
    ctx.restore();
  }


  private buildScanBox(canvasWidth:number,canvasHeight:number){
    let size = computeRecommendedScanSide(canvasWidth,canvasHeight)
    let scanBoxTop = canvasHeight * this.centerY; //40%
    let scanBoxLet = (canvasWidth - size) / 2;

    this.canvasWidth = canvasWidth;
    this.canvasHeight = canvasHeight;
    this.SCAN_BOX_SIZE = size;
    this.SCAN_BOX_TOP = scanBoxTop; //40%
    this.drawCanvas();

    let pxSize = Math.round(vp2px(size))
    let crop: image.Region = {
      x: Math.round(vp2px(scanBoxLet)),
      y: Math.round(vp2px(scanBoxTop - size / 2)),
      size: {
        width: pxSize,
        height: pxSize
      }
    };

    //获取避开扫描框的安全区域
    computeScanBoxSafeArea(canvasWidth,canvasHeight,scanBoxTop,size);

    EventManager.sync('ScanningEffectCanvas',new AppEvent(AppEventType.ScanBoxInitted,Level.High,crop))
    EventManager.sync('ScanningEffectCanvas',new AppEvent(AppEventType.ScanBoxSafeArea,Level.High,ScanBoxSafeArea.getInstance()))
  }

  build() {
    Canvas(this.renderingContext)
      .width('100%')
      .height('100%')
      .onReady(() => this.drawCanvas())
      .onAreaChange((_, area: Area) => {
        let canvasWidth = area.width as number;
        let canvasHeight = area.height as number;
        this.buildScanBox(canvasWidth,canvasHeight);
      })
  }
}

/**
 * 动态效果，扫描线，雷达特效
 * */
@Component
export struct ScanningEffectCanvasDynamic {
  //@Prop => @Param ,@Watch => @Monitor('isQT','themeColor')
  @Prop @Watch('onIsQTChanged')isQT: boolean = true;//@Watch('onIsQTChanged')
  @Prop @Watch('onThemeColorChange') themeColor: ResourceColor = '#007AFF';//@Watch('onThemeColorChange')
  @Prop centerY :number = 0.4;//百分比

  private SCAN_BOX_SIZE: number = 250;
  private SCAN_BOX_TOP: number = 250;
  private readonly CORNER_SIZE: number = 20;
  private readonly CORNER_WIDTH: number = 4;

  //@State => @Local
  @State scanLinePosition: number = 0;
  @State radarAngle: number = 0;
  @State canvasWidth: number = 0;
  @State canvasHeight: number = 0;

  //@Event scanBoxInfo: (val: ScanBoxInfo) => void;

  private renderingContext: CanvasRenderingContext2D = new CanvasRenderingContext2D();
  private scanIntervalId: number = -1;
  private radarIntervalId: number = -1;

  aboutToAppear() {
    //若使用单位px要转换
    //this.SCAN_BOX_SIZE = px2vp(this.scanBoxSize)
    //this.SCAN_BOX_SIZE = this.scanBoxSize
    // 60fps 左右的重绘定时器
    this.scanIntervalId = setInterval(() => {
      this.scanLinePosition = (this.scanLinePosition + 2) % this.SCAN_BOX_SIZE;
      this.drawCanvas();
    }, 16);

    // 雷达角速度
    this.onIsQTChanged()
  }

  aboutToDisappear() {
    if (this.scanIntervalId !== -1) { clearInterval(this.scanIntervalId); this.scanIntervalId = -1; }
    if (this.radarIntervalId !== -1) { clearInterval(this.radarIntervalId); this.radarIntervalId = -1; }
  }

  /**
   * 监听isQT
   * */
  //@Monitor('isQT')
  onIsQTChanged() {
    if (this.isQT) {
      if (this.radarIntervalId === -1) {
        // 雷达角速度
        this.radarIntervalId = setInterval(() => {
          this.radarAngle = (this.radarAngle + 10) % 360;//角速度改这里
          this.drawCanvas();
        }, 50);
      }
    } else {
      if (this.radarIntervalId !== -1) {
        //清空定时器
        clearInterval(this.radarIntervalId);
        this.radarIntervalId = -1;
        console.log('已回收雷达特效定时器')
      }
      this.drawCanvas();
    }
  }

  private drawCanvas() {
    if (!this.renderingContext || !this.canvasWidth || !this.canvasHeight) return;
    const ctx = this.renderingContext;
    ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

    // 计算扫描框位置（居中）
    const centerX = this.canvasWidth / 2;
    //const centerY = this.canvasHeight / 2;
    const centerY = this.SCAN_BOX_TOP;
    const scanBoxX = centerX - this.SCAN_BOX_SIZE / 2;
    const scanBoxY = centerY - this.SCAN_BOX_SIZE / 2;

    if(this.isQT){
      // 六边形雷达
      this.drawRadarEffect_Hexagon(ctx, centerX, centerY);
    }
    else{
      // 扫描线
      this.drawScanLine(ctx, scanBoxX, scanBoxY);
    }
  }

  //@Monitor('themeColor')
  private onThemeColorChange(){
    this.buildColor()
    this.drawCanvas()
  }

  private buildColor(){
    const c0 = this.colorToRgba(this.themeColor, 0.0);
    const c1 = this.colorToRgba(this.themeColor, 1.0);
    this.drawScanLineColor = [c0,c1];
    const h0 = this.colorToRgba(this.themeColor, 0.0);
    const h1 = this.colorToRgba(this.themeColor, 0.8);
    const h2 = this.colorToRgba(this.themeColor, 0.3);
    const h3 = this.colorToRgba(this.themeColor, 0.0);
    this.hexagonEffectColor = [h0,h1,h2,h3];
  }

  // 将 ResourceColor 转为 rgba 字符串，便于控制透明度
  private colorToRgba(c: ResourceColor, a: number): string {
    const s = c?.toString?.() ?? '';
    if (typeof s === 'string' && s.startsWith('#')) {
      let r = 0, g = 0, b = 0, alpha = a;
      if (s.length === 7) { // #RRGGBB
        r = parseInt(s.slice(1, 3), 16);
        g = parseInt(s.slice(3, 5), 16);
        b = parseInt(s.slice(5, 7), 16);
      } else if (s.length === 9) { // #AARRGGBB
        const aa = parseInt(s.slice(1, 3), 16) / 255;
        r = parseInt(s.slice(3, 5), 16);
        g = parseInt(s.slice(5, 7), 16);
        b = parseInt(s.slice(7, 9), 16);
        alpha = aa * a;
      }
      return `rgba(${r},${g},${b},${alpha})`;
    }
    if (typeof s === 'string' && s.startsWith('rgb')) {
      const m = s.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)/);
      if (m) {
        return `rgba(${m[1]},${m[2]},${m[3]},${a})`;
      }
    }
    return `rgba(0,255,0,${a})`;
  }

  private drawScanLineColor:Array<string> = [];
  /**
   * 矩形扫描框的扫描线
   * */
  private drawScanLine(ctx: CanvasRenderingContext2D, scanBoxX: number, scanBoxY: number) {
    const y = scanBoxY + this.scanLinePosition;
    const g = ctx.createLinearGradient(scanBoxX, y, scanBoxX + this.SCAN_BOX_SIZE, y);
    // g.addColorStop(0, 'rgba(0,255,0,0)');
    // g.addColorStop(0.5, 'rgba(0,255,0,1)');
    // g.addColorStop(1, 'rgba(0,255,0,0)');
    g.addColorStop(0, this.drawScanLineColor[0]);
    g.addColorStop(0.5, this.drawScanLineColor[1]);
    g.addColorStop(1, this.drawScanLineColor[0]);
    ctx.fillStyle = g;
    ctx.fillRect(scanBoxX, y, this.SCAN_BOX_SIZE, 2);
  }

  private hexagonEffectColor :Array<string> = [];
  /**
   * 六边形雷达渐变
   * */
  private drawRadarEffect_Hexagon(ctx: CanvasRenderingContext2D, centerX: number, centerY: number) {
    const r = this.SCAN_BOX_SIZE / Math.sqrt(3);
    ctx.save();
    const grad = ctx.createConicGradient(this.radarAngle * Math.PI / 180, centerX, centerY);
    // grad.addColorStop(0, 'rgba(0,255,0,0)');
    // grad.addColorStop(0.1, 'rgba(0,255,0,0.8)');
    // grad.addColorStop(0.3, 'rgba(0,255,0,0.3)');
    // grad.addColorStop(1, 'rgba(0,255,0,0)');
    grad.addColorStop(0, this.hexagonEffectColor[0]);
    grad.addColorStop(0.1, this.hexagonEffectColor[1]);
    grad.addColorStop(0.3, this.hexagonEffectColor[2]);
    grad.addColorStop(1, this.hexagonEffectColor[3]);
    ctx.beginPath();
    for (let i = 0; i < 6; i++) {
      const a = Math.PI / 6 + Math.PI / 3 * i;
      const x = centerX + r * Math.cos(a);
      const y = centerY + r * Math.sin(a);
      i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
    }
    ctx.closePath();
    ctx.fillStyle = grad;
    ctx.fill();
    ctx.restore();
  }

  private buildScanBox(canvasWidth:number,canvasHeight:number){
    let size = computeRecommendedScanSide(canvasWidth,canvasHeight)
    let scanBoxTop = canvasHeight * this.centerY; //40%
    let scanBoxLet = (canvasWidth - size) / 2;

    this.canvasWidth = canvasWidth;
    this.canvasHeight = canvasHeight;
    this.SCAN_BOX_SIZE = size;
    this.SCAN_BOX_TOP = scanBoxTop; //40%
    this.buildColor();

    //把扫描框信息返回父组件，可通过EvenManager发送,已在ScanningEffectCanvasStatic发送
  }

  build() {
    Canvas(this.renderingContext)
      .width('100%')
      .height('100%')
      .onReady(() => this.drawCanvas())
      .onAreaChange((_, area: Area) => {
        let canvasWidth = area.width as number;
        let canvasHeight = area.height as number;
        this.buildScanBox(canvasWidth,canvasHeight);
      })
  }
}

/**
 * 计算扫描框大小(相当于安卓ScanShapeView.init)
 * @param canvasWidth
 * @param canvasHeight
 * @returns
 * */
function computeRecommendedScanSide(canvasWidth: number, canvasHeight: number): number {
  // const w = Math.min(canvasWidth, canvasHeight);
  // const h = Math.max(canvasWidth, canvasHeight);
  const w = canvasWidth;
  const h = canvasHeight;
  //兼顾美观，以及解码速度（框太大会导致解码时间过长）
  const ratio = w / h;
  let scanSide = w * 2 / 3;
  if (ratio < 0.449) {//比如折叠屏的小屏幕
    scanSide = w * 4 / 5;
  } else if (ratio < 0.5) {//大概是(9:20),比如1080:2400
    scanSide = w * 7 / 10;
  } else if (ratio > 0.75) {//屏幕比较短，比如折叠屏展开后5:4
    scanSide = Math.min(w * 2 / 3, h * 2 / 5);
  }
  return scanSide;
}
function computeScanBoxSafeArea(canvasWidth:number,canvasHeight:number,scanBoxTop:number,size:number){
  //由于扫描框会以正六边形形式出现，size换算成正六边形中垂线的长度
  size = size * 2 / Math.sqrt(3);
  const left   = (canvasWidth - size) / 2;
  const right  = left + size;
  const top    = scanBoxTop - size / 2;
  const bottom = scanBoxTop + size / 2;
  ScanBoxSafeArea.init(
    { x: 0,          y: 0,           size: { width: canvasWidth, height: top } },                        // 上
    { x: 0,          y: bottom,      size: { width: canvasWidth, height: canvasHeight - bottom } },      // 下
    { x: 0,          y: top,         size: { width: left,        height: size } },                       // 左
    { x: right,      y: top,         size: { width: canvasWidth - right, height: size } }                // 右
  );
  if(BuildProfile.DEBUG){
    let scanBoxSafeArea = ScanBoxSafeArea.getInstance();
    console.log('canvasHeight', canvasHeight);
    console.log('bottom.y', scanBoxSafeArea.Bottom.y);
    console.log('bottom.height', scanBoxSafeArea.Bottom.size.height);
    console.log('computed diff', canvasHeight - scanBoxSafeArea.Bottom.y);
  }
}
