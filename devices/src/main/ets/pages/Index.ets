import { taskpool } from '@kit.ArkTS';
import { emitter } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
          .onClick(async () => {

          })
      }
      .width('100%')
    }
    .height('100%')
  }
}

