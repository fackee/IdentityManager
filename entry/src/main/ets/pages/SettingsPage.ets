import router from '@ohos.router'

@Entry
@Component
struct SettingsPage {
  @State isLoggedIn: boolean = false
  @State enableCloudSync: boolean = false
  @State savedPrinters: string[] = ['HP LaserJet Pro', 'Canon PIXMA']

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

      // 设置列表
      List() {
        // 账号管理
        ListItem() {
          this.SettingItem('账号管理', this.isLoggedIn ? '已登录' : '未登录', () => {
            this.manageAccount()
          })
        }

        // 隐私设置
        ListItem() {
          this.SettingItem('隐私设置', '', () => {
            this.openPrivacySettings()
          })
        }

        // 云同步开关
        ListItem() {
          Row() {
            Text('云同步')
              .fontSize(16)
              .fontColor('#333333')
            
            Blank()
            
            Toggle({ type: ToggleType.Switch, isOn: this.enableCloudSync })
              .onChange((isOn: boolean) => {
                this.enableCloudSync = isOn
                this.toggleCloudSync(isOn)
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .margin({ bottom: 8 })
        }

        // 打印机管理
        ListItem() {
          this.SettingItem('打印机管理', `${this.savedPrinters.length}台设备`, () => {
            this.managePrinters()
          })
        }

        // 关于
        ListItem() {
          this.SettingItem('关于', '版本 1.0.0', () => {
            this.showAbout()
          })
        }

        // 帮助与反馈
        ListItem() {
          this.SettingItem('帮助与反馈', '', () => {
            this.showHelp()
          })
        }

        // 清除缓存
        ListItem() {
          this.SettingItem('清除缓存', '156MB', () => {
            this.clearCache()
          })
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
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

  private goBack() {
    this.getUIContext().getRouter().back()
  }
} 