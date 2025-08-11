import { DocumentItem } from '../model/DocumentItem'
import { DocumentEditParams } from '../types/RouterParams'
import image from '@kit.ImageKit'

@Entry
@Component
struct EditPage {
  @State document: DocumentItem | null = null
  @State currentTool: string = ''
  @State brightnessValue: number = 0
  @State contrastValue: number = 0
  @State saturationValue: number = 0
  @State mode: string = 'edit' // 'edit' 或 'tool'
  @State documentData: DocumentEditParams | null = null

  aboutToAppear() {
    // 获取路由参数
    const params = this.getUIContext().getRouter().getParams() as DocumentEditParams
    if (params) {
      this.mode = params.mode || 'edit'
      if (this.mode === 'edit' && params.documentId) {
        // 编辑模式，接收证件数据
        this.documentData = {
          documentId: params.documentId,
          documentName: params.documentName,
          documentType: params.documentType,
          documentNumber: params.documentNumber,
          documentExpiry: params.documentExpiry,
          documentImage: params.documentImage
        }
        this.document = new DocumentItem(
          this.documentData.documentId || '',
          this.documentData.documentName || '',
          this.documentData.documentType || '',
          this.documentData.documentNumber || '',
          this.documentData.documentExpiry || '',
          this.documentData.documentImage || '',
          new Date(),
          new Date()
        )
      }
    }
  }

  build() {
    Column() {
      // 顶部工具栏
      Row() {
        Button('返回')
          .onClick(() => {
            this.goBack()
          })
        
        Text(this.mode === 'edit' ? '编辑证件' : '编辑工具')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16 })

        Blank()

        if (this.mode === 'edit') {
          Button('保存')
            .backgroundColor('#007DFF')
            .fontColor(Color.White)
            .onClick(() => {
              this.saveEdit()
            })
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })

      // 图片编辑区域
      Stack() {
        Image(this.document?.imageUrl ? this.document.imageUrl : $r('app.media.background'))
          .width('100%')
          .height(400)
          .objectFit(ImageFit.Cover)
          .borderRadius(12)
          .margin({ left: 20, right: 20, bottom: 20 })

        // 编辑工具提示
        if (this.currentTool) {
          Text(`当前工具: ${this.currentTool}`)
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor('#00000080')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(16)
            .position({ x: '50%', y: 20 })
            .translate({ x: -50 })
        }
      }
      .width('100%')
      .height(420)

      // 编辑工具选择
      Row() {
        ForEach(['裁剪', '旋转', '抠图', '调整', '滤镜'], (tool: string) => {
          Button(tool)
            .width(60)
            .height(40)
            .fontSize(12)
            .backgroundColor(this.currentTool === tool ? '#007DFF' : '#F0F0F0')
            .fontColor(this.currentTool === tool ? Color.White : '#666666')
            .margin({ right: 8 })
            .onClick(() => {
              this.selectTool(tool)
            })
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })

      // 工具操作面板
      if (this.currentTool === '调整') {
        this.AdjustmentPanel()
      } else if (this.currentTool === '滤镜') {
        this.FilterPanel()
      } else if (this.currentTool === '裁剪') {
        this.CropPanel()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }

  @Builder
  AdjustmentPanel() {
    Column() {
      Text('图片调整')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 20 })

      Row() {
        Text('亮度')
          .fontSize(14)
          .fontColor('#666666')
          .width('20%')
        
        Slider({
          value: this.brightnessValue,
          min: -100,
          max: 100,
          step: 1
        })
        .width('60%')
        .onChange((value: number) => {
          this.brightnessValue = value
        })

        Text(this.brightnessValue.toString())
          .fontSize(14)
          .fontColor('#666666')
          .width('20%')
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .margin({ bottom: 16 })

      Row() {
        Text('对比度')
          .fontSize(14)
          .fontColor('#666666')
          .width('20%')
        
        Slider({
          value: this.contrastValue,
          min: -100,
          max: 100,
          step: 1
        })
        .width('60%')
        .onChange((value: number) => {
          this.contrastValue = value
        })

        Text(this.contrastValue.toString())
          .fontSize(14)
          .fontColor('#666666')
          .width('20%')
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .margin({ bottom: 16 })

      Row() {
        Text('饱和度')
          .fontSize(14)
          .fontColor('#666666')
          .width('20%')
        
        Slider({
          value: this.saturationValue,
          min: -100,
          max: 100,
          step: 1
        })
        .width('60%')
        .onChange((value: number) => {
          this.saturationValue = value
        })

        Text(this.saturationValue.toString())
          .fontSize(14)
          .fontColor('#666666')
          .width('20%')
          .textAlign(TextAlign.End)
      }
      .width('100%')
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding(20)
    .margin({ left: 20, right: 20 })
  }

  @Builder
  FilterPanel() {
    Column() {
      Text('滤镜效果')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 20 })

      Row() {
        ForEach(['原图', '黑白', '复古', '清晰', '柔和'], (filter: string) => {
          Column() {
            Image($r('app.media.background'))
              .width(60)
              .height(60)
              .borderRadius(8)
              .objectFit(ImageFit.Cover)
            
            Text(filter)
              .fontSize(12)
              .fontColor('#666666')
              .margin({ top: 4 })
          }
          .margin({ right: 12 })
          .onClick(() => {
            this.applyFilter(filter)
          })
        })
      }
      .width('100%')
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding(20)
    .margin({ left: 20, right: 20 })
  }

  @Builder
  CropPanel() {
    Column() {
      Text('裁剪设置')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 20 })

      Row() {
        ForEach(['自由', '1:1', '3:4', '4:3', '证件'], (ratio: string) => {
          Button(ratio)
            .width(60)
            .height(32)
            .fontSize(12)
            .backgroundColor('#F0F0F0')
            .fontColor('#666666')
            .margin({ right: 8 })
            .onClick(() => {
              this.setCropRatio(ratio)
            })
        })
      }
      .width('100%')
      .margin({ bottom: 16 })

      Row() {
        Button('重置')
          .width(80)
          .height(40)
          .backgroundColor('#F0F0F0')
          .fontColor('#666666')
          .margin({ right: 12 })

        Button('确认裁剪')
          .width(100)
          .height(40)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
      }
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding(20)
    .margin({ left: 20, right: 20 })
  }

  private selectTool(tool: string) {
    this.currentTool = tool
    console.log('选择工具:', tool)
  }

  private applyFilter(filter: string) {
    console.log('应用滤镜:', filter)
  }

  private setCropRatio(ratio: string) {
    console.log('设置裁剪比例:', ratio)
  }

  private saveEdit() {
    console.log('保存编辑')
    // 这里可以添加保存逻辑
    this.getUIContext().showAlertDialog({
      title: '保存成功',
      message: '证件编辑已保存',
      primaryButton: {
        value: '确定',
        action: () => {
          this.goBack()
        }
      }
    })
  }

  private goBack() {
    this.getUIContext().getRouter().back()
  }
} 