import { DocumentItem } from '../model/DocumentItem'
import router from '@ohos.router'
import { DocumentPrintParams } from '../types/RouterParams'

@Entry
@Component
struct PrintPage {
  @State selectedPrinter: string = ''
  @State paperSize: string = 'A4'
  @State copies: number = 1
  @State mode: string = 'print' // 'print' 或 'list'
  @State documentData: DocumentPrintParams | null = null
  @State documents: DocumentItem[] = []

  aboutToAppear() {
    // 获取路由参数
    const params = this.getUIContext().getRouter().getParams() as DocumentPrintParams
    if (params) {
      this.mode = params.mode || 'print'
      if (this.mode === 'print' && params.documentId) {
        // 打印模式，接收证件数据
        this.documentData = {
          documentId: params.documentId,
          documentName: params.documentName,
          documentType: params.documentType,
          documentNumber: params.documentNumber,
          documentExpiry: params.documentExpiry,
          documentImage: params.documentImage
        }
      } else if (this.mode === 'list') {
        // 打印列表模式，加载所有证件
        this.loadDocuments()
      }
    }
  }

  loadDocuments() {
    // 模拟加载证件数据
    this.documents = [
      new DocumentItem(
        '1',
        '张三的身份证',
        '身份证',
        '1101********1234',
        '2025-12-31',
        $r('app.media.background'),
        new Date(),
        new Date()
      ),
      new DocumentItem(
        '2',
        '李四的护照',
        '护照',
        'E12345678',
        '2026-06-30',
        $r('app.media.background'),
        new Date(),
        new Date()
      )
    ]
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button('返回')
          .onClick(() => {
            this.goBack()
          })
        
        Text(this.mode === 'print' ? '打印证件' : '批量打印')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16 })

        Blank()

        if (this.mode === 'print') {
          Button('打印')
            .backgroundColor('#007DFF')
            .fontColor(Color.White)
            .onClick(() => {
              this.startPrint()
            })
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })

      if (this.mode === 'print') {
        // 单证件打印模式
        this.SinglePrintMode()
      } else {
        // 批量打印模式
        this.BatchPrintMode()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }

  @Builder
  SinglePrintMode() {
    Column() {
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

        Image(this.documentData?.documentImage || $r('app.media.background'))
          .width('100%')
          .height(200)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
  }

  @Builder
  BatchPrintMode() {
    Column() {
      // 批量打印说明
      Text('选择要打印的证件')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 16 })

      // 证件列表
      List() {
        ForEach(this.documents, (document: DocumentItem) => {
          ListItem() {
            Row() {
              Checkbox()
                .select(false)
                .onChange((value: boolean) => {
                  console.log('选择证件:', document.id, value)
                })

              Image(document.imageUrl)
                .width(60)
                .height(45)
                .borderRadius(8)
                .objectFit(ImageFit.Cover)
                .margin({ left: 12 })

              Column() {
                Text(document.name)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .margin({ bottom: 4 })
                
                Text(document.number)
                  .fontSize(14)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 12 })
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
      .layoutWeight(1)

      // 批量打印按钮
      Button('批量打印')
        .width('100%')
        .height(48)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .margin({ top: 20 })
        .onClick(() => {
          this.batchPrint()
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20 })
  }

  private startPrint() {
    if (!this.selectedPrinter) {
      this.getUIContext().showAlertDialog({
        title: '提示',
        message: '请选择打印机',
        primaryButton: {
          value: '确定',
          action: () => {
            console.log('确定')
          }
        }
      })
      return
    }

    console.log('开始打印', {
      printer: this.selectedPrinter,
      paperSize: this.paperSize,
      copies: this.copies,
      document: this.documentData
    })

    // 显示打印进度
    this.getUIContext().showAlertDialog({
      title: '打印中',
      message: '正在打印证件，请稍候...',
      primaryButton: {
        value: '确定',
        action: () => {
          console.log('打印完成')
          this.goBack()
        }
      }
    })
  }

  private batchPrint() {
    console.log('批量打印')
    this.getUIContext().showAlertDialog({
      title: '批量打印',
      message: '正在准备批量打印...',
      primaryButton: {
        value: '确定',
        action: () => {
          console.log('批量打印完成')
          this.goBack()
        }
      }
    })
  }

  private goBack() {
    this.getUIContext().getRouter().back()
  }
} 