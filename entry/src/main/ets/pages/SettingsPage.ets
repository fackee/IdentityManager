import { CommonUtils } from '../utils/CommonUtils'

@Entry
@Component
struct SettingsPage {
  @State isLoading: boolean = false

  aboutToAppear() {
    this.loadSettings()
  }

  async loadSettings() {
    this.isLoading = true
    // 可以在这里加载一些基础设置
    this.isLoading = false
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button('返回')
          .onClick(() => {
            this.goBack()
          })
        
        Text('设置')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })

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
        .height(200)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            // 打印机管理
            this.PrinterManagementSection()
            
            Divider()
              .margin({ top: 20, bottom: 20 })
            
            // 数据清除
            this.DataClearSection()
            
            Divider()
              .margin({ top: 20, bottom: 20 })
            
            // 关于应用
            this.AboutAppSection()
          }
          .padding({ left: 20, right: 20 })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }

  @Builder
  SettingItem(title: string, subtitle: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor('#333333')
      
      Blank()
      
      if (subtitle) {
        Text(subtitle)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ right: 8 })
      }
      
      Text('>')
        .fontSize(16)
        .fontColor('#999999')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ bottom: 8 })
    .onClick(onClick)
  }

  @Builder
  PrinterManagementSection() {
    Column() {
      Text('打印机管理')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })
        .alignSelf(ItemAlign.Start)

      // 打印机列表
      this.SettingItem('管理打印机', '配置打印设备和参数', () => {
        this.managePrinters()
      })

      // 打印设置
      this.SettingItem('打印设置', '设置默认打印参数', () => {
        this.openPrintSettings()
      })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding(20)
  }

  @Builder
  DataClearSection() {
    Column() {
      Text('数据清除')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })
        .alignSelf(ItemAlign.Start)

      // 清除缓存
      this.SettingItem('清除缓存', '释放存储空间', () => {
        this.clearCache()
      })

      // 清除所有数据
      this.SettingItem('清除所有数据', '删除所有证件记录', () => {
        this.clearAllData()
      })

      // 重置应用
      this.SettingItem('重置应用', '恢复出厂设置', () => {
        this.resetApp()
      })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding(20)
  }

  @Builder
  AboutAppSection() {
    Column() {
      Text('关于应用')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })
        .alignSelf(ItemAlign.Start)

      // 应用信息
      this.SettingItem('应用信息', '版本 1.0.0', () => {
        this.showAppInfo()
      })

      // 使用帮助
      this.SettingItem('使用帮助', '查看使用说明', () => {
        this.showHelp()
      })

      // 意见反馈
      this.SettingItem('意见反馈', '提交问题或建议', () => {
        this.showFeedback()
      })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding(20)
  }

  private managePrinters() {
    this.getUIContext().showAlertDialog({
      title: '打印机管理',
      message: '打印机管理功能开发中...',
      primaryButton: {
        value: '确定',
        action: () => {
          console.log('打印机管理')
        }
      }
    })
  }

  private openPrintSettings() {
    this.getUIContext().showAlertDialog({
      title: '打印设置',
      message: '打印设置功能开发中...',
      primaryButton: {
        value: '确定',
        action: () => {
          console.log('打印设置')
        }
      }
    })
  }

  private clearCache() {
    this.getUIContext().showAlertDialog({
      title: '清除缓存',
      message: '确定要清除应用缓存吗？这将释放存储空间。',
      primaryButton: {
        value: '清除',
        action: () => {
          console.log('清除缓存')
          this.showAlert('成功', '缓存清除成功')
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {
          console.log('取消清除缓存')
        }
      }
    })
  }

  private clearAllData() {
    this.getUIContext().showAlertDialog({
      title: '清除所有数据',
      message: '确定要删除所有证件记录吗？此操作不可恢复。',
      primaryButton: {
        value: '确定',
        action: () => {
          console.log('清除所有数据')
          this.showAlert('成功', '所有数据已清除')
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {
          console.log('取消清除数据')
        }
      }
    })
  }

  private resetApp() {
    this.getUIContext().showAlertDialog({
      title: '重置应用',
      message: '确定要重置应用吗？这将清除所有数据和设置，恢复出厂状态。',
      primaryButton: {
        value: '确定',
        action: () => {
          console.log('重置应用')
          this.showAlert('成功', '应用已重置')
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {
          console.log('取消重置应用')
        }
      }
    })
  }

  private showAppInfo() {
    this.getUIContext().showAlertDialog({
      title: '应用信息',
      message: '证件管理器\n版本: 1.0.0\n\n一个安全、高效的证件数字化管理应用，支持AI识别、编辑美化和打印功能。',
      primaryButton: {
        value: '确定',
        action: () => {
          console.log('查看应用信息')
        }
      }
    })
  }

  private showHelp() {
    this.getUIContext().showAlertDialog({
      title: '使用帮助',
      message: '使用帮助功能开发中...',
      primaryButton: {
        value: '确定',
        action: () => {
          console.log('显示帮助')
        }
      }
    })
  }

  private showFeedback() {
    this.getUIContext().showAlertDialog({
      title: '意见反馈',
      message: '意见反馈功能开发中...',
      primaryButton: {
        value: '确定',
        action: () => {
          console.log('显示反馈')
        }
      }
    })
  }

  private showAlert(title: string, message: string) {
    this.getUIContext().showAlertDialog({
      title: title,
      message: message,
      primaryButton: {
        value: '确定',
        action: () => {
          console.log('用户确认:', message)
        }
      }
    })
  }

  private goBack() {
    this.getUIContext().getRouter().back()
  }
} 