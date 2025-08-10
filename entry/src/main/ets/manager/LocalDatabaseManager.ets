import { DocumentItem } from '../model/DocumentItem'
import { DocumentTypeInfo } from '../types/DocumentRecognition'
import { preferences } from '@kit.ArkData'

export class LocalDatabaseManager {
  private static readonly DOCUMENTS_KEY = 'documents'
  private static readonly DOCUMENT_TYPES_KEY = 'document_types'
  private static readonly PREFERENCES_NAME = 'document_manager'

  private static instance: LocalDatabaseManager
  private preferencesHelper: preferences.Preferences | null = null

  private constructor() {}

  static getInstance(): LocalDatabaseManager {
    if (!LocalDatabaseManager.instance) {
      LocalDatabaseManager.instance = new LocalDatabaseManager()
    }
    return LocalDatabaseManager.instance
  }

  // 初始化数据库
  async initialize(context: Context): Promise<void> {
    try {
      this.preferencesHelper = await preferences.getPreferences(context, LocalDatabaseManager.PREFERENCES_NAME)
      console.log('本地数据库初始化成功')
    } catch (error) {
      console.error('本地数据库初始化失败:', error)
    }
  }

  // 保存文档列表
  async saveDocuments(documents: DocumentItem[]): Promise<boolean> {
    try {
      if (!this.preferencesHelper) {
        console.error('数据库未初始化')
        return false
      }

      const documentsJSON = documents.map(doc => doc.toJSON())
      await this.preferencesHelper.put(LocalDatabaseManager.DOCUMENTS_KEY, JSON.stringify(documentsJSON))
      await this.preferencesHelper.flush()
      
      // 更新文档类型统计
      await this.updateDocumentTypes(documents)
      
      console.log('文档保存成功，共保存', documents.length, '个文档')
      return true
    } catch (error) {
      console.error('保存文档失败:', error)
      return false
    }
  }

  // 加载文档列表
  async loadDocuments(): Promise<DocumentItem[]> {
    try {
      if (!this.preferencesHelper) {
        console.error('数据库未初始化')
        return []
      }

      const documentsJSON = await this.preferencesHelper.get(LocalDatabaseManager.DOCUMENTS_KEY, '[]')
      const documentsArray = JSON.parse(documentsJSON as string)
      
      const documents = documentsArray.map((doc: {
        id?: string
        name?: string
        type?: string
        number?: string
        expiryDate?: string
        imageUrl?: Resource
        createTime?: string
        updateTime?: string
        dynamicFields?: Record<string, string>
        recognitionConfidence?: number
        originalImagePath?: string
      }) => DocumentItem.fromJSON(doc))
      console.log('文档加载成功，共加载', documents.length, '个文档')
      return documents
    } catch (error) {
      console.error('加载文档失败:', error)
      return []
    }
  }

  // 添加单个文档
  async addDocument(document: DocumentItem): Promise<boolean> {
    try {
      const documents = await this.loadDocuments()
      documents.push(document)
      return await this.saveDocuments(documents)
    } catch (error) {
      console.error('添加文档失败:', error)
      return false
    }
  }

  // 更新单个文档
  async updateDocument(document: DocumentItem): Promise<boolean> {
    try {
      const documents = await this.loadDocuments()
      const index = documents.findIndex(doc => doc.id === document.id)
      if (index !== -1) {
        documents[index] = document
        return await this.saveDocuments(documents)
      }
      return false
    } catch (error) {
      console.error('更新文档失败:', error)
      return false
    }
  }

  // 删除单个文档
  async deleteDocument(id: string): Promise<boolean> {
    try {
      const documents = await this.loadDocuments()
      const filteredDocuments = documents.filter(doc => doc.id !== id)
      return await this.saveDocuments(filteredDocuments)
    } catch (error) {
      console.error('删除文档失败:', error)
      return false
    }
  }

  // 根据ID获取文档
  async getDocumentById(id: string): Promise<DocumentItem | null> {
    try {
      const documents = await this.loadDocuments()
      return documents.find(doc => doc.id === id) || null
    } catch (error) {
      console.error('获取文档失败:', error)
      return null
    }
  }

  // 根据类型获取文档
  async getDocumentsByType(type: string): Promise<DocumentItem[]> {
    try {
      const documents = await this.loadDocuments()
      if (type === '全部') {
        return documents
      }
      return documents.filter(doc => doc.type === type)
    } catch (error) {
      console.error('根据类型获取文档失败:', error)
      return []
    }
  }

  // 搜索文档
  async searchDocuments(keyword: string): Promise<DocumentItem[]> {
    try {
      const documents = await this.loadDocuments()
      return documents.filter(doc => 
        doc.name.includes(keyword) || 
        doc.number.includes(keyword) ||
        doc.type.includes(keyword)
      )
    } catch (error) {
      console.error('搜索文档失败:', error)
      return []
    }
  }

  // 更新文档类型统计
  private async updateDocumentTypes(documents: DocumentItem[]): Promise<void> {
    try {
      const typeCount = new Map<string, number>()
      
      // 统计各类型文档数量
      documents.forEach(doc => {
        const count = typeCount.get(doc.type) || 0
        typeCount.set(doc.type, count + 1)
      })

      // 转换为DocumentTypeInfo数组
      const documentTypes: DocumentTypeInfo[] = Array.from(typeCount.entries()).map(([type, count]) => ({
        type,
        displayName: type,
        icon: this.getDocumentTypeIcon(type),
        count
      }))

      // 保存文档类型信息
      if (this.preferencesHelper) {
        await this.preferencesHelper.put(LocalDatabaseManager.DOCUMENT_TYPES_KEY, JSON.stringify(documentTypes))
        await this.preferencesHelper.flush()
      }
    } catch (error) {
      console.error('更新文档类型统计失败:', error)
    }
  }

  // 获取文档类型列表
  async getDocumentTypes(): Promise<DocumentTypeInfo[]> {
    try {
      if (!this.preferencesHelper) {
        return []
      }

      const typesJSON = await this.preferencesHelper.get(LocalDatabaseManager.DOCUMENT_TYPES_KEY, '[]')
      const types = JSON.parse(typesJSON as string)
      return types
    } catch (error) {
      console.error('获取文档类型失败:', error)
      return []
    }
  }

  // 获取文档类型图标
  private getDocumentTypeIcon(type: string): string {
    const iconMap: { [key: string]: string } = {
      '身份证': '🆔',
      '护照': '📘',
      '驾驶证': '🚗',
      '银行卡': '💳',
      '其他': '📄'
    }
    return iconMap[type] || '📄'
  }

  // 清空所有数据
  async clearAllData(): Promise<boolean> {
    try {
      if (!this.preferencesHelper) {
        return false
      }

      await this.preferencesHelper.clear()
      await this.preferencesHelper.flush()
      console.log('所有数据已清空')
      return true
    } catch (error) {
      console.error('清空数据失败:', error)
      return false
    }
  }
}
