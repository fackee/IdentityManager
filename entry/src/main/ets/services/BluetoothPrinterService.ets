import { connection, socket } from '@kit.ConnectivityKit'
import { BusinessError } from '@kit.BasicServicesKit'

export interface BluetoothDevice {
  deviceId: string
  deviceName: string
  deviceClass: number
  bondState: connection.BondState
  rssi: number
}

export interface PrintJob {
  documentId: string
  documentName: string
  documentImage: string
  paperSize: string
  copies: number
}

export interface ConnectionState {
  connected: boolean
  device: BluetoothDevice | null
}

export class BluetoothPrinterService {
  private static instance: BluetoothPrinterService
  private clientNumber: number = -1
  private isConnected: boolean = false
  private currentDevice: BluetoothDevice | null = null
  private discoveredDevices: BluetoothDevice[] = []
  private deviceFoundCallback?: (devices: BluetoothDevice[]) => void
  private connectionStateChangeCallback?: (connected: boolean, device?: BluetoothDevice) => void
  private printProgressCallback?: (progress: number, message: string) => void

  public static getInstance(): BluetoothPrinterService {
    if (!BluetoothPrinterService.instance) {
      BluetoothPrinterService.instance = new BluetoothPrinterService()
    }
    return BluetoothPrinterService.instance
  }

  // 开始扫描蓝牙设备
  public startDiscovery(callback?: (devices: BluetoothDevice[]) => void): void {
    this.deviceFoundCallback = callback
    this.discoveredDevices = []

    try {
      // 监听设备发现事件
      connection.on('bluetoothDeviceFind', (data: Array<string>) => {
        this.onDeviceFound(data)
      })
      
      // 检查是否正在扫描
      if (!connection.isBluetoothDiscovering()) {
        connection.startBluetoothDiscovery()
        console.info('开始扫描蓝牙设备')
      }
    } catch (err) {
      console.error('开始扫描失败:', (err as BusinessError).message)
    }
  }

  // 停止扫描
  public stopDiscovery(): void {
    try {
      if (connection.isBluetoothDiscovering()) {
        connection.stopBluetoothDiscovery()
        console.info('停止扫描蓝牙设备')
      }
      connection.off('bluetoothDeviceFind')
    } catch (err) {
      console.error('停止扫描失败:', (err as BusinessError).message)
    }
  }

  // 设备发现回调
  private onDeviceFound(data: Array<string>): void {
    console.info('发现设备:', JSON.stringify(data))
    
    // 解析设备信息
    if (data && data.length >= 4) {
      const device: BluetoothDevice = {
        deviceId: data[0],
        deviceName: data[1] || '未知设备',
        deviceClass: parseInt(data[2]) || 0,
        bondState: parseInt(data[3]) as connection.BondState || connection.BondState.BOND_STATE_INVALID,
        rssi: parseInt(data[4]) || 0
      }
      
      // 过滤打印机设备（根据设备类或名称）
      if (this.isPrinterDevice(device)) {
        this.addOrUpdateDevice(device)
      }
    }
  }

  // 判断是否为打印机设备
  private isPrinterDevice(device: BluetoothDevice): boolean {
    // 根据设备名称判断
    const printerKeywords = ['printer', 'print', '打印机', 'HP', 'Canon', 'Epson', 'Brother']
    const deviceName = device.deviceName.toLowerCase()
    
    return printerKeywords.some(keyword => 
      deviceName.includes(keyword.toLowerCase())
    )
  }

  // 添加或更新设备列表
  private addOrUpdateDevice(device: BluetoothDevice): void {
    const existingIndex = this.discoveredDevices.findIndex(d => d.deviceId === device.deviceId)
    
    if (existingIndex >= 0) {
      this.discoveredDevices[existingIndex] = device
    } else {
      this.discoveredDevices.push(device)
    }
    
    // 通知回调
    if (this.deviceFoundCallback) {
      this.deviceFoundCallback([...this.discoveredDevices])
    }
  }

  // 获取已配对设备
  public getPairedDevices(): BluetoothDevice[] {
    try {
      const pairedDeviceIds = connection.getPairedDevices()
      return pairedDeviceIds.map(deviceId => {
        const pairState = connection.getPairState(deviceId)
        return {
          deviceId: deviceId,
          deviceName: deviceId, // 已配对设备可能没有名称
          deviceClass: 0,
          bondState: pairState,
          rssi: 0
        } as BluetoothDevice
      })
    } catch (err) {
      console.error('获取已配对设备失败:', (err as BusinessError).message)
      return []
    }
  }

  // 配对设备
  public async pairDevice(device: BluetoothDevice): Promise<boolean> {
    return new Promise((resolve) => {
      try {
        // 监听配对状态变化
        connection.on('bondStateChange', (data: connection.BondStateParam) => {
          if (data.deviceId === device.deviceId) {
            if (data.state === connection.BondState.BOND_STATE_BONDED) {
              console.info('设备配对成功:', device.deviceName)
              resolve(true)
            } if (data.state === connection.BondState.BOND_STATE_BONDING) {
              console.info('设备配对中:', device.deviceName)
              resolve(false)
            } else if (data.state === connection.BondState.BOND_STATE_INVALID) {
              console.error('设备配对失败:', device.deviceName)
              resolve(false)
            }
          }
        })

        // 发起配对
        connection.pairDevice(device.deviceId).then(() => {
          console.info('发起配对:', device.deviceName)
        }).catch((error: BusinessError) => {
          console.error('配对失败:', error.message)
          resolve(false)
        })
      } catch (err) {
        console.error('配对异常:', (err as BusinessError).message)
        resolve(false)
      }
    })
  }

  // 连接打印机
  public async connectPrinter(device: BluetoothDevice, onStateChange?: (connected: boolean) => void): Promise<boolean> {
    this.connectionStateChangeCallback = onStateChange
    
    return new Promise((resolve) => {
      try {
        // 配置SPP连接参数
        const option: socket.SppOptions = {
          uuid: '00001101-0000-1000-8000-00805F9B34FB', // 标准SPP UUID
          secure: false,
          type: socket.SppType.SPP_RFCOMM
        }

        console.info('连接打印机:', device.deviceName)
        
        socket.sppConnect(device.deviceId, option, (err, num: number) => {
          if (err) {
            console.error('连接失败:', (err as BusinessError).message)
            this.isConnected = false
            this.currentDevice = null
            if (this.connectionStateChangeCallback) {
              this.connectionStateChangeCallback(false)
            }
            resolve(false)
          } else {
            console.info('连接成功, clientNumber:', num)
            this.clientNumber = num
            this.isConnected = true
            this.currentDevice = device
            
            // 开始监听数据
            this.startDataListener()
            
            if (this.connectionStateChangeCallback) {
              this.connectionStateChangeCallback(true, device)
            }
            resolve(true)
          }
        })
      } catch (err) {
        console.error('连接异常:', (err as BusinessError).message)
        resolve(false)
      }
    })
  }

  // 开始数据监听
  private startDataListener(): void {
    if (this.clientNumber === -1) return
    
    try {
      socket.on('sppRead', this.clientNumber, (dataBuffer: ArrayBuffer) => {
        const data = new Uint8Array(dataBuffer)
        console.info('收到打印机数据:', JSON.stringify(data))
        this.handlePrinterResponse(data)
      })
    } catch (err) {
      console.error('启动数据监听失败:', (err as BusinessError).message)
    }
  }

  // 处理打印机响应
  private handlePrinterResponse(data: Uint8Array): void {
    // 根据打印机协议处理响应
    if (data.length > 0) {
      const status = data[0]
      switch (status) {
        case 0x00: // 打印成功
          if (this.printProgressCallback) {
            this.printProgressCallback(100, '打印完成')
          }
          break
        case 0x01: // 打印中
          if (this.printProgressCallback) {
            this.printProgressCallback(50, '正在打印...')
          }
          break
        case 0xFF: // 错误
          if (this.printProgressCallback) {
            this.printProgressCallback(0, '打印错误')
          }
          break
      }
    }
  }

  // 发送打印数据
  public async sendPrintData(printJob: PrintJob, onProgress?: (progress: number, message: string) => void): Promise<boolean> {
    if (!this.isConnected || this.clientNumber === -1) {
      console.error('打印机未连接')
      return false
    }

    this.printProgressCallback = onProgress

    return new Promise((resolve) => {
      try {
        // 构建打印命令
        const printCommands = this.buildPrintCommands(printJob)
        
        if (this.printProgressCallback) {
          this.printProgressCallback(10, '准备打印数据...')
        }

        // 发送打印命令
        for (let i = 0; i < printCommands.length; i++) {
          const command = printCommands[i]
          
          setTimeout(() => {
            try {
              socket.sppWrite(this.clientNumber, command)
              
              const progress = 10 + Math.floor((i + 1) / printCommands.length * 80)
              if (this.printProgressCallback) {
                this.printProgressCallback(progress, `发送打印数据 ${i + 1}/${printCommands.length}`)
              }
              
              // 最后一个命令发送完成
              if (i === printCommands.length - 1) {
                setTimeout(() => {
                  resolve(true)
                }, 1000)
              }
            } catch (err) {
              console.error('发送打印数据失败:', (err as BusinessError).message)
              resolve(false)
            }
          }, i * 100) // 每个命令间隔100ms
        }
      } catch (err) {
        console.error('构建打印命令失败:', (err as BusinessError).message)
        resolve(false)
      }
    })
  }

  // 构建打印命令
  private buildPrintCommands(printJob: PrintJob): ArrayBuffer[] {
    const commands: ArrayBuffer[] = []
    
    // ESC/POS 打印命令
    const initPrinter = new Uint8Array([0x1B, 0x40]) // 初始化打印机
    commands.push(initPrinter.buffer as ArrayBuffer)
    
    // 设置对齐方式
    const alignCenter = new Uint8Array([0x1B, 0x61, 0x01]) // 居中对齐
    commands.push(alignCenter.buffer as ArrayBuffer)
    
    // 设置字体大小
    const fontSize = new Uint8Array([0x1B, 0x21, 0x10]) // 字体大小
    commands.push(fontSize.buffer as ArrayBuffer)
    
    // 打印标题
    const title = this.stringToUint8Array(printJob.documentName + '\n')
    commands.push(title.buffer as ArrayBuffer)
    
    // 重置字体
    const resetFont = new Uint8Array([0x1B, 0x21, 0x00])
    commands.push(resetFont.buffer as ArrayBuffer)
    
    // 打印文档信息
    const info = this.stringToUint8Array(`文档类型: ${printJob.documentId}\n`)
    commands.push(info.buffer as ArrayBuffer)
    
    // 打印份数信息
    const copiesInfo = this.stringToUint8Array(`打印份数: ${printJob.copies}\n`)
    commands.push(copiesInfo.buffer as ArrayBuffer)
    
    // 打印时间
    const time = this.stringToUint8Array(`打印时间: ${new Date().toLocaleString()}\n\n`)
    commands.push(time.buffer as ArrayBuffer)
    
    // 切纸
    const cutPaper = new Uint8Array([0x1D, 0x56, 0x00])
    commands.push(cutPaper.buffer as ArrayBuffer)
    
    return commands
  }

  // 断开连接
  public disconnect(): void {
    if (this.clientNumber !== -1) {
      try {
        // 取消数据监听
        socket.off('sppRead', this.clientNumber)
        
        // 关闭连接
        socket.sppCloseClientSocket(this.clientNumber)
        
        this.clientNumber = -1
        this.isConnected = false
        this.currentDevice = null
        
        if (this.connectionStateChangeCallback) {
          this.connectionStateChangeCallback(false)
        }
        
        console.info('打印机连接已断开')
      } catch (err) {
        console.error('断开连接失败:', (err as BusinessError).message)
      }
    }
  }

  // 获取连接状态
  public getConnectionState(): ConnectionState {
    return {
      connected: this.isConnected,
      device: this.currentDevice
    } as ConnectionState
  }

  // 获取发现的设备
  public getDiscoveredDevices(): BluetoothDevice[] {
    return [...this.discoveredDevices]
  }

  // 将字符串转换为 Uint8Array
  private stringToUint8Array(str: string): Uint8Array {
    const bytes = new Uint8Array(str.length)
    for (let i = 0; i < str.length; i++) {
      bytes[i] = str.charCodeAt(i)
    }
    return bytes
  }
}

export default BluetoothPrinterService.getInstance()
