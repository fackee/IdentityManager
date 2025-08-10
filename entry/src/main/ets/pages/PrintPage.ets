import { DocumentItem } from '../model/DocumentItem'

@Entry
@Component
struct PrintPage {
  @State selectedPrinter: string = ''
  @State paperSize: string = 'A4'
  @State copies: number = 1

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button('返回')
          .onClick(() => {
            this.goBack()
          })
        
        Text('打印证件')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16 })

        Blank()

        Button('打印')
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .onClick(() => {
            this.startPrint()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })

      // 打印机选择
      Column() {
        Text('选择打印机')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 16 })

        List() {
          ForEach(['HP LaserJet Pro', 'Canon PIXMA', 'Epson WorkForce'], (printer: string) => {
            ListItem() {
              Row() {
                Radio({ value: printer, group: 'printer' })
                  .checked(this.selectedPrinter === printer)
                  .onChange((isChecked: boolean) => {
                    if (isChecked) {
                      this.selectedPrinter = printer
                    }
                  })

                Text(printer)
                  .fontSize(16)
                  .margin({ left: 12 })

                Blank()

                Text('已连接')
                  .fontSize(12)
                  .fontColor('#4CAF50')
                  .backgroundColor('#E8F5E8')
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .borderRadius(12)
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(8)
              .margin({ bottom: 8 })
            }
          })
        }
        .width('100%')
        .height(150)
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })

      // 打印设置
      Column() {
        Text('打印设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 16 })

        // 纸张大小
        Row() {
          Text('纸张大小')
            .fontSize(16)
            .fontColor('#666666')
            .width('30%')

          Select([
            { value: 'A4' },
            { value: 'A5' },
            { value: '证件尺寸' },
            { value: '自定义' }
          ])
            .selected(0)
            .value(this.paperSize)
            .font({ size: 16 })
            .onSelect((index: number, value: string) => {
              this.paperSize = value
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .margin({ bottom: 8 })

        // 打印份数
        Row() {
          Text('打印份数')
            .fontSize(16)
            .fontColor('#666666')
            .width('30%')

          Row() {
            Button('-')
              .width(40)
              .height(40)
              .backgroundColor('#F0F0F0')
              .fontColor('#666666')
              .onClick(() => {
                if (this.copies > 1) {
                  this.copies--
                }
              })

            Text(this.copies.toString())
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .width(60)
              .textAlign(TextAlign.Center)

            Button('+')
              .width(40)
              .height(40)
              .backgroundColor('#F0F0F0')
              .fontColor('#666666')
              .onClick(() => {
                if (this.copies < 10) {
                  this.copies++
                }
              })
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .margin({ bottom: 8 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })

      // 打印预览
      Column() {
        Text('打印预览')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 16 })

        Image($r('app.media.background'))
          .width('100%')
          .height(200)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }

  private startPrint() {
    if (!this.selectedPrinter) {
      console.log('请选择打印机')
      return
    }

    console.log('开始打印', {
      printer: this.selectedPrinter,
      paperSize: this.paperSize,
      copies: this.copies
    })

    setTimeout(() => {
      console.log('打印完成')
      this.goBack()
    }, 2000)
  }

  private goBack() {
    console.log('返回')
  }
} 