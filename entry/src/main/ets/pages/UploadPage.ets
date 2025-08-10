import { DocumentItem } from '../model/DocumentItem'
import { DocumentType } from '../model/DocumentType'
import { ImageUtils } from '../utils/ImageUtils'
import { DocumentRecognitionService } from '../services/DocumentRecognitionService'
import { LocalDatabaseManager } from '../manager/LocalDatabaseManager'
import { RecognitionResponse, RecognitionField, UploadPageParams } from '../types/DocumentRecognition'
import { PermissionUtils } from '../utils/PermissionUtils'

@Entry
@Component
struct UploadPage {
  @State currentStep: number = 0
  @State selectedImage: Resource | null = null
  @State imagePath: string = ''
  @State imageBase64: string = ''
  @State isProcessing: boolean = false
  @State recognitionResult: RecognitionResponse | null = null
  @State dynamicFields: Map<string, string> = new Map()
  @State documentType: string = ''
  @State confidence: number = 0

  private databaseManager: LocalDatabaseManager = LocalDatabaseManager.getInstance()

  aboutToAppear() {
    // 初始化数据库
    this.databaseManager.initialize(getContext())
    
    // 检查是否有传入的参数
    const params = this.getUIContext().getRouter().getParams() as UploadPageParams
    if (params?.mode) {
      this.selectUploadMethod(params.mode)
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

      if (this.imagePath) {
        Image(this.imagePath)
          .width('80%')
          .height(300)
          .borderRadius(12)
          .objectFit(ImageFit.Cover)
          .margin({ bottom: 40 })
      } else {
        Image($r('app.media.background'))
          .width('80%')
          .height(300)
          .borderRadius(12)
          .margin({ bottom: 40 })
      }

      Row() {
        Button('重新拍摄')
          .width(120)
          .height(48)
          .backgroundColor('#F0F0F0')
          .fontColor('#666666')
          .margin({ right: 20 })
          .onClick(() => {
            this.currentStep = 0
          })

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
      Text('预览')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      if (this.imagePath) {
        Image(this.imagePath)
          .width('90%')
          .height(400)
          .borderRadius(12)
          .objectFit(ImageFit.Cover)
          .margin({ bottom: 30 })
      } else {
        Image($r('app.media.background'))
          .width('90%')
          .height(400)
          .borderRadius(12)
          .margin({ bottom: 30 })
      }

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
            this.startRecognition()
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

      if (this.isProcessing) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .margin({ bottom: 16 })
          Text('正在识别中...')
            .fontSize(16)
            .fontColor('#666666')
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      } else if (this.recognitionResult && this.recognitionResult.success) {
        Column() {
          // 文档类型和置信度
          Row() {
            Text(`文档类型: ${this.documentType}`)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Blank()
            Text(`置信度: ${(this.confidence * 100).toFixed(1)}%`)
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
          .margin({ bottom: 20 })

          // 动态表单字段
          Column() {
            ForEach(Array.from(this.dynamicFields.entries()), ([key, value]) => {
              this.DynamicField(key, value)
            })
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
        .padding({ left: 20, right: 20 })
      } else {
        Column() {
          Text('识别失败')
            .fontSize(18)
            .fontColor('#FF4444')
            .margin({ bottom: 16 })
          
          if (this.recognitionResult?.error) {
            Text(this.recognitionResult.error)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 30 })
          }

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

            Button('返回')
              .width(120)
              .height(48)
              .backgroundColor('#007DFF')
              .fontColor(Color.White)
              .onClick(() => {
                this.currentStep = 0
              })
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ left: 20, right: 20 })
  }

  @Builder
  DynamicField(key: string, value: string) {
    Row() {
      Text(key)
        .fontSize(16)
        .fontColor('#666666')
        .width('30%')
      
      TextInput({ text: value })
        .width('70%')
        .height(40)
        .backgroundColor('#F8F9FA')
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .onChange((newValue: string) => {
          this.dynamicFields.set(key, newValue)
        })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  private async selectUploadMethod(method: string) {
    console.log('选择上传方式:', method)
    
    try {
      let result
      if (method === 'camera') {
        result = await ImageUtils.takePhoto(getContext())
      } else if (method === 'gallery') {
        result = await ImageUtils.selectFromGallery(getContext())
      }

      if (result?.success && result.imagePath) {
        this.imagePath = result.imagePath
        this.imageBase64 = result.imageBase64 || ''
        this.currentStep = 1
      } else {
        // 显示错误信息
        this.getUIContext().showAlertDialog({
          title: '错误',
          message: result?.error || '获取图片失败',
          primaryButton: {
            value: '确定',
            action: () => {
              console.log('用户确认错误')
            }
          }
        })
      }
    } catch (error) {
      console.error('选择上传方式失败:', error)
      this.getUIContext().showAlertDialog({
        title: '错误',
        message: '获取图片失败',
        primaryButton: {
          value: '确定',
          action: () => {
            console.log('用户确认错误')
          }
        }
      })
    }
  }

  private async startRecognition() {
    if (!this.imageBase64) {
      this.getUIContext().showAlertDialog({
        title: '错误',
        message: '没有可识别的图片',
        primaryButton: {
          value: '确定',
          action: () => {
            console.log('用户确认错误')
          }
        }
      })
      return
    }

    this.currentStep = 3
    this.isProcessing = true

    try {
      // 调用识别服务
      const result = await DocumentRecognitionService.recognizeDocument(this.imageBase64)
      
      this.recognitionResult = result
      this.isProcessing = false

      if (result.success) {
        this.documentType = result.documentType
        this.confidence = result.confidence
        
        // 初始化动态字段
        this.dynamicFields.clear()
        result.fields.forEach(field => {
          this.dynamicFields.set(field.label, field.value)
        })
      }
    } catch (error) {
      console.error('识别失败:', error)
      this.isProcessing = false
      this.recognitionResult = {
        success: false,
        documentType: '',
        confidence: 0,
        fields: [],
        error: '识别失败'
      }
    }
  }

  private async saveDocument() {
    try {
      // 创建文档对象
      const document = new DocumentItem(
        '', // ID将由数据库管理器生成
        this.documentType, // 使用识别出的文档类型作为名称
        this.documentType,
        this.dynamicFields.get('证件号码') || this.dynamicFields.get('护照号码') || this.dynamicFields.get('驾驶证号码') || '',
        this.dynamicFields.get('有效期限') || this.dynamicFields.get('有效期至') || '',
        $r('app.media.background'), // 暂时使用默认图片
        new Date(),
        new Date(),
        this.dynamicFields,
        this.confidence,
        this.imagePath
      )

      // 保存到数据库
      const success = await this.databaseManager.addDocument(document)
      
      if (success) {
        this.getUIContext().showAlertDialog({
          title: '成功',
          message: '文档保存成功',
          primaryButton: {
            value: '确定',
            action: () => {
              this.goBack()
            }
          }
        })
      } else {
        this.getUIContext().showAlertDialog({
          title: '错误',
          message: '保存失败',
          primaryButton: {
            value: '确定',
            action: () => {
              console.log('用户确认错误')
            }
          }
        })
      }
    } catch (error) {
      console.error('保存文档失败:', error)
      this.getUIContext().showAlertDialog({
        title: '错误',
        message: '保存失败',
        primaryButton: {
          value: '确定',
          action: () => {
            console.log('用户确认错误')
          }
        }
      })
    }
  }

  private goBack() {
    this.getUIContext().getRouter().back()
  }
} 