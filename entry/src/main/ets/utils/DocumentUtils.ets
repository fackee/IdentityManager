import { DocumentItem } from '../model/DocumentItem'

export class DocumentUtils {
  // 检查证件是否即将过期（30天内）
  static isExpiringSoon(expiryDate: string): boolean {
    const expiry = new Date(expiryDate)
    const today = new Date()
    const diffTime = expiry.getTime() - today.getTime()
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
    return diffDays <= 30 && diffDays > 0
  }

  // 检查证件是否已过期
  static isExpired(expiryDate: string): boolean {
    const expiry = new Date(expiryDate)
    const today = new Date()
    return expiry < today
  }

  // 格式化证件号码（隐藏中间部分）
  static formatDocumentNumber(number: string): string {
    if (number.length <= 8) {
      return number
    }
    const start = number.substring(0, 4)
    const end = number.substring(number.length - 4)
    return `${start}****${end}`
  }

  // 获取证件类型图标
  static getDocumentTypeIcon(type: string): string {
    switch (type) {
      case '身份证':
        return '🆔'
      case '护照':
        return '📘'
      case '驾驶证':
        return '🚗'
      default:
        return '📄'
    }
  }

  // 获取证件状态颜色
  static getDocumentStatusColor(expiryDate: string): string {
    if (DocumentUtils.isExpired(expiryDate)) {
      return '#F44336' // 红色 - 已过期
    } else if (DocumentUtils.isExpiringSoon(expiryDate)) {
      return '#FF9800' // 橙色 - 即将过期
    } else {
      return '#4CAF50' // 绿色 - 正常
    }
  }

  // 获取证件状态文本
  static getDocumentStatusText(expiryDate: string): string {
    if (DocumentUtils.isExpired(expiryDate)) {
      return '已过期'
    } else if (DocumentUtils.isExpiringSoon(expiryDate)) {
      return '即将过期'
    } else {
      return '正常'
    }
  }

  // 验证证件号码格式
  static validateDocumentNumber(type: string, number: string): boolean {
    switch (type) {
      case '身份证':
        // 身份证号码验证（简化版）
        return /^\d{17}[\dXx]$/.test(number)
      case '护照':
        // 护照号码验证（简化版）
        return /^[A-Z]\d{8}$/.test(number)
      case '驾驶证':
        // 驾驶证号码验证（简化版）
        return /^\d{18}$/.test(number)
      default:
        return number.length > 0
    }
  }

  // 生成证件二维码数据
  static generateQRCodeData(document: DocumentItem): string {
    return JSON.stringify({
      id: document.id,
      name: document.name,
      type: document.type,
      number: document.number,
      expiryDate: document.expiryDate
    })
  }
}
