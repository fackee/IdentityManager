import preferences from '@kit.PreferencesKit'

export class CommonUtils {
  private static readonly PREFERENCES_NAME = 'IdentityManager'
  private static readonly API_CONFIG_KEY = 'api_config'
  private static readonly USER_SETTINGS_KEY = 'user_settings'

  // 保存API配置
  static async saveAPIConfig(config: {
    baseUrl: string
    apiKey: string
    model: string
  }): Promise<boolean> {
    try {
      const preferencesHelper = await preferences.getPreferences(getContext(), this.PREFERENCES_NAME)
      await preferencesHelper.put(this.API_CONFIG_KEY, JSON.stringify(config))
      await preferencesHelper.flush()
      console.log('API配置保存成功')
      return true
    } catch (error) {
      console.error('保存API配置失败:', error)
      return false
    }
  }

  // 获取API配置
  static async getAPIConfig(): Promise<{
    baseUrl: string
    apiKey: string
    model: string
  } | null> {
    try {
      const preferencesHelper = await preferences.getPreferences(getContext(), this.PREFERENCES_NAME)
      const configString = await preferencesHelper.get(this.API_CONFIG_KEY, '')
      
      if (configString) {
        return JSON.parse(configString)
      }
      return null
    } catch (error) {
      console.error('获取API配置失败:', error)
      return null
    }
  }

  // 保存用户设置
  static async saveUserSettings(settings: {
    autoSave: boolean
    imageQuality: number
    enableBackup: boolean
  }): Promise<boolean> {
    try {
      const preferencesHelper = await preferences.getPreferences(getContext(), this.PREFERENCES_NAME)
      await preferencesHelper.put(this.USER_SETTINGS_KEY, JSON.stringify(settings))
      await preferencesHelper.flush()
      console.log('用户设置保存成功')
      return true
    } catch (error) {
      console.error('保存用户设置失败:', error)
      return false
    }
  }

  // 获取用户设置
  static async getUserSettings(): Promise<{
    autoSave: boolean
    imageQuality: number
    enableBackup: boolean
  }> {
    try {
      const preferencesHelper = await preferences.getPreferences(getContext(), this.PREFERENCES_NAME)
      const settingsString = await preferencesHelper.get(this.USER_SETTINGS_KEY, '')
      
      if (settingsString) {
        return JSON.parse(settingsString)
      }
      
      // 返回默认设置
      return {
        autoSave: true,
        imageQuality: 0.8,
        enableBackup: true
      }
    } catch (error) {
      console.error('获取用户设置失败:', error)
      return {
        autoSave: true,
        imageQuality: 0.8,
        enableBackup: true
      }
    }
  }

  // 清除所有配置
  static async clearAllConfig(): Promise<boolean> {
    try {
      const preferencesHelper = await preferences.getPreferences(getContext(), this.PREFERENCES_NAME)
      await preferencesHelper.clear()
      await preferencesHelper.flush()
      console.log('所有配置已清除')
      return true
    } catch (error) {
      console.error('清除配置失败:', error)
      return false
    }
  }

  // 格式化文件大小
  static formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B'
    
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  // 格式化日期
  static formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    const hours = String(date.getHours()).padStart(2, '0')
    const minutes = String(date.getMinutes()).padStart(2, '0')
    
    return `${year}-${month}-${day} ${hours}:${minutes}`
  }

  // 验证邮箱格式
  static isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return emailRegex.test(email)
  }

  // 验证手机号格式
  static isValidPhone(phone: string): boolean {
    const phoneRegex = /^1[3-9]\d{9}$/
    return phoneRegex.test(phone)
  }

  // 验证身份证号格式
  static isValidIDCard(idCard: string): boolean {
    const idCardRegex = /^[1-9]\d{5}(18|19|20)\d{2}((0[1-9])|(1[0-2]))(([0-2][1-9])|10|20|30|31)\d{3}[0-9Xx]$/
    return idCardRegex.test(idCard)
  }

  // 生成随机字符串
  static generateRandomString(length: number = 8): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    let result = ''
    for (let i = 0; i < length; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    return result
  }

  // 深拷贝对象
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

  // 防抖函数
  static debounce<T extends (...args: any[]) => any>(
    func: T,
    wait: number
  ): (...args: Parameters<T>) => void {
    let timeout: number | null = null
    
    return (...args: Parameters<T>) => {
      if (timeout) {
        clearTimeout(timeout)
      }
      timeout = setTimeout(() => func(...args), wait) as unknown as number
    }
  }

  // 节流函数
  static throttle<T extends (...args: any[]) => any>(
    func: T,
    limit: number
  ): (...args: Parameters<T>) => void {
    let inThrottle: boolean = false
    
    return (...args: Parameters<T>) => {
      if (!inThrottle) {
        func(...args)
        inThrottle = true
        setTimeout(() => inThrottle = false, limit)
      }
    }
  }
} 