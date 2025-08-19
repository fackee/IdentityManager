import { DocumentItem, DynamicFieldItem } from '../model/DocumentItem'
import router from '@ohos.router'
import { DocumentDetailParams } from '../types/RouterParams'
import image from '@kit.ImageKit'
import { BusinessError, pasteboard } from '@kit.BasicServicesKit'
import { unifiedDataChannel, uniformDataStruct, uniformTypeDescriptor } from '@kit.ArkData'

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
        params.createTime,
        params.updateTime,
        params.dynamicFields
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
        List() {
          this.InfoItem('证件类型', this.document.type)
          
          // 动态渲染dynamicFields中的数据
          ForEach(this.document.getAllDynamicFields(), (field: DynamicFieldItem) => {
            this.InfoItem(field.key, field.value, true)
          })
        }
        .height(400)
        .width('100%')
        .padding({ left: 20, right: 20 })
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
  InfoItem(label: string, value: string, showCopyButton: boolean = false) {
    ListItem() {
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

        if (showCopyButton) {
          Button('复制')
            .fontSize(12)
            .backgroundColor('#007DFF')
            .fontColor(Color.White)
            .borderRadius(4)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .margin({ left: 8 })
            .onClick(() => {
              this.copyToClipboard(value)
            })
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius(8)
      .margin({ bottom: 8 })
    }
  }

  private reloadDocument() {
    console.log('重新加载证件信息')
    // 这里可以重新获取证件数据
  }

  private goBack() {
    this.getUIContext().getRouter().back()
  }

  private copyToClipboard(text: string) {
    // 构造一条PlainText数据
    let plainText: uniformDataStruct.PlainText = {
      uniformDataType: uniformTypeDescriptor.UniformDataType.PLAIN_TEXT,
      textContent: text,
      abstract: '复制的证件信息'
    }
    let record = new unifiedDataChannel.UnifiedRecord(uniformTypeDescriptor.UniformDataType.PLAIN_TEXT, plainText)
    let data = new unifiedDataChannel.UnifiedData()
    data.addRecord(record)

    // 向系统剪贴板中存入数据
    let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard()
    systemPasteboard.setUnifiedData(data).then(() => {
      this.getUIContext().getPromptAction().showToast({
        message: '已复制到剪切板'
      })
      // 可以在这里添加提示信息
    }).catch((err: BusinessError) => {
      this.getUIContext().getPromptAction().showToast({
        message: '复制到剪贴板失败: ' + err.message
      })
    })
  }
}
