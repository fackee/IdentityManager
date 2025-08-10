import { DocumentItem } from '../model/DocumentItem'
import { DocumentType } from '../model/DocumentType'

@Entry
@Component
struct Index {
  @State currentTab: number = 0
  @State documents: DocumentItem[] = []
  @State searchText: string = ''
  
  private tabs: string[] = ['全部', '身份证', '护照', '驾驶证', '其他']

  aboutToAppear() {
    this.loadMockData()
  }

  loadMockData() {
    // 模拟数据
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
          })
      }
      .padding({ left: 20, right: 20, top: 12, bottom: 16 })

      // 分类标签
      Tabs({ barPosition: BarPosition.Start, index: this.currentTab }) {
        ForEach(this.tabs, (tab: string, index: number) => {
          TabContent() {
            this.DocumentList()
          }.tabBar(tab)
        })
      }
      .width('100%')
      .layoutWeight(1)
      .onChange((index: number) => {
        this.currentTab = index
      })

      // 底部导航栏
      Row() {
        ForEach(['首页', '编辑工具', '打印', '设置'], (tab: string, index: number) => {
          Column() {
            Text(tab)
              .fontSize(12)
              .fontColor(index === 0 ? '#007DFF' : '#666666')
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .onClick(() => {
            this.navigateToTab(index)
          })
        })
      }
      .width('100%')
      .height(60)
      .backgroundColor(Color.White)
      .border({ width: { top: 1 }, color: '#E0E0E0' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }

  @Builder
  DocumentList() {
    if (this.documents.length === 0) {
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
      Image(document.imageUrl)
        .width(80)
        .height(60)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)

      Column() {
        Text(document.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 4 })
        
        Text(document.number)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 4 })
        
        Text(`有效期至：${document.expiryDate}`)
          .fontSize(12)
          .fontColor('#999999')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      Column() {
        Button('编辑')
          .width(60)
          .height(32)
          .fontSize(12)
          .backgroundColor('#F0F0F0')
          .margin({ bottom: 8 })
          .onClick(() => {
            this.editDocument(document)
          })

        Button('打印')
          .width(60)
          .height(32)
          .fontSize(12)
          .backgroundColor('#F0F0F0')
          .onClick(() => {
            this.printDocument(document)
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
  }

  private viewDocument(document: DocumentItem) {
    console.log('查看证件', document.id)
  }

  private editDocument(document: DocumentItem) {
    console.log('编辑证件', document.id)
  }

  private printDocument(document: DocumentItem) {
    console.log('打印证件', document.id)
  }

  private navigateToTab(index: number) {
    switch (index) {
      case 0: // 首页
        console.log('已在首页')
        break
      case 1: // 编辑工具
        console.log('导航到编辑工具')
        break
      case 2: // 打印
        console.log('导航到打印页面')
        break
      case 3: // 设置
        console.log('导航到设置页面')
        break
    }
  }
}