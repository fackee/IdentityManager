import { CommonUtils,UserSetting } from '../utils/CommonUtils'
import { DocumentRecognitionService } from '../services/DocumentRecognitionService'

@Entry
@Component
struct SettingsPage {
  @State isLoggedIn: boolean = false
  @State enableCloudSync: boolean = false
  @State savedPrinters: string[] = ['HP LaserJet Pro', 'Canon PIXMA']
  
  @State proxyStatus: boolean = false
  
  @State userSettings: UserSetting = new UserSetting(true, 0.8, true)
  
  @State isLoading: boolean = false
  @State showApiKey: boolean = false

  aboutToAppear() {
    this.loadSettings()
  }

  async loadSettings() {
    this.isLoading = true
    
    // 测试代理服务连接
    this.proxyStatus = await DocumentRecognitionService.testProxyConnection()
    
    // 加载用户设置
    this.userSettings = await CommonUtils.getUserSettings()
    
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
            // 代理服务状态
            this.ProxyStatusSection()
            
            Divider()
              .margin({ top: 20, bottom: 20 })
            
            // 用户设置
            this.UserSettingsSection()
            
            Divider()
              .margin({ top: 20, bottom: 20 })
            
            // 其他设置
            this.OtherSettingsSection()
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
  ProxyStatusSection() {
    Column() {
      Text('代理服务状态')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })
        .alignSelf(ItemAlign.Start)

      // 服务状态
      Row() {
        Text('服务状态')
          .fontSize(16)
          .fontColor('#333333')
        
        Blank()
        
        Row() {
          Circle()
            .width(12)
            .height(12)
            .fill(this.proxyStatus ? '#28A745' : '#DC3545')
            .margin({ right: 8 })
          
          Text(this.proxyStatus ? '正常' : '异常')
            .fontSize(14)
            .fontColor(this.proxyStatus ? '#28A745' : '#DC3545')
        }
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 服务信息
      Column() {
        Text('服务地址')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 8 })
          .alignSelf(ItemAlign.Start)
        
        Text('http://47.111.83.157/llm')
          .fontSize(14)
          .fontColor('#333333')
          .backgroundColor('#F8F9FA')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .borderRadius(8)
      }
      .margin({ bottom: 16 })

      // 重新测试按钮
      Button('重新测试连接')
        .width('100%')
        .height(48)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .onClick(() => {
          this.testProxyConnection()
        })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding(20)
  }

  @Builder
  UserSettingsSection() {
    Column() {
      Text('用户设置')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })
        .alignSelf(ItemAlign.Start)

      // 自动保存
      Row() {
        Text('自动保存识别结果')
          .fontSize(16)
          .fontColor('#333333')
        
        Blank()
        
        Toggle({ type: ToggleType.Switch, isOn: this.userSettings.autoSave })
          .onChange((isOn: boolean) => {
            this.userSettings.autoSave = isOn
          })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 图片质量
      Column() {
        Row() {
          Text('图片质量')
            .fontSize(16)
            .fontColor('#333333')
          
          Blank()
          
          Text(`${(this.userSettings.imageQuality * 100).toFixed(0)}%`)
            .fontSize(14)
            .fontColor('#666666')
        }
        .width('100%')
        .margin({ bottom: 8 })
        
        Slider({
          value: this.userSettings.imageQuality,
          min: 0.1,
          max: 1.0,
          step: 0.1
        })
          .width('100%')
          .onChange((value: number) => {
            this.userSettings.imageQuality = value
          })
      }
      .margin({ bottom: 16 })

      // 启用备份
      Row() {
        Text('启用自动备份')
          .fontSize(16)
          .fontColor('#333333')
        
        Blank()
        
        Toggle({ type: ToggleType.Switch, isOn: this.userSettings.enableBackup })
          .onChange((isOn: boolean) => {
            this.userSettings.enableBackup = isOn
          })
      }
      .width('100%')
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding(20)
  }

  @Builder
  OtherSettingsSection() {
    Column() {
      Text('其他设置')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })
        .alignSelf(ItemAlign.Start)

      // 保存设置按钮
      Button('保存设置')
        .width('100%')
        .height(48)
        .backgroundColor('#28A745')
        .fontColor(Color.White)
        .margin({ bottom: 16 })
        .onClick(() => {
          this.saveSettings()
        })

      // 清除配置按钮
      Button('清除所有配置')
        .width('100%')
        .height(48)
        .backgroundColor('#DC3545')
        .fontColor(Color.White)
        .margin({ bottom: 16 })
        .onClick(() => {
          this.clearAllSettings()
        })

      // 关于应用
      Button('关于应用')
        .width('100%')
        .height(48)
        .backgroundColor('#6C757D')
        .fontColor(Color.White)
        .onClick(() => {
          this.showAboutDialog()
        })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding(20)
  }

  private manageAccount() {
    if (this.isLoggedIn) {
      // 显示账号信息或退出登录
      this.getUIContext().showAlertDialog({
        title: '账号管理',
        message: '是否要退出登录？',
        primaryButton: {
          value: '退出登录',
          action: () => {
            this.isLoggedIn = false
            console.log('退出登录')
          }
        },
        secondaryButton: {
          value: '取消',
          action: () => {
            console.log('取消')
          }
        }
      })
    } else {
      // 跳转到登录页面
      console.log('跳转到登录页面')
    }
  }

  private openPrivacySettings() {
    console.log('打开隐私设置')
  }

  private toggleCloudSync(isOn: boolean) {
    if (isOn && !this.isLoggedIn) {
      // 如果开启云同步但未登录，提示登录
      this.getUIContext().showAlertDialog({
        title: '需要登录',
        message: '开启云同步需要先登录账号',
        primaryButton: {
          value: '去登录',
          action: () => {
            console.log('跳转到登录页面')
          }
        },
        secondaryButton: {
          value: '取消',
          action: () => {
            this.enableCloudSync = false
          }
        }
      })
    } else {
      console.log('云同步状态:', isOn)
    }
  }

  private managePrinters() {
    console.log('管理打印机')
  }

  private showAbout() {
    this.getUIContext().showAlertDialog({
      title: '关于证件管理',
      message: '版本：1.0.0\n\n一个安全、高效的证件数字化管理应用，支持AI识别、编辑美化和打印功能。',
      primaryButton: {
        value: '确定',
        action: () => {
          console.log('确定')
        }
      }
    })
  }

  private showHelp() {
    console.log('显示帮助与反馈')
  }

  private clearCache() {
    this.getUIContext().showAlertDialog({
      title: '清除缓存',
      message: '确定要清除应用缓存吗？这将释放156MB存储空间。',
      primaryButton: {
        value: '清除',
        action: () => {
          console.log('清除缓存')
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {
          console.log('取消')
        }
      }
    })
  }

  private async testProxyConnection() {
    this.showAlert('测试中', '正在测试代理服务连接...')
    
    try {
      const isConnected = await DocumentRecognitionService.testProxyConnection()
      this.proxyStatus = isConnected
      
      if (isConnected) {
        this.showAlert('成功', '代理服务连接正常')
      } else {
        this.showAlert('错误', '代理服务连接失败')
      }
    } catch (error) {
      this.proxyStatus = false
      this.showAlert('错误', '代理服务连接测试失败')
    }
  }

  private async saveSettings() {
    try {
      // 保存用户设置
      const userSettingsSaved = await CommonUtils.saveUserSettings(this.userSettings)
      
      if (userSettingsSaved) {
        this.showAlert('成功', '设置保存成功')
      } else {
        this.showAlert('错误', '设置保存失败')
      }
    } catch (error) {
      console.error('保存设置失败:', error)
      this.showAlert('错误', '保存设置失败')
    }
  }

  private async clearAllSettings() {
    this.getUIContext().showAlertDialog({
      title: '确认清除',
      message: '确定要清除所有配置吗？此操作不可恢复。',
      primaryButton: {
        value: '确定',
        action: async () => {
          try {
            const success = await CommonUtils.clearAllConfig()
            if (success) {
              // 重新加载默认设置
              await this.loadSettings()
              this.showAlert('成功', '所有配置已清除')
            } else {
              this.showAlert('错误', '清除配置失败')
            }
          } catch (error) {
            console.error('清除配置失败:', error)
            this.showAlert('错误', '清除配置失败')
          }
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {
          console.log('用户取消清除配置')
        }
      }
    })
  }

  private showAboutDialog() {
    this.getUIContext().showAlertDialog({
      title: '关于证件管理器',
      message: '版本: 1.0.0\n\n一个基于大模型的智能证件识别和管理应用。\n\n支持识别身份证、护照、驾驶证、银行卡等多种证件类型。',
      primaryButton: {
        value: '确定',
        action: () => {
          console.log('用户确认关于信息')
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