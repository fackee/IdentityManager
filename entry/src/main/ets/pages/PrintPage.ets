import { DocumentItem } from '../model/DocumentItem'
import router from '@ohos.router'
import { DocumentPrintParams } from '../types/RouterParams'
import image from '@kit.ImageKit'
import BluetoothPrinterService, { BluetoothDevice, PrintJob } from '../services/BluetoothPrinterService'
import { connection, access } from '@kit.ConnectivityKit'
import BluetoothPermissionUtils from '../utils/BluetoothPermissionUtils'

@Entry
@Component
struct PrintPage {
  @State selectedPrinter: string = ''
  @State paperSize: string = 'A4'
  @State copies: number = 1
  @State mode: string = 'print' // 'print' 或 'list'
  @State documentData: DocumentPrintParams | null = null
  @State documents: DocumentItem[] = []
  
  // 蓝牙打印相关状态
  @State discoveredDevices: BluetoothDevice[] = []
  @State pairedDevices: BluetoothDevice[] = []
  @State isScanning: boolean = false
  @State isConnecting: boolean = false
  @State connectedDevice: BluetoothDevice | null = null
  @State showDeviceList: boolean = false
  @State printProgress: number = 0
  @State printMessage: string = ''
  @State showPrintProgress: boolean = false
  @State bluetoothState: access.BluetoothState = access.BluetoothState.STATE_OFF

  aboutToAppear() {
    // 获取路由参数
    const params = this.getUIContext().getRouter().getParams() as DocumentPrintParams
    if (params) {
      console.log("params document", JSON.stringify(params))
      this.mode = params.mode || 'print'
      if (this.mode === 'print' && params.documentId) {
        // 打印模式，接收证件数据
        this.documentData = {
          documentId: params.documentId,
          documentName: params.documentName,
          documentType: params.documentType,
          documentNumber: params.documentNumber,
          documentExpiry: params.documentExpiry,
          documentImage: params.documentImage
        }
      } else if (this.mode === 'list') {
        // 打印列表模式，加载所有证件
        this.loadDocuments()
      }
    }
    
    // 初始化蓝牙打印服务
    this.initBluetoothPrinter()
  }

  aboutToDisappear() {
    // 页面销毁时清理资源
    if (this.isScanning) {
      this.stopBluetoothScan()
    }
    
    // 清理蓝牙状态监听器
    BluetoothPermissionUtils.offBluetoothStateChange()
  }

  loadDocuments() {
    // 模拟加载证件数据
    this.documents = [
      new DocumentItem(
        '1',
        '张三的身份证',
        '身份证',
        '1101********1234',
        '2025-12-31',
        $r('app.media.background').bundleName,
        new Date(),
        new Date()
      ),
      new DocumentItem(
        '2',
        '李四的护照',
        '护照',
        'E12345678',
        '2026-06-30',
        $r('app.media.background').bundleName,
        new Date(),
        new Date()
      )
    ]
  }

  // 初始化蓝牙打印服务
  initBluetoothPrinter() {
    // 获取已配对设备
    this.pairedDevices = BluetoothPrinterService.getPairedDevices()
    
    // 检查当前连接状态
    const connectionState = BluetoothPrinterService.getConnectionState()
    this.connectedDevice = connectionState.device
    
    // 监听蓝牙状态变化
    BluetoothPermissionUtils.onBluetoothStateChange((state: access.BluetoothState) => {
      console.info('蓝牙状态变化:', state)
      this.bluetoothState = state
      
      // 如果蓝牙关闭，断开打印机连接
      if (state === access.BluetoothState.STATE_OFF && this.connectedDevice) {
        this.disconnectPrinter()
        this.getUIContext().getPromptAction().showToast({
          message: '蓝牙已关闭，打印机连接已断开',
          duration: 2000
        })
      }
    })
    
    // 获取初始蓝牙状态
    this.bluetoothState = BluetoothPermissionUtils.getBluetoothState()
  }

  // 开始扫描蓝牙设备
  async startBluetoothScan() {
    // 检查蓝牙状态
    const bluetoothState = BluetoothPermissionUtils.getBluetoothState()
    
    if (bluetoothState === access.BluetoothState.STATE_OFF) {
      // 蓝牙关闭，尝试开启
      this.getUIContext().showAlertDialog({
        title: '蓝牙未开启',
        message: '检测到蓝牙未开启，是否尝试开启蓝牙？',
        primaryButton: {
          value: '开启蓝牙',
          action: async () => {
            const success = await BluetoothPermissionUtils.enableBluetooth()
            if (success) {
              this.getUIContext().getPromptAction().showToast({
                message: '蓝牙已开启，开始扫描设备',
                duration: 2000
              })
              this.startDeviceScan()
            } else {
              this.getUIContext().getPromptAction().showToast({
                message: '蓝牙开启失败，请手动开启蓝牙',
                duration: 2000
              })
            }
          }
        },
        secondaryButton: {
          value: '取消',
          action: () => {
            console.log('用户取消开启蓝牙')
          }
        }
      })
      return
    }
    
    if (bluetoothState === access.BluetoothState.STATE_TURNING_ON) {
      this.getUIContext().getPromptAction().showToast({
        message: '蓝牙正在开启中，请稍候',
        duration: 2000
      })
      return
    }
    
    if (bluetoothState === access.BluetoothState.STATE_TURNING_OFF) {
      this.getUIContext().getPromptAction().showToast({
        message: '蓝牙正在关闭中，无法扫描设备',
        duration: 2000
      })
      return
    }

    // 蓝牙已开启，开始扫描
    this.startDeviceScan()
  }

  // 开始设备扫描
  private startDeviceScan() {
    this.isScanning = true
    this.discoveredDevices = []
    this.showDeviceList = true
    
    BluetoothPrinterService.startDiscovery((devices: BluetoothDevice[]) => {
      this.discoveredDevices = devices
    })
    
    // 10秒后自动停止扫描
    setTimeout(() => {
      this.stopBluetoothScan()
    }, 10000)
  }

  // 停止扫描蓝牙设备
  stopBluetoothScan() {
    this.isScanning = false
    BluetoothPrinterService.stopDiscovery()
  }

  // 连接打印机
  async connectPrinter(device: BluetoothDevice) {
    this.isConnecting = true
    
    try {
      const success = await BluetoothPrinterService.connectPrinter(device, (connected: boolean) => {
        if (connected) {
          this.connectedDevice = device
          this.showDeviceList = false
          this.getUIContext().getPromptAction().showToast({
            message: `已连接到 ${device.deviceName}`,
            duration: 2000
          })
        } else {
          this.connectedDevice = null
          this.getUIContext().getPromptAction().showToast({
            message: '连接失败',
            duration: 2000
          })
        }
        this.isConnecting = false
      })
      
      if (!success) {
        this.isConnecting = false
      }
    } catch (error) {
      console.error('连接打印机失败:', error)
      this.isConnecting = false
    }
  }

  // 配对设备
  async pairDevice(device: BluetoothDevice) {
    try {
      const success = await BluetoothPrinterService.pairDevice(device)
      if (success) {
        this.getUIContext().getPromptAction().showToast({
          message: '配对成功',
          duration: 2000
        })
        // 刷新已配对设备列表
        this.pairedDevices = BluetoothPrinterService.getPairedDevices()
      } else {
        this.getUIContext().getPromptAction().showToast({
          message: '配对失败',
          duration: 2000
        })
      }
    } catch (error) {
      console.error('配对设备失败:', error)
      this.getUIContext().getPromptAction().showToast({
        message: '配对失败',
        duration: 2000
      })
    }
  }

  // 断开连接
  disconnectPrinter() {
    BluetoothPrinterService.disconnect()
    this.connectedDevice = null
    this.getUIContext().getPromptAction().showToast({
      message: '已断开连接',
      duration: 2000
    })
  }

  build() {
    Stack() {
      Column() {
        // 顶部导航栏
        Row() {
          Button('返回')
            .onClick(() => {
              this.goBack()
            })
          
          Text(this.mode === 'print' ? '打印证件' : '批量打印')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 16 })

          Blank()

          if (this.mode === 'print') {
            Button('打印')
              .backgroundColor('#007DFF')
              .fontColor(Color.White)
              .onClick(() => {
                this.startPrint()
              })
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 12 })

        if (this.mode === 'print') {
          // 单证件打印模式
          this.SinglePrintMode()
        } else {
          // 批量打印模式
          this.BatchPrintMode()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F9FA')

      // 打印进度对话框
      if (this.showPrintProgress) {
        Column() {
          Column() {
            Text('打印进度')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 20 })

            Progress({ value: this.printProgress, total: 100 })
              .width('100%')
              .height(8)
              .margin({ bottom: 16 })

            Text(`${this.printProgress}%`)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 8 })

            Text(this.printMessage)
              .fontSize(14)
              .fontColor('#666666')
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding(24)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ left: 40, right: 40 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  SinglePrintMode() {
    Column() {
      // 蓝牙打印机选择
      Column() {
        // 蓝牙状态显示
        Row() {
          Text('蓝牙状态:')
            .fontSize(14)
            .fontColor('#666666')
          
          Text(this.getBluetoothStateText())
            .fontSize(14)
            .fontColor(this.getBluetoothStateColor())
            .margin({ left: 8 })
          
          Blank()
          
          if (this.bluetoothState === access.BluetoothState.STATE_OFF) {
            Button('开启蓝牙')
              .fontSize(12)
              .backgroundColor('#007DFF')
              .fontColor(Color.White)
              .onClick(async () => {
                const success = await BluetoothPermissionUtils.enableBluetooth()
                if (success) {
                  this.getUIContext().getPromptAction().showToast({
                    message: '蓝牙已开启',
                    duration: 2000
                  })
                }
              })
          }
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#F0F0F0')
        .borderRadius(8)
        .margin({ bottom: 12 })

        Row() {
          Text('蓝牙打印机')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
          
          Blank()
          
          if (this.connectedDevice) {
            Button('断开')
              .fontSize(14)
              .backgroundColor('#FF4444')
              .fontColor(Color.White)
              .onClick(() => {
                this.disconnectPrinter()
              })
          } else {
            Button(this.isScanning ? '停止扫描' : '扫描设备')
              .fontSize(14)
              .backgroundColor(this.isScanning ? '#FF8800' : '#007DFF')
              .fontColor(Color.White)
              .onClick(() => {
                if (this.isScanning) {
                  this.stopBluetoothScan()
                } else {
                  this.startBluetoothScan()
                }
              })
          }
        }
        .width('100%')
        .margin({ bottom: 16 })

        // 当前连接状态
        if (this.connectedDevice) {
          Row() {
            Image($r('app.media.background'))
              .width(40)
              .height(40)
              .borderRadius(20)
            
            Column() {
              Text(this.connectedDevice.deviceName)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
              
              Text('已连接')
                .fontSize(12)
                .fontColor('#4CAF50')
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 12 })
            
            Blank()
            
            Text('●')
              .fontSize(20)
              .fontColor('#4CAF50')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .margin({ bottom: 16 })
        }

        // 设备列表
        if (this.showDeviceList) {
          Column() {
            Text('发现的设备')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 12 })

            List() {
              ForEach(this.discoveredDevices, (device: BluetoothDevice) => {
                ListItem() {
                  Row() {
                    Image($r('app.media.background'))
                      .width(40)
                      .height(40)
                      .borderRadius(20)
                    
                    Column() {
                      Text(device.deviceName)
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)
                      
                      Text(device.deviceId)
                        .fontSize(12)
                        .fontColor('#666666')
                    }
                    .alignItems(HorizontalAlign.Start)
                    .margin({ left: 12 })
                    
                    Blank()
                    
                    if (device.bondState === connection.BondState.BOND_STATE_BONDED) {
                      Button('连接')
                        .fontSize(12)
                        .backgroundColor('#007DFF')
                        .fontColor(Color.White)
                        .onClick(() => {
                          this.connectPrinter(device)
                        })
                    } else {
                      Button('配对')
                        .fontSize(12)
                        .backgroundColor('#FF8800')
                        .fontColor(Color.White)
                        .onClick(() => {
                          this.pairDevice(device)
                        })
                    }
                  }
                  .width('100%')
                  .padding(16)
                  .backgroundColor(Color.White)
                  .borderRadius(8)
                  .margin({ bottom: 8 })
                }
              })
            }
            .width('100%')
            .height(200)
          }
          .width('100%')
          .margin({ bottom: 16 })
        }

        // 已配对设备
        if (this.pairedDevices.length > 0) {
          Column() {
            Text('已配对设备')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 12 })

            List() {
              ForEach(this.pairedDevices, (device: BluetoothDevice) => {
                ListItem() {
                  Row() {
                    Image($r('app.media.background'))
                      .width(40)
                      .height(40)
                      .borderRadius(20)
                    
                    Column() {
                      Text(device.deviceName || device.deviceId)
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)
                      
                      Text('已配对')
                        .fontSize(12)
                        .fontColor('#4CAF50')
                    }
                    .alignItems(HorizontalAlign.Start)
                    .margin({ left: 12 })
                    
                    Blank()
                    
                    Button('连接')
                      .fontSize(12)
                      .backgroundColor('#007DFF')
                      .fontColor(Color.White)
                      .onClick(() => {
                        this.connectPrinter(device)
                      })
                  }
                  .width('100%')
                  .padding(16)
                  .backgroundColor(Color.White)
                  .borderRadius(8)
                  .margin({ bottom: 8 })
                }
              })
            }
            .width('100%')
            .height(120)
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })

      // 打印设置
      Column() {
        Text('打印设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 16 })

        // 纸张大小
        Row() {
          Text('纸张大小')
            .fontSize(16)
            .fontColor('#666666')
            .width('30%')

          Select([
            { value: 'A4' },
            { value: 'A5' },
            { value: '证件尺寸' },
            { value: '自定义' }
          ])
            .selected(0)
            .value(this.paperSize)
            .font({ size: 16 })
            .onSelect((index: number, value: string) => {
              this.paperSize = value
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .margin({ bottom: 8 })

        // 打印份数
        Row() {
          Text('打印份数')
            .fontSize(16)
            .fontColor('#666666')
            .width('30%')

          Row() {
            Button('-')
              .width(40)
              .height(40)
              .backgroundColor('#F0F0F0')
              .fontColor('#666666')
              .onClick(() => {
                if (this.copies > 1) {
                  this.copies--
                }
              })

            Text(this.copies.toString())
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .width(60)
              .textAlign(TextAlign.Center)

            Button('+')
              .width(40)
              .height(40)
              .backgroundColor('#F0F0F0')
              .fontColor('#666666')
              .onClick(() => {
                if (this.copies < 10) {
                  this.copies++
                }
              })
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .margin({ bottom: 8 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })

      // 打印预览
      Column() {
        Text('打印预览')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 16 })

        Image(this.documentData?.documentImage ? this.documentData.documentImage : $r('app.media.background'))
          .width('100%')
          .height(200)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
  }

  @Builder
  BatchPrintMode() {
    Column() {
      // 批量打印说明
      Text('选择要打印的证件')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 16 })

      // 证件列表
      List() {
        ForEach(this.documents, (document: DocumentItem) => {
          ListItem() {
            Row() {
              Checkbox()
                .select(false)
                .onChange((value: boolean) => {
                  console.log('选择证件:', document.id, value)
                })

              Image(document.imageUrl ? document.imageUrl : $r('app.media.background'))
                .width(60)
                .height(45)
                .borderRadius(8)
                .objectFit(ImageFit.Cover)
                .margin({ left: 12 })

              Column() {
                Text(document.name)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .margin({ bottom: 4 })
                
                Text(document.number)
                  .fontSize(14)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 12 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .margin({ bottom: 8 })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)

      // 批量打印按钮
      Button('批量打印')
        .width('100%')
        .height(48)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .margin({ top: 20 })
        .onClick(() => {
          this.batchPrint()
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20 })
  }

  private async startPrint() {
    if (!this.connectedDevice) {
      this.getUIContext().showAlertDialog({
        title: '提示',
        message: '请先连接蓝牙打印机',
        primaryButton: {
          value: '确定',
          action: () => {
            console.log('确定')
          }
        }
      })
      return
    }

    if (!this.documentData) {
      this.getUIContext().showAlertDialog({
        title: '提示',
        message: '没有可打印的文档数据',
        primaryButton: {
          value: '确定',
          action: () => {
            console.log('确定')
          }
        }
      })
      return
    }

    // 显示打印进度对话框
    this.showPrintProgress = true
    this.printProgress = 0
    this.printMessage = '准备打印...'

    try {
      // 构建打印任务
      const printJob: PrintJob = {
        documentId: this.documentData.documentId || '',
        documentName: this.documentData.documentName || '证件打印',
        documentImage: this.documentData.documentImage || '',
        paperSize: this.paperSize,
        copies: this.copies
      }

      console.log('开始蓝牙打印', {
        device: this.connectedDevice.deviceName,
        printJob: printJob
      })

      // 发送打印数据
      const success = await BluetoothPrinterService.sendPrintData(printJob, (progress: number, message: string) => {
        this.printProgress = progress
        this.printMessage = message
      })

      if (success) {
        this.printProgress = 100
        this.printMessage = '打印完成'
        
        setTimeout(() => {
          this.showPrintProgress = false
          this.getUIContext().showAlertDialog({
            title: '打印成功',
            message: '证件已成功打印',
            primaryButton: {
              value: '确定',
              action: () => {
                this.goBack()
              }
            }
          })
        }, 1000)
      } else {
        this.printMessage = '打印失败'
        setTimeout(() => {
          this.showPrintProgress = false
          this.getUIContext().showAlertDialog({
            title: '打印失败',
            message: '打印过程中出现错误，请重试',
            primaryButton: {
              value: '确定',
              action: () => {
                console.log('确定')
              }
            }
          })
        }, 1000)
      }
    } catch (error) {
      console.error('打印异常:', error)
      this.printMessage = '打印异常'
      setTimeout(() => {
        this.showPrintProgress = false
        this.getUIContext().showAlertDialog({
          title: '打印异常',
          message: '打印过程中出现异常，请检查打印机连接',
          primaryButton: {
            value: '确定',
            action: () => {
              console.log('确定')
            }
          }
        })
      }, 1000)
    }
  }

  private batchPrint() {
    console.log('批量打印')
    this.getUIContext().showAlertDialog({
      title: '批量打印',
      message: '正在准备批量打印...',
      primaryButton: {
        value: '确定',
        action: () => {
          console.log('批量打印完成')
          this.goBack()
        }
      }
    })
  }

  private goBack() {
    this.getUIContext().getRouter().back()
  }

  // 获取蓝牙状态文本
  private getBluetoothStateText(): string {
    switch (this.bluetoothState) {
      case access.BluetoothState.STATE_OFF:
        return '已关闭'
      case access.BluetoothState.STATE_TURNING_ON:
        return '正在开启'
      case access.BluetoothState.STATE_ON:
        return '已开启'
      case access.BluetoothState.STATE_TURNING_OFF:
        return '正在关闭'
      case access.BluetoothState.STATE_BLE_TURNING_ON:
        return 'BLE开启中'
      case access.BluetoothState.STATE_BLE_ON:
        return 'BLE已开启'
      case access.BluetoothState.STATE_BLE_TURNING_OFF:
        return 'BLE关闭中'
      default:
        return '未知状态'
    }
  }

  // 获取蓝牙状态颜色
  private getBluetoothStateColor(): string {
    switch (this.bluetoothState) {
      case access.BluetoothState.STATE_OFF:
        return '#FF4444'
      case access.BluetoothState.STATE_TURNING_ON:
        return '#FF8800'
      case access.BluetoothState.STATE_ON:
        return '#4CAF50'
      case access.BluetoothState.STATE_TURNING_OFF:
        return '#FF8800'
      case access.BluetoothState.STATE_BLE_TURNING_ON:
        return '#FF8800'
      case access.BluetoothState.STATE_BLE_ON:
        return '#4CAF50'
      case access.BluetoothState.STATE_BLE_TURNING_OFF:
        return '#FF8800'
      default:
        return '#666666'
    }
  }
}