import { DocumentItem } from '../model/DocumentItem'
import router from '@ohos.router'
import { DocumentDetailParams } from '../types/RouterParams'
import image from '@kit.ImageKit'

@Entry
@Component
struct DocumentDetailPage {
  @State document: DocumentItem | null = null

  aboutToAppear() {
    // 获取路由参数
    const params = this.getUIContext().getRouter().getParams() as DocumentDetailParams
    if (params && params.documentId) {
      this.document = new DocumentItem(
        params.documentId,
        params.documentName,
        params.documentType,
        params.documentNumber,
        params.documentExpiry,
        params.documentImage,
        new Date(),
        new Date()
      )
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button('返回')
          .onClick(() => {
            this.goBack()
          })
        
        Text('证件详情')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16 })

        Blank()

        Button('编辑')
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .onClick(() => {
            this.editDocument()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })

      if (this.document) {
        // 证件图片
        Image(this.document.imageUrl ? this.document.imageUrl : $r('app.media.background'))
          .width('100%')
          .height(300)
          .objectFit(ImageFit.Cover)
          .borderRadius(12)
          .margin({ left: 20, right: 20, bottom: 20 })

        // 证件信息
        Column() {
          this.InfoItem('证件名称', this.document.name)
          this.InfoItem('证件类型', this.document.type)
          this.InfoItem('证件号码', this.document.number)
          this.InfoItem('有效期至', this.document.expiryDate)
          this.InfoItem('创建时间', this.document.createTime.toLocaleDateString())
          this.InfoItem('更新时间', this.document.updateTime.toLocaleDateString())
        }
        .width('100%')
        .padding({ left: 20, right: 20 })

        // 操作按钮
        Row() {
          Button('打印')
            .width('45%')
            .height(48)
            .backgroundColor('#4CAF50')
            .fontColor(Color.White)
            .onClick(() => {
              this.printDocument()
            })

          Button('分享')
            .width('45%')
            .height(48)
            .backgroundColor('#FF9800')
            .fontColor(Color.White)
            .onClick(() => {
              this.shareDocument()
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ top: 40, left: 20, right: 20 })
      } else {
        // 加载失败提示
        Column() {
          Text('证件信息加载失败')
            .fontSize(18)
            .fontColor('#666666')
            .margin({ bottom: 16 })
          
          Button('重新加载')
            .backgroundColor('#007DFF')
            .fontColor(Color.White)
            .onClick(() => {
              this.reloadDocument()
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }

  @Builder
  InfoItem(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#666666')
        .width('30%')
      
      Text(value)
        .fontSize(16)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ bottom: 8 })
  }

  private editDocument() {
    if (this.document) {
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/EditPage',
        params: {
          documentId: this.document.id,
          documentName: this.document.name,
          documentType: this.document.type,
          documentNumber: this.document.number,
          documentExpiry: this.document.expiryDate,
          documentImage: this.document.imageUrl
        }
      })
    }
  }

  private printDocument() {
    if (this.document) {
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/PrintPage',
        params: {
          documentId: this.document.id,
          documentName: this.document.name,
          documentType: this.document.type,
          documentNumber: this.document.number,
          documentExpiry: this.document.expiryDate,
          documentImage: this.document.imageUrl
        }
      })
    }
  }

  private shareDocument() {
    console.log('分享证件')
    this.getUIContext().showAlertDialog({
      title: '分享证件',
      message: '选择分享方式',
      primaryButton: {
        value: '微信',
        action: () => {
          console.log('分享到微信')
        }
      },
      secondaryButton: {
        value: 'QQ',
        action: () => {
          console.log('分享到QQ')
        }
      }
    })
  }

  private reloadDocument() {
    console.log('重新加载证件信息')
    // 这里可以重新获取证件数据
  }

  private goBack() {
    this.getUIContext().getRouter().back()
  }
}
