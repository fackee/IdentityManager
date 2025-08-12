import { preferences } from '@kit.ArkData'

export class UserSetting {
  autoSave: boolean;
  imageQuality: number;
  enableBackup: boolean;

  constructor(autoSave: boolean, imageQuality: number,  enableBackup: boolean) {
    this.autoSave = autoSave;
    this.imageQuality = imageQuality;
    this.enableBackup = enableBackup;
  }
}

export class CommonUtils {
  private static readonly PREFERENCES_NAME = 'IdentityManager'
  private static readonly USER_SETTINGS_KEY = 'user_settings'


  // 保存用户设置
  static async saveUserSettings(settings: UserSetting): Promise<boolean> {
    try {
      const preferencesHelper = await preferences.getPreferences(getContext(), CommonUtils.PREFERENCES_NAME)
      await preferencesHelper.put(CommonUtils.USER_SETTINGS_KEY, JSON.stringify(settings))
      await preferencesHelper.flush()
      console.log('用户设置保存成功')
      return true
    } catch (error) {
      console.error('保存用户设置失败:', error)
      return false
    }
  }

  // 获取用户设置
  static async getUserSettings(): Promise<UserSetting> {
    try {
      const preferencesHelper = await preferences.getPreferences(getContext(), CommonUtils.PREFERENCES_NAME)
      const settingsString = await preferencesHelper.get(CommonUtils.USER_SETTINGS_KEY, '')
      
      if (settingsString && typeof settingsString === 'string') {
        const settingsObj = JSON.parse(settingsString) as UserSetting
        return new UserSetting(settingsObj.autoSave, settingsObj.imageQuality, settingsObj.enableBackup)
      }
      
      // 返回默认设置
      return new UserSetting(true, 0.8, true)
    } catch (error) {
      console.error('获取用户设置失败:', error)
      return new UserSetting(true, 0.8, true)
    }
  }

  // 清除所有配置
  static async clearAllConfig(): Promise<boolean> {
    try {
      const preferencesHelper = await preferences.getPreferences(getContext(), CommonUtils.PREFERENCES_NAME)
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
} 