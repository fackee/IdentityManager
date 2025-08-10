import { DocumentItem } from '../model/DocumentItem'
import { DocumentType } from '../model/DocumentType'
import { LocalDatabaseManager } from './LocalDatabaseManager'

export class DocumentManager {
  private documents: DocumentItem[] = []
  private databaseManager: LocalDatabaseManager = LocalDatabaseManager.getInstance()
  private isInitialized: boolean = false

  constructor() {
    this.initialize()
  }

  private async initialize() {
    try {
      await this.databaseManager.initialize(getContext())
      this.isInitialized = true
      await this.loadDocuments()
    } catch (error) {
      console.error('DocumentManager初始化失败:', error)
      // 如果数据库初始化失败，使用内存数据
      this.loadMockData()
    }
  }

  private loadMockData() {
    this.documents = [
      new DocumentItem(
        '1',
        '张三的身份证',
        '身份证',
        '1101********1234',
        '2025-12-31',
        $r('app.media.background'),
        new Date(),
        new Date()
      ),
      new DocumentItem(
        '2',
        '李四的护照',
        '护照',
        'E12345678',
        '2026-06-30',
        $r('app.media.background'),
        new Date(),
        new Date()
      ),
      new DocumentItem(
        '3',
        '王五的驾驶证',
        '驾驶证',
        '110101199001011234',
        '2027-03-15',
        $r('app.media.background'),
        new Date(),
        new Date()
      )
    ]
  }

  private async loadDocuments() {
    if (this.isInitialized) {
      try {
        this.documents = await this.databaseManager.loadDocuments()
      } catch (error) {
        console.error('加载文档失败:', error)
        this.loadMockData()
      }
    }
  }

  // 获取证件列表
  async getDocuments(type: DocumentType = DocumentType.ALL, searchText: string = ''): Promise<DocumentItem[]> {
    await this.loadDocuments()
    let filtered = this.documents

    // 按类型过滤
    if (type !== DocumentType.ALL) {
      filtered = filtered.filter(doc => doc.type === type)
    }

    // 按搜索文本过滤
    if (searchText) {
      filtered = filtered.filter(doc => 
        doc.name.includes(searchText) || 
        doc.number.includes(searchText)
      )
    }

    return filtered
  }

  // 添加证件
  async addDocument(document: DocumentItem): Promise<boolean> {
    try {
      if (this.isInitialized) {
        return await this.databaseManager.addDocument(document)
      } else {
        // 如果数据库未初始化，使用内存存储
        document.id = this.generateId()
        document.createTime = new Date()
        document.updateTime = new Date()
        this.documents.push(document)
        return true
      }
    } catch (error) {
      console.error('添加证件失败:', error)
      return false
    }
  }

  // 更新证件
  async updateDocument(document: DocumentItem): Promise<boolean> {
    try {
      if (this.isInitialized) {
        return await this.databaseManager.updateDocument(document)
      } else {
        // 如果数据库未初始化，使用内存存储
        const index = this.documents.findIndex(doc => doc.id === document.id)
        if (index !== -1) {
          document.updateTime = new Date()
          this.documents[index] = document
          return true
        }
        return false
      }
    } catch (error) {
      console.error('更新证件失败:', error)
      return false
    }
  }

  // 删除证件
  async deleteDocument(id: string): Promise<boolean> {
    try {
      if (this.isInitialized) {
        return await this.databaseManager.deleteDocument(id)
      } else {
        // 如果数据库未初始化，使用内存存储
        const index = this.documents.findIndex(doc => doc.id === id)
        if (index !== -1) {
          this.documents.splice(index, 1)
          return true
        }
        return false
      }
    } catch (error) {
      console.error('删除证件失败:', error)
      return false
    }
  }

  // 根据ID获取证件
  async getDocumentById(id: string): Promise<DocumentItem | null> {
    try {
      if (this.isInitialized) {
        return await this.databaseManager.getDocumentById(id)
      } else {
        return this.documents.find(doc => doc.id === id) || null
      }
    } catch (error) {
      console.error('获取证件失败:', error)
      return null
    }
  }

  // 根据类型获取证件
  async getDocumentsByType(type: string): Promise<DocumentItem[]> {
    try {
      if (this.isInitialized) {
        return await this.databaseManager.getDocumentsByType(type)
      } else {
        if (type === '全部') {
          return this.documents
        }
        return this.documents.filter(doc => doc.type === type)
      }
    } catch (error) {
      console.error('根据类型获取证件失败:', error)
      return []
    }
  }

  // 搜索证件
  async searchDocuments(keyword: string): Promise<DocumentItem[]> {
    try {
      if (this.isInitialized) {
        return await this.databaseManager.searchDocuments(keyword)
      } else {
        return this.documents.filter(doc => 
          doc.name.includes(keyword) || 
          doc.number.includes(keyword) ||
          doc.type.includes(keyword)
        )
      }
    } catch (error) {
      console.error('搜索证件失败:', error)
      return []
    }
  }

  // 生成唯一ID
  private generateId(): string {
    return Date.now().toString() + Math.random().toString(36).substr(2, 9)
  }

  // 获取证件统计信息
  async getStatistics() {
    await this.loadDocuments()
    const total = this.documents.length
    const byType = {
      '身份证': this.documents.filter(doc => doc.type === '身份证').length,
      '护照': this.documents.filter(doc => doc.type === '护照').length,
      '驾驶证': this.documents.filter(doc => doc.type === '驾驶证').length,
      '其他': this.documents.filter(doc => !['身份证', '护照', '驾驶证'].includes(doc.type)).length
    }

    return {
      total,
      byType
    }
  }

  // 检查证件是否过期
  async checkExpiry(): Promise<DocumentItem[]> {
    await this.loadDocuments()
    const today = new Date()
    return this.documents.filter(doc => {
      const expiryDate = new Date(doc.expiryDate)
      return expiryDate < today
    })
  }

  // 获取数据库管理器实例
  getDatabaseManager(): LocalDatabaseManager {
    return this.databaseManager
  }

  // 重新初始化
  async reinitialize() {
    this.isInitialized = false
    await this.initialize()
  }
} 