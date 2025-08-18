import { DocumentItem, DynamicFieldItem } from '../model/DocumentItem'
import { DocumentType } from '../model/DocumentType'
import { DocumentEditParams } from '../types/RouterParams'
import { DocumentDatabaseManager } from '../manager/DocumentDatabaseManager'

@Entry
@Component
struct EditPage {
  @State document: DocumentItem | null = null
  @State documentData: DocumentEditParams | null = null
  @State mode: string = 'edit' // 'edit' 或 'tool'
  @State selectedDocumentType: string = ''
  @State dynamicFields: Array<DynamicFieldItem> = []
  @State showAddFieldDialog: boolean = false
  @State newFieldKey: string = ''
  @State newFieldValue: string = ''

  aboutToAppear() {
    // 获取路由参数
    const params = this.getUIContext().getRouter().getParams() as DocumentEditParams
    console.log("params:", params.documentId)
    if (params && params.documentId) {
      // 从数据库获取证件数据
      this.loadDocumentFromDatabase(params.documentId)
    }
  }

  private async loadDocumentFromDatabase(documentId: string) {
    try {
      // 获取数据库管理器实例
      const dbManager = DocumentDatabaseManager.getInstance()

      // 确保数据库已初始化
      if (!dbManager.isDatabaseInitialized()) {
        await dbManager.initialize(getContext())
      }
      
      // 从数据库获取证件数据
      const document = await dbManager.getDocumentById(documentId)
      console.info("getDocumentById", document?.id)
      
      if (document) {
        this.document = document
        
        // 初始化证件类型
        this.selectedDocumentType = document.type || DocumentType.ID_CARD
        
        // 初始化动态字段 - 从数据库获取的getAllDynamicFields
        this.dynamicFields = document.getAllDynamicFields()
        
        console.log('从数据库加载证件成功:', document.name)
        console.log('动态字段数量:', this.dynamicFields.length)
      } else {
        console.error('未找到证件，ID:', documentId)
        // 显示错误提示
        this.getUIContext().showAlertDialog({
          title: '错误',
          message: '未找到指定的证件',
          primaryButton: {
            value: '确定',
            action: () => {
              this.goBack()
            }
          }
        })
      }
    } catch (error) {
      console.error('从数据库加载证件失败:', error)
      // 显示错误提示
      this.getUIContext().showAlertDialog({
        title: '错误',
        message: '加载证件数据失败',
        primaryButton: {
          value: '确定',
          action: () => {
            this.goBack()
          }
        }
      })
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
        
        Text('编辑证件')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16 })

        Blank()

        Button('保存')
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .onClick(async () => {
            await this.saveEdit()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })

      Scroll() {
        Column() {
          // 证件图片
          Image(this.document?.imageUrl ? this.document.imageUrl : $r('app.media.background'))
            .width('100%')
            .height(200)
            .objectFit(ImageFit.Cover)
            .borderRadius(12)
            .margin({ left: 20, right: 20, bottom: 20 })

          // 证件类型选择
          this.DocumentTypeSection()

          // 动态字段编辑
          this.DynamicFieldsSection()
        }
      }
      .width('100%')
      .layoutWeight(1)

      // 添加字段对话框
      if (this.showAddFieldDialog) {
        this.AddFieldDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }

  @Builder
  DocumentTypeSection() {
    Column() {
      Text('证件类型')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 16 })

      Row() {
        ForEach(Object.values(DocumentType).filter(type => type !== DocumentType.ALL), (type: string) => {
          Button(type)
            .width(80)
            .height(40)
            .fontSize(14)
            .backgroundColor(this.selectedDocumentType === type ? '#007DFF' : '#F0F0F0')
            .fontColor(this.selectedDocumentType === type ? Color.White : '#666666')
            .margin({ right: 12, bottom: 8 })
            .onClick(() => {
              this.selectedDocumentType = type
              this.document!.type = type
            })
        })
      }
      .width('100%')
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding(20)
    .margin({ left: 20, right: 20, bottom: 20 })
  }

  @Builder
  DynamicFieldsSection() {
    Column() {
      Row() {
        Text('证件信息')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
        
        Blank()
        
        Button('添加字段')
          .width(80)
          .height(32)
          .fontSize(12)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .onClick(() => {
            this.showAddFieldDialog = true
          })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 动态字段列表
      ForEach(this.dynamicFields, (item:DynamicFieldItem,index:number) => {
        this.DynamicFieldItem(item,index)
      })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding(20)
    .margin({ left: 20, right: 20, bottom: 20 })
  }

  @Builder
  DynamicFieldItem(field: DynamicFieldItem, index: number) {
    Row() {
      Column() {
        TextInput({ text: field.key })
          .width('100%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#F8F9FA')
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => {
            this.dynamicFields[index].key = value
          })
        
        Text('字段名')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .width('30%')
      .margin({ right: 12 })

      Column() {
        TextInput({ text: field.value })
          .width('100%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#F8F9FA')
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => {
            this.dynamicFields[index].value = value
          })
        
        Text('字段值')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .width('50%')
      .margin({ right: 12 })

      Button('删除')
        .width(60)
        .height(40)
        .fontSize(12)
        .backgroundColor('#FF4757')
        .fontColor(Color.White)
        .onClick(() => {
          this.dynamicFields.splice(index, 1)
        })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  // 添加字段对话框
  @Builder
  AddFieldDialog() {
    if (this.showAddFieldDialog) {
      Column() {
        Text('添加字段')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 20 })

        TextInput({ placeholder: '请输入字段名' })
          .width('100%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#F8F9FA')
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .margin({ bottom: 16 })
          .onChange((value: string) => {
            this.newFieldKey = value
          })

        TextInput({ placeholder: '请输入字段值' })
          .width('100%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#F8F9FA')
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .margin({ bottom: 20 })
          .onChange((value: string) => {
            this.newFieldValue = value
          })

        Row() {
          Button('取消')
            .width(100)
            .height(40)
            .backgroundColor('#F0F0F0')
            .fontColor('#666666')
            .margin({ right: 12 })
            .onClick(() => {
              this.showAddFieldDialog = false
              this.newFieldKey = ''
              this.newFieldValue = ''
            })

          Button('确定')
            .width(100)
            .height(40)
            .backgroundColor('#007DFF')
            .fontColor(Color.White)
            .onClick(() => {
              if (this.newFieldKey.trim() && this.newFieldValue.trim()) {
                this.dynamicFields.push({
                  key: this.newFieldKey.trim(),
                  value: this.newFieldValue.trim()
                })
                this.showAddFieldDialog = false
                this.newFieldKey = ''
                this.newFieldValue = ''
              }
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('80%')
      .backgroundColor(Color.White)
      .borderRadius(12)
      .padding(20)
      .position({ x: '10%', y: '30%' })
    }
  }

  private async saveEdit() {
    if (!this.document) {
      return
    }

    try {
      // 更新证件类型
      this.document.type = this.selectedDocumentType

      // 更新动态字段
      this.document.dynamicFields.clear()
      this.dynamicFields.forEach(field => {
        if (field.key.trim() && field.value.trim()) {
          this.document!.addDynamicField(field.key.trim(), field.value.trim())
        }
      })

      // 更新基本信息
      const nameField = this.dynamicFields.find(field => field.key === '姓名')
      if (nameField) {
        this.document.name = nameField.value
      }

      const numberField = this.dynamicFields.find(field => field.key === '证件号码')
      if (numberField) {
        this.document.number = numberField.value
      }

      const expiryField = this.dynamicFields.find(field => field.key === '有效期')
      if (expiryField) {
        this.document.expiryDate = expiryField.value
      }

      // 更新修改时间
      this.document.updateTime = new Date()

      // 获取数据库管理器实例
      const dbManager = DocumentDatabaseManager.getInstance()
      
      // 确保数据库已初始化
      if (!dbManager.isDatabaseInitialized()) {
        const context = this.getUIContext()
        await dbManager.initialize(getContext())
      }
      
      // 保存到数据库
      const success = await dbManager.updateDocument(this.document)
      
      if (success) {
        console.log('证件信息保存到数据库成功:', this.document.name)
        
        // 显示保存成功提示
        this.getUIContext().showAlertDialog({
          title: '保存成功',
          message: '证件信息已保存到数据库',
          primaryButton: {
            value: '确定',
            action: () => {
              this.goBack()
            }
          }
        })
      } else {
        console.error('保存到数据库失败')
        // 显示保存失败提示
        this.getUIContext().showAlertDialog({
          title: '保存失败',
          message: '保存到数据库失败，请重试',
          primaryButton: {
            value: '确定',
            action: () => {
              // 不返回，让用户重试
            }
          }
        })
      }
    } catch (error) {
      console.error('保存编辑失败:', error)
      // 显示错误提示
      this.getUIContext().showAlertDialog({
        title: '保存失败',
        message: '保存过程中发生错误，请重试',
        primaryButton: {
          value: '确定',
          action: () => {
            // 不返回，让用户重试
          }
        }
      })
    }
  }

  private goBack() {
    this.getUIContext().getRouter().back()
  }
} 