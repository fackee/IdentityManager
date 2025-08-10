export class CommonUtils {
  /**
   * 格式化日期
   * @param date 日期对象
   * @param format 格式化字符串
   * @returns 格式化后的日期字符串
   */
  static formatDate(date: Date, format: string = 'YYYY-MM-DD'): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    
    return format
      .replace('YYYY', year.toString())
      .replace('MM', month)
      .replace('DD', day)
  }

  /**
   * 检查字符串是否为空
   * @param str 待检查的字符串
   * @returns 是否为空
   */
  static isEmpty(str: string): boolean {
    return !str || str.trim().length === 0
  }

  /**
   * 生成随机ID
   * @returns 随机ID字符串
   */
  static generateId(): string {
    return Date.now().toString() + Math.random().toString(36).substr(2, 9)
  }

  /**
   * 脱敏处理
   * @param text 原始文本
   * @param start 开始位置
   * @param end 结束位置
   * @returns 脱敏后的文本
   */
  static maskText(text: string, start: number = 4, end: number = -4): string {
    if (!text || text.length < start + Math.abs(end)) {
      return text
    }
    
    const prefix = text.substring(0, start)
    const suffix = end < 0 ? text.substring(text.length + end) : text.substring(end)
    const mask = '*'.repeat(text.length - start - (end < 0 ? Math.abs(end) : end))
    
    return prefix + mask + suffix
  }

  /**
   * 验证身份证号码
   * @param idNumber 身份证号码
   * @returns 是否有效
   */
  static validateIdNumber(idNumber: string): boolean {
    if (!idNumber || idNumber.length !== 18) {
      return false
    }
    
    // 简单的身份证号码验证
    const pattern = /^[1-9]\d{5}(18|19|20)\d{2}((0[1-9])|(1[0-2]))(([0-2][1-9])|10|20|30|31)\d{3}[0-9Xx]$/
    return pattern.test(idNumber)
  }

  /**
   * 验证护照号码
   * @param passportNumber 护照号码
   * @returns 是否有效
   */
  static validatePassportNumber(passportNumber: string): boolean {
    if (!passportNumber) {
      return false
    }
    
    // 简单的护照号码验证
    const pattern = /^[A-Z]\d{8}$/
    return pattern.test(passportNumber)
  }

  /**
   * 获取文件大小描述
   * @param bytes 字节数
   * @returns 文件大小描述
   */
  static formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B'
    
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  /**
   * 防抖函数
   * @param func 要执行的函数
   * @param delay 延迟时间
   * @returns 防抖后的函数
   */
  static debounce(func: Function, delay: number): Function {
    let timeoutId: number | null = null
    
    return function (...args: unknown[]) {
      if (timeoutId) {
        clearTimeout(timeoutId)
      }
      
      timeoutId = setTimeout(() => {
        func(...args)
      }, delay)
    }
  }

  /**
   * 节流函数
   * @param func 要执行的函数
   * @param delay 延迟时间
   * @returns 节流后的函数
   */
  static throttle(func: Function, delay: number): Function {
    let lastCall = 0
    
    return function (...args: unknown[]) {
      const now = Date.now()
      
      if (now - lastCall >= delay) {
        lastCall = now
        func(...args)
      }
    }
  }

  /**
   * 深拷贝对象
   * @param obj 要拷贝的对象
   * @returns 拷贝后的对象
   */
  static deepClone<T>(obj: T): T {
    if (obj === null || typeof obj !== 'object') {
      return obj
    }
    
    if (obj instanceof Date) {
      return new Date(obj.getTime()) as unknown as T
    }
    
    if (obj instanceof Array) {
      return obj.map(item => this.deepClone(item)) as unknown as T
    }
    
    if (typeof obj === 'object') {
      const clonedObj = {} as T
      for (const key in obj) {
        if (obj.hasOwnProperty(key)) {
          clonedObj[key] = this.deepClone(obj[key])
        }
      }
      return clonedObj
    }
    
    return obj
  }
} 