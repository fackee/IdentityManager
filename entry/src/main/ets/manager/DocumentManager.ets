import { DocumentItem } from '../model/DocumentItem'
import { DocumentType } from '../model/DocumentType'

export class DocumentManager {
  private documents: DocumentItem[] = []

  constructor() {
    this.loadMockData()
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

  // 获取证件列表
  getDocuments(type: DocumentType = DocumentType.ALL, searchText: string = ''): DocumentItem[] {
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
  addDocument(document: DocumentItem): boolean {
    try {
      document.id = this.generateId()
      document.createTime = new Date()
      document.updateTime = new Date()
      this.documents.push(document)
      return true
    } catch (error) {
      console.error('添加证件失败:', error)
      return false
    }
  }

  // 更新证件
  updateDocument(document: DocumentItem): boolean {
    try {
      const index = this.documents.findIndex(doc => doc.id === document.id)
      if (index !== -1) {
        document.updateTime = new Date()
        this.documents[index] = document
        return true
      }
      return false
    } catch (error) {
      console.error('更新证件失败:', error)
      return false
    }
  }

  // 删除证件
  deleteDocument(id: string): boolean {
    try {
      const index = this.documents.findIndex(doc => doc.id === id)
      if (index !== -1) {
        this.documents.splice(index, 1)
        return true
      }
      return false
    } catch (error) {
      console.error('删除证件失败:', error)
      return false
    }
  }

  // 根据ID获取证件
  getDocumentById(id: string): DocumentItem | null {
    return this.documents.find(doc => doc.id === id) || null
  }

  // 生成唯一ID
  private generateId(): string {
    return Date.now().toString() + Math.random().toString(36).substr(2, 9)
  }

  // 获取证件统计信息
  getStatistics() {
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
  checkExpiry(): DocumentItem[] {
    const today = new Date()
    return this.documents.filter(doc => {
      const expiryDate = new Date(doc.expiryDate)
      return expiryDate < today
    })
  }
} 