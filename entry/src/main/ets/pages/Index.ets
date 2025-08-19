import { DocumentItem } from '../model/DocumentItem'
import { DocumentUtils } from '../utils/DocumentUtils'
import { DocumentDatabaseManager } from '../manager/DocumentDatabaseManager'
import { DocumentTypeInfo } from '../types/DocumentRecognition'

@Entry
@Component
struct Index {
  @State currentTab: number = 0
  @State documents: DocumentItem[] = []
  @State searchText: string = ''
  @State documentTypes: DocumentTypeInfo[] = []
  @State tabs: string[] = ['全部']
  @State isLoading: boolean = false
  
  private documentDatabaseManager: DocumentDatabaseManager = DocumentDatabaseManager.getInstance()

  aboutToAppear() {
    this.initializeData()
  }

  async initializeData() {
    try {
      this.isLoading = true
      
      // 初始化数据库
      const initSuccess = await this.documentDatabaseManager.initialize(getContext())
      if (!initSuccess) {
        console.error('数据库初始化失败')
        this.isLoading = false
        return
      }
      
      // 加载文档类型
      await this.loadDocumentTypes()
      
      // 加载文档列表
      await this.loadDocuments()
      
      this.isLoading = false
    } catch (error) {
      console.error('初始化数据失败:', error)
      this.isLoading = false
    }
  }

  async loadDocumentTypes() {
    try {
      const types = await this.documentDatabaseManager.getDocumentTypes()
      
      // 构建标签页数组：全部 + 动态类型
      this.tabs = ['全部']
      this.documentTypes = types
      
      types.forEach(type => {
        this.tabs.push(type.type)
      })
      
      console.log('文档类型加载成功:', this.tabs)
    } catch (error) {
      console.error('加载文档类型失败:', error)
    }
  }

  async loadDocuments() {
    try {
      const currentType = this.tabs[this.currentTab]
      let documents: DocumentItem[] = []
      
      if (currentType === '全部') {
        documents = await this.documentDatabaseManager.loadDocuments()
      } else {
        documents = await this.documentDatabaseManager.getDocumentsByType(currentType)
      }
      
      // 如果有搜索文本，进行过滤
      if (this.searchText) {
        documents = documents.filter(doc => 
          doc.name.includes(this.searchText) || 
          doc.number.includes(this.searchText) ||
          doc.type.includes(this.searchText)
        )
      }
      
      this.documents = documents
      console.log('文档加载成功', JSON.stringify(this.documents))
    } catch (error) {
      console.error('加载文档失败:', error)
      this.documents = []
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('我的证件')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
        
        Blank()
        
        Button({ type: ButtonType.Circle }) {
          Text('+')
            .fontSize(20)
            .fontColor(Color.White)
        }
        .width(48)
        .height(48)
        .backgroundColor('#007DFF')
        .onClick(() => {
          this.addDocument()
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })

      // 搜索栏
      Row() {
        TextInput({ placeholder: '搜索证件...', text: this.searchText })
          .width('100%')
          .height(40)
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.searchText = value
            this.loadDocuments()
          })
      }
      .padding({ left: 20, right: 20, top: 12, bottom: 16 })

      // 分类标签
      if (this.tabs.length > 1) {
        Tabs({ barPosition: BarPosition.Start, index: this.currentTab }) {
          ForEach(this.tabs, (tab: string, index: number) => {
            TabContent() {
              this.DocumentList()
            }.tabBar(this.TabBar(tab, index))
          })
        }
        .width('100%')
        .layoutWeight(1)
        .onChange((index: number) => {
          this.currentTab = index
          this.loadDocuments()
        })
      } else {
        // 如果没有动态类型，显示简单的文档列表
        Column() {
          this.DocumentList()
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }

  @Builder
  TabBar(tab: string, index: number) {
    Row() {
      if (tab === '全部') {
        Text('全部')
          .fontSize(14)
          .fontColor(this.currentTab === index ? '#007DFF' : '#666666')
      } else {
        // 显示动态类型标签
        this.DynamicTabContent(tab, index)
      }
    }
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  DynamicTabContent(tab: string, index: number) {
    Text(this.getTabDisplayText(tab))
      .fontSize(14)
      .fontColor(this.currentTab === index ? '#007DFF' : '#666666')
  }

  private getTabDisplayText(tab: string): string {
    const typeInfo = this.documentTypes.find(type => type.type === tab)
    if (typeInfo) {
      return `${typeInfo.icon} ${typeInfo.type}(${typeInfo.count})`
    }
    return tab
  }

  @Builder
  DocumentList() {
    if (this.isLoading) {
      Column() {
        LoadingProgress()
          .width(50)
          .height(50)
          .margin({ bottom: 16 })
        Text('加载中...')
          .fontSize(16)
          .fontColor('#666666')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    } else if (this.documents.length === 0) {
      Column() {
        Text('暂无证件')
          .fontSize(18)
          .fontColor('#666666')
        Text('点击右上角添加按钮上传证件')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 8 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    } else {
      List() {
        ForEach(this.documents, (document: DocumentItem) => {
          ListItem() {
            this.DocumentCard(document)
          }
        })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16 })
    }
  }

  @Builder
  DocumentCard(document: DocumentItem) {
    Row() {
      Stack() {
        Image(document.imageUrl ? document.imageUrl : $r('app.media.background'))
          .width(80)
          .height(60)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)

        // 证件状态指示器
        Text(DocumentUtils.getDocumentStatusText(document.expiryDate))
          .fontSize(10)
          .fontColor(Color.White)
          .backgroundColor(DocumentUtils.getDocumentStatusColor(document.expiryDate))
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
          .borderRadius(4)
          .position({ x: 0, y: 0 })
      }
      .width(80)
      .height(60)

      Column() {
        Row() {
          Text(DocumentUtils.getDocumentTypeIcon(document.type))
            .fontSize(16)
            .margin({ right: 8 })
          
          Text(document.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
        }
        .margin({ bottom: 4 })
        
        Text(DocumentUtils.formatDocumentNumber(document.number))
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 4 })
        
        Row() {
          Text(`有效期至：${document.expiryDate}`)
            .fontSize(12)
            .fontColor('#999999')
          
          Blank()
          
          Text(DocumentUtils.getDocumentStatusText(document.expiryDate))
            .fontSize(10)
            .fontColor(Color.White)
            .backgroundColor(DocumentUtils.getDocumentStatusColor(document.expiryDate))
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(8)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      Column() {
        Button('打印')
          .width(60)
          .height(32)
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('#007DFF')
          .borderRadius(16)
          .onClick(() => {
            this.printDocument(document)
          })
          .margin({ bottom: 8 })
        
        Button('删除')
          .width(60)
          .height(32)
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('#FF4444')
          .borderRadius(16)
          .onClick(() => {
            this.deleteDocument(document)
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 12 })
    .onClick(() => {
      this.viewDocument(document)
    })
  }

  private addDocument() {
    console.log('添加证件')
    // 跳转到上传页面
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/UploadPage'
    })
  }

  private viewDocument(document: DocumentItem) {
    console.log('查看证件', document.id)
    // 跳转到证件详情页面
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/DocumentDetailPage',
      params: {
        documentId: document.id,
        documentName: document.name,
        documentType: document.type,
        documentNumber: document.number,
        documentExpiry: document.expiryDate,
        documentImage: document.imageUrl,
        createTime: document.createTime,
        updateTime: document.updateTime,
        dynamicFields: document.dynamicFields
      }
    })
  }

  private printDocument(document: DocumentItem) {
    console.log('打印证件', document.id)
    // 跳转到打印页面并传递证件数据
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/PrintPage',
      params: {
        documentId: document.id,
        documentName: document.name,
        documentType: document.type,
        documentNumber: document.number,
        documentExpiry: document.expiryDate,
        documentImage: document.imageUrl
      }
    })
  }

  private async deleteDocument(document: DocumentItem) {
    try {
      // 显示确认对话框
      this.getUIContext().showAlertDialog({
        title: '确认删除',
        message: `确定要删除证件"${document.name}"吗？此操作不可撤销。`,
        primaryButton: {
          value: '取消',
          action: () => {
            console.log('用户取消删除')
          }
        },
        secondaryButton: {
          value: '删除',
          fontColor: '#FF4444',
          action: async () => {
            try {
              // 从数据库删除证件
              const success = await this.documentDatabaseManager.deleteDocument(document.id)
              if (success) {
                console.log('证件删除成功')
                // 重新加载文档列表
                await this.loadDocuments()
                // 显示成功提示
                this.getUIContext().getPromptAction().showToast({
                  message: '证件删除成功'
                })
              } else {
                console.error('证件删除失败')
                this.getUIContext().getPromptAction().showToast({
                  message: '删除失败，请重试'
                })
              }
            } catch (error) {
              console.error('删除证件时发生错误:', error)
              this.getUIContext().getPromptAction().showToast({
                message: '删除失败，请重试'
              })
            }
          }
        }
      })
    } catch (error) {
      console.error('显示删除确认对话框失败:', error)
    }
  }

  private navigateToTab(index: number) {
    switch (index) {
      case 0: // 首页
        console.log('已在首页')
        break
      case 1: // 设置
        console.log('导航到设置页面')
        // 跳转到设置页面
        this.getUIContext().getRouter().pushUrl({
          url: 'pages/SettingsPage'
        })
        break
    }
  }
}