import { DocumentItem } from '../model/DocumentItem'
import { DocumentType } from '../model/DocumentType'

@Entry
@Component
struct UploadPage {
  @State currentStep: number = 0
  @State selectedImage: Resource | null = null

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button('返回')
          .onClick(() => {
            this.goBack()
          })
        
        Text('添加证件')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })

      // 步骤指示器
      Row() {
        ForEach([1, 2, 3, 4], (step: number) => {
          Text(step.toString())
            .fontSize(14)
            .fontColor(this.currentStep >= step ? Color.White : '#666666')
            .backgroundColor(this.currentStep >= step ? '#007DFF' : '#F0F0F0')
            .width(24)
            .height(24)
            .borderRadius(12)
            .textAlign(TextAlign.Center)
            .margin({ right: 8 })
        })
      }
      .justifyContent(FlexAlign.Center)
      .margin({ top: 20, bottom: 30 })

      // 内容区域
      if (this.currentStep === 0) {
        this.UploadMethodSelection()
      } else if (this.currentStep === 1) {
        this.ImageCapture()
      } else if (this.currentStep === 2) {
        this.ImagePreview()
      } else if (this.currentStep === 3) {
        this.RecognitionResult()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }

  @Builder
  UploadMethodSelection() {
    Column() {
      Text('选择上传方式')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 40 })

      Button('拍照上传')
        .width('80%')
        .height(56)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .margin({ bottom: 20 })
        .onClick(() => {
          this.selectUploadMethod('camera')
        })

      Button('从相册选择')
        .width('80%')
        .height(56)
        .backgroundColor(Color.White)
        .fontColor('#007DFF')
        .border({ width: 2, color: '#007DFF' })
        .onClick(() => {
          this.selectUploadMethod('gallery')
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ImageCapture() {
    Column() {
      Text('拍摄证件照片')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      Image($r('app.media.background'))
        .width('80%')
        .height(300)
        .borderRadius(12)
        .margin({ bottom: 40 })

      Row() {
        Button('重新拍摄')
          .width(120)
          .height(48)
          .backgroundColor('#F0F0F0')
          .fontColor('#666666')
          .margin({ right: 20 })

        Button('下一步')
          .width(120)
          .height(48)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .onClick(() => {
            this.currentStep = 2
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ImagePreview() {
    Column() {
      Text('预览与裁剪')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      Image($r('app.media.background'))
        .width('90%')
        .height(400)
        .borderRadius(12)
        .margin({ bottom: 30 })

      Row() {
        Button('重新选择')
          .width(120)
          .height(48)
          .backgroundColor('#F0F0F0')
          .fontColor('#666666')
          .margin({ right: 20 })
          .onClick(() => {
            this.currentStep = 0
          })

        Button('开始识别')
          .width(120)
          .height(48)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .onClick(() => {
            this.currentStep = 3
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  RecognitionResult() {
    Column() {
      Text('识别结果')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 30 })

      Column() {
        this.InfoField('证件类型', '身份证')
        this.InfoField('姓名', '张三')
        this.InfoField('证件号码', '110101199001011234')
        this.InfoField('有效期', '2025-12-31')
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(12)
      .padding(20)
      .margin({ bottom: 30 })

      Row() {
        Button('重新识别')
          .width(120)
          .height(48)
          .backgroundColor('#F0F0F0')
          .fontColor('#666666')
          .margin({ right: 20 })
          .onClick(() => {
            this.currentStep = 2
          })

        Button('保存')
          .width(120)
          .height(48)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .onClick(() => {
            this.saveDocument()
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ left: 20, right: 20 })
  }

  @Builder
  InfoField(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#666666')
        .width('30%')
      
      TextInput({ text: value })
        .width('70%')
        .height(40)
        .backgroundColor('#F8F9FA')
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  private selectUploadMethod(method: string) {
    console.log('选择上传方式:', method)
    this.currentStep = 1
  }

  private saveDocument() {
    console.log('保存证件')
    this.goBack()
  }

  private goBack() {
    console.log('返回')
  }
} 