import { CustomTheme, CustomColors, ThemeControl } from '@kit.ArkUI';
import { tag } from '@kit.ConnectivityKit';


@Entry
@ComponentV2
struct Index {

    @Local tag: boolean = false

    build() {
        Column() {
            buildSwitchItem({tag: this.tag!!})
        }

    }


}

@ComponentV2
struct buildSwitchItem{

    @Param title: string = 'test'
    @Param tag: boolean = false
    @Event $tag: (val: boolean) => void = (tag: boolean) => {};

    build() {
        Row() {
            Text(this.title)
                .fontSize(14)
                .fontColor('#000000')
                .flexGrow(1)
                .padding({ left: 7, bottom: 5 })

            Toggle({type: ToggleType.Switch, isOn: this.tag!!})
                .size({ width: 40, height: 25})
                .onChange(() => {
                    this.$tag(!this.tag)
                })
        }
        .height(35)
        .alignItems(VerticalAlign.Center)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .padding({ left: 10, right: 15 })
    }
}