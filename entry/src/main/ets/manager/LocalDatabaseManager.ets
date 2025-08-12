// import { relationalStore } from '@kit.ArkData'
// import { BusinessError } from '@kit.BasicServicesKit'
// import { DocumentItem } from '../model/DocumentItem'
// import { DocumentTypeInfo } from '../types/DocumentRecognition'
//
// // 定义 JSON 接口
// interface DocumentItemJSON {
//   id?: string
//   name?: string
//   type?: string
//   number?: string
//   expiryDate?: string
//   imageUrl?: string
//   createTime?: string
//   updateTime?: string
//   dynamicFields?: Record<string, string>
//   recognitionConfidence?: number
//   originalImagePath?: string
// }
//
// export class DocumentDatabaseManager {
//   private static instance: DocumentDatabaseManager
//   private rdbStore: relationalStore.RdbStore | null = null
//   private context: Context | null = null
//
//   // 数据库配置
//   private static readonly STORE_CONFIG: relationalStore.StoreConfig = {
//     name: 'DocumentManager.db',
//     securityLevel: relationalStore.SecurityLevel.S3,
//     encrypt: false,
//     isReadOnly: false
//   }
//
//   // 数据库版本
//   private static readonly CURRENT_VERSION = 1
//
//   // 建表SQL
//   private static readonly SQL_CREATE_DOCUMENTS_TABLE = `
//     CREATE TABLE IF NOT EXISTS documents (
//       id TEXT PRIMARY KEY,
//       name TEXT NOT NULL,
//       type TEXT NOT NULL,
//       number TEXT,
//       expiryDate TEXT,
//       imageUrl TEXT,
//       createTime TEXT NOT NULL,
//       updateTime TEXT NOT NULL,
//       dynamicFields TEXT,
//       recognitionConfidence REAL DEFAULT 0,
//       originalImagePath TEXT
//     )
//   `
//
//   private static readonly SQL_CREATE_DOCUMENT_TYPES_TABLE = `
//     CREATE TABLE IF NOT EXISTS document_types (
//       type TEXT PRIMARY KEY,
//       displayName TEXT NOT NULL,
//       icon TEXT,
//       count INTEGER DEFAULT 0
//     )
//   `
//
//   private constructor() {}
//
//   static getInstance(): DocumentDatabaseManager {
//     if (!DocumentDatabaseManager.instance) {
//       DocumentDatabaseManager.instance = new DocumentDatabaseManager()
//     }
//     return DocumentDatabaseManager.instance
//   }
//
//   // 初始化数据库
//   async initialize(context: Context): Promise<boolean> {
//     try {
//       this.context = context
//
//       return new Promise((resolve) => {
//         relationalStore.getRdbStore(context, DocumentDatabaseManager.STORE_CONFIG, async (err, store) => {
//           if (err) {
//             console.error(`获取RdbStore失败. 错误码:${err.code}, 消息:${err.message}`)
//             resolve(false)
//             return
//           }
//
//           this.rdbStore = store
//           console.log('成功获取RdbStore')
//
//           // 检查数据库版本并进行升级
//           const success = await this.handleDatabaseVersion()
//           resolve(success)
//         })
//       })
//     } catch (error) {
//       console.error('初始化数据库失败:', error)
//       return false
//     }
//   }
//
//   // 处理数据库版本升级
//   private async handleDatabaseVersion(): Promise<boolean> {
//     if (!this.rdbStore) return false
//
//     try {
//       let storeVersion = this.rdbStore.version
//
//       // 当数据库创建时，版本为0，需要创建表
//       if (storeVersion === 0) {
//         await this.rdbStore.execute(DocumentDatabaseManager.SQL_CREATE_DOCUMENTS_TABLE)
//         await this.rdbStore.execute(DocumentDatabaseManager.SQL_CREATE_DOCUMENT_TYPES_TABLE)
//         storeVersion = DocumentDatabaseManager.CURRENT_VERSION
//         console.log('数据库表创建成功')
//       }
//
//       // 设置数据库版本
//       this.rdbStore.version = storeVersion
//       console.log('数据库初始化完成，版本:', storeVersion)
//       return true
//     } catch (error) {
//       const err = error as BusinessError
//       console.error(`数据库版本处理失败. 错误码:${err.code}, 消息:${err.message}`)
//       return false
//     }
//   }
//
//   // 保存文档列表
//   async saveDocuments(documents: DocumentItem[]): Promise<boolean> {
//     if (!this.rdbStore) {
//       console.error('数据库未初始化')
//       return false
//     }
//
//     try {
//       // 开始事务
//       await this.rdbStore.beginTransaction()
//
//       // 清空现有数据
//       await this.rdbStore.execute('DELETE FROM documents')
//
//       // 插入新数据
//       for (const doc of documents) {
//         const valuesBucket: relationalStore.ValuesBucket = {
//           id: doc.id,
//           name: doc.name,
//           type: doc.type,
//           number: doc.number,
//           expiryDate: doc.expiryDate,
//           imageUrl: doc.imageUrl,
//           createTime: doc.createTime.toISOString(),
//           updateTime: doc.updateTime.toISOString(),
//           dynamicFields: JSON.stringify(Object.fromEntries(doc.dynamicFields)),
//           recognitionConfidence: doc.recognitionConfidence,
//           originalImagePath: doc.originalImagePath
//         }
//
//         await this.rdbStore.insert('documents', valuesBucket)
//       }
//
//       // 提交事务
//       await this.rdbStore.commit()
//
//       // 更新文档类型统计
//       await this.updateDocumentTypes(documents)
//
//       console.log('文档保存成功，共保存', documents.length, '个文档')
//       return true
//     } catch (error) {
//       // 回滚事务
//       if (this.rdbStore) {
//         await this.rdbStore.rollBack()
//       }
//       console.error('保存文档失败:', error)
//       return false
//     }
//   }
//
//   // 加载文档列表
//   async loadDocuments(): Promise<DocumentItem[]> {
//     if (!this.rdbStore) {
//       console.error('数据库未初始化')
//       return []
//     }
//
//     try {
//       const predicates = new relationalStore.RdbPredicates('documents')
//       const resultSet = await this.rdbStore.query(predicates)
//
//       const documents: DocumentItem[] = []
//       while (resultSet.goToNextRow()) {
//         const dynamicFieldsStr = resultSet.getString(resultSet.getColumnIndex('dynamicFields'))
//         const dynamicFields = new Map<string, string>()
//
//         if (dynamicFieldsStr) {
//           const dynamicFieldsObj = JSON.parse(dynamicFieldsStr)
//           Object.keys(dynamicFieldsObj).forEach(key => {
//             dynamicFields.set(key, dynamicFieldsObj[key])
//           })
//         }
//
//         const document = new DocumentItem(
//           resultSet.getString(resultSet.getColumnIndex('id')),
//           resultSet.getString(resultSet.getColumnIndex('name')),
//           resultSet.getString(resultSet.getColumnIndex('type')),
//           resultSet.getString(resultSet.getColumnIndex('number')),
//           resultSet.getString(resultSet.getColumnIndex('expiryDate')),
//           resultSet.getString(resultSet.getColumnIndex('imageUrl')),
//           new Date(resultSet.getString(resultSet.getColumnIndex('createTime'))),
//           new Date(resultSet.getString(resultSet.getColumnIndex('updateTime'))),
//           dynamicFields,
//           resultSet.getDouble(resultSet.getColumnIndex('recognitionConfidence')),
//           resultSet.getString(resultSet.getColumnIndex('originalImagePath'))
//         )
//         documents.push(document)
//       }
//
//       resultSet.close()
//       console.log('文档加载成功，共加载', documents.length, '个文档')
//       return documents
//     } catch (error) {
//       console.error('加载文档失败:', error)
//       return []
//     }
//   }
//
//   // 添加单个文档
//   async addDocument(document: DocumentItem): Promise<boolean> {
//     if (!this.rdbStore) {
//       console.error('数据库未初始化')
//       return false
//     }
//
//     try {
//       const valuesBucket: relationalStore.ValuesBucket = {
//         id: document.id,
//         name: document.name,
//         type: document.type,
//         number: document.number,
//         expiryDate: document.expiryDate,
//         imageUrl: document.imageUrl,
//         createTime: document.createTime.toISOString(),
//         updateTime: document.updateTime.toISOString(),
//         dynamicFields: JSON.stringify(Object.fromEntries(document.dynamicFields)),
//         recognitionConfidence: document.recognitionConfidence,
//         originalImagePath: document.originalImagePath
//       }
//
//       await this.rdbStore.insert('documents', valuesBucket)
//
//       // 更新文档类型统计
//       const documents = await this.loadDocuments()
//       await this.updateDocumentTypes(documents)
//
//       console.log('文档添加成功:', document.name)
//       return true
//     } catch (error) {
//       console.error('添加文档失败:', error)
//       return false
//     }
//   }
//
//   // 更新单个文档
//   async updateDocument(document: DocumentItem): Promise<boolean> {
//     if (!this.rdbStore) {
//       console.error('数据库未初始化')
//       return false
//     }
//
//     try {
//       const predicates = new relationalStore.RdbPredicates('documents')
//       predicates.equalTo('id', document.id)
//
//       const valuesBucket: relationalStore.ValuesBucket = {
//         name: document.name,
//         type: document.type,
//         number: document.number,
//         expiryDate: document.expiryDate,
//         imageUrl: document.imageUrl,
//         updateTime: document.updateTime.toISOString(),
//         dynamicFields: JSON.stringify(Object.fromEntries(document.dynamicFields)),
//         recognitionConfidence: document.recognitionConfidence,
//         originalImagePath: document.originalImagePath
//       }
//
//       const rows = await this.rdbStore.update(valuesBucket, predicates)
//
//       if (rows > 0) {
//         // 更新文档类型统计
//         const documents = await this.loadDocuments()
//         await this.updateDocumentTypes(documents)
//
//         console.log('文档更新成功:', document.name)
//         return true
//       }
//       return false
//     } catch (error) {
//       console.error('更新文档失败:', error)
//       return false
//     }
//   }
//
//   // 删除单个文档
//   async deleteDocument(id: string): Promise<boolean> {
//     if (!this.rdbStore) {
//       console.error('数据库未初始化')
//       return false
//     }
//
//     try {
//       const predicates = new relationalStore.RdbPredicates('documents')
//       predicates.equalTo('id', id)
//
//       const rows = await this.rdbStore.delete(predicates)
//
//       if (rows > 0) {
//         // 更新文档类型统计
//         const documents = await this.loadDocuments()
//         await this.updateDocumentTypes(documents)
//
//         console.log('文档删除成功，ID:', id)
//         return true
//       }
//       return false
//     } catch (error) {
//       console.error('删除文档失败:', error)
//       return false
//     }
//   }
//
//   // 根据ID获取文档
//   async getDocumentById(id: string): Promise<DocumentItem | null> {
//     if (!this.rdbStore) {
//       console.error('数据库未初始化')
//       return null
//     }
//
//     try {
//       const predicates = new relationalStore.RdbPredicates('documents')
//       predicates.equalTo('id', id)
//
//       const resultSet = await this.rdbStore.query(predicates)
//
//       if (resultSet.goToFirstRow()) {
//         const dynamicFieldsStr = resultSet.getString(resultSet.getColumnIndex('dynamicFields'))
//         const dynamicFields = new Map<string, string>()
//
//         if (dynamicFieldsStr) {
//           const dynamicFieldsObj = JSON.parse(dynamicFieldsStr)
//           Object.keys(dynamicFieldsObj).forEach(key => {
//             dynamicFields.set(key, dynamicFieldsObj[key])
//           })
//         }
//
//         const document = new DocumentItem(
//           resultSet.getString(resultSet.getColumnIndex('id')),
//           resultSet.getString(resultSet.getColumnIndex('name')),
//           resultSet.getString(resultSet.getColumnIndex('type')),
//           resultSet.getString(resultSet.getColumnIndex('number')),
//           resultSet.getString(resultSet.getColumnIndex('expiryDate')),
//           resultSet.getString(resultSet.getColumnIndex('imageUrl')),
//           new Date(resultSet.getString(resultSet.getColumnIndex('createTime'))),
//           new Date(resultSet.getString(resultSet.getColumnIndex('updateTime'))),
//           dynamicFields,
//           resultSet.getDouble(resultSet.getColumnIndex('recognitionConfidence')),
//           resultSet.getString(resultSet.getColumnIndex('originalImagePath'))
//         )
//
//         resultSet.close()
//         return document
//       }
//
//       resultSet.close()
//       return null
//     } catch (error) {
//       console.error('获取文档失败:', error)
//       return null
//     }
//   }
//
//   // 根据类型获取文档
//   async getDocumentsByType(type: string): Promise<DocumentItem[]> {
//     if (!this.rdbStore) {
//       console.error('数据库未初始化')
//       return []
//     }
//
//     try {
//       const predicates = new relationalStore.RdbPredicates('documents')
//       if (type !== '全部') {
//         predicates.equalTo('type', type)
//       }
//
//       const resultSet = await this.rdbStore.query(predicates)
//
//       const documents: DocumentItem[] = []
//       while (resultSet.goToNextRow()) {
//         const dynamicFieldsStr = resultSet.getString(resultSet.getColumnIndex('dynamicFields'))
//         const dynamicFields = new Map<string, string>()
//
//         if (dynamicFieldsStr) {
//           const dynamicFieldsObj = JSON.parse(dynamicFieldsStr)
//           Object.keys(dynamicFieldsObj).forEach(key => {
//             dynamicFields.set(key, dynamicFieldsObj[key])
//           })
//         }
//
//         const document = new DocumentItem(
//           resultSet.getString(resultSet.getColumnIndex('id')),
//           resultSet.getString(resultSet.getColumnIndex('name')),
//           resultSet.getString(resultSet.getColumnIndex('type')),
//           resultSet.getString(resultSet.getColumnIndex('number')),
//           resultSet.getString(resultSet.getColumnIndex('expiryDate')),
//           resultSet.getString(resultSet.getColumnIndex('imageUrl')),
//           new Date(resultSet.getString(resultSet.getColumnIndex('createTime'))),
//           new Date(resultSet.getString(resultSet.getColumnIndex('updateTime'))),
//           dynamicFields,
//           resultSet.getDouble(resultSet.getColumnIndex('recognitionConfidence')),
//           resultSet.getString(resultSet.getColumnIndex('originalImagePath'))
//         )
//         documents.push(document)
//       }
//
//       resultSet.close()
//       return documents
//     } catch (error) {
//       console.error('根据类型获取文档失败:', error)
//       return []
//     }
//   }
//
//   // 搜索文档
//   async searchDocuments(keyword: string): Promise<DocumentItem[]> {
//     if (!this.rdbStore) {
//       console.error('数据库未初始化')
//       return []
//     }
//
//     try {
//       const predicates = new relationalStore.RdbPredicates('documents')
//       predicates.like('name', `%${keyword}%`)
//         .or()
//         .like('number', `%${keyword}%`)
//         .or()
//         .like('type', `%${keyword}%`)
//
//       const resultSet = await this.rdbStore.query(predicates)
//
//       const documents: DocumentItem[] = []
//       while (resultSet.goToNextRow()) {
//         const dynamicFieldsStr = resultSet.getString(resultSet.getColumnIndex('dynamicFields'))
//         const dynamicFields = new Map<string, string>()
//
//         if (dynamicFieldsStr) {
//           const dynamicFieldsObj = JSON.parse(dynamicFieldsStr)
//           Object.keys(dynamicFieldsObj).forEach(key => {
//             dynamicFields.set(key, dynamicFieldsObj[key])
//           })
//         }
//
//         const document = new DocumentItem(
//           resultSet.getString(resultSet.getColumnIndex('id')),
//           resultSet.getString(resultSet.getColumnIndex('name')),
//           resultSet.getString(resultSet.getColumnIndex('type')),
//           resultSet.getString(resultSet.getColumnIndex('number')),
//           resultSet.getString(resultSet.getColumnIndex('expiryDate')),
//           resultSet.getString(resultSet.getColumnIndex('imageUrl')),
//           new Date(resultSet.getString(resultSet.getColumnIndex('createTime'))),
//           new Date(resultSet.getString(resultSet.getColumnIndex('updateTime'))),
//           dynamicFields,
//           resultSet.getDouble(resultSet.getColumnIndex('recognitionConfidence')),
//           resultSet.getString(resultSet.getColumnIndex('originalImagePath'))
//         )
//         documents.push(document)
//       }
//
//       resultSet.close()
//       return documents
//     } catch (error) {
//       console.error('搜索文档失败:', error)
//       return []
//     }
//   }
//
//   // 更新文档类型统计
//   private async updateDocumentTypes(documents: DocumentItem[]): Promise<void> {
//     if (!this.rdbStore) return
//
//     try {
//       // 开始事务
//       await this.rdbStore.beginTransaction()
//
//       // 清空现有类型数据
//       await this.rdbStore.execute('DELETE FROM document_types')
//
//       // 统计各类型文档数量
//       const typeCount = new Map<string, number>()
//       documents.forEach(doc => {
//         const count = typeCount.get(doc.type) || 0
//         typeCount.set(doc.type, count + 1)
//       })
//
//       // 插入类型数据
//       typeCount.forEach((count, type) => {
//         const valuesBucket: relationalStore.ValuesBucket = {
//           type: type,
//           displayName: type,
//           icon: this.getDocumentTypeIcon(type),
//           count: count
//         }
//         this.rdbStore!.insert('document_types', valuesBucket)
//       })
//
//       // 提交事务
//       await this.rdbStore.commit()
//     } catch (error) {
//       // 回滚事务
//       if (this.rdbStore) {
//         await this.rdbStore.rollBack()
//       }
//       console.error('更新文档类型统计失败:', error)
//     }
//   }
//
//   // 获取文档类型列表
//   async getDocumentTypes(): Promise<DocumentTypeInfo[]> {
//     if (!this.rdbStore) {
//       return []
//     }
//
//     try {
//       const predicates = new relationalStore.RdbPredicates('document_types')
//       const resultSet = await this.rdbStore.query(predicates)
//
//       const documentTypes: DocumentTypeInfo[] = []
//       while (resultSet.goToNextRow()) {
//         documentTypes.push({
//           type: resultSet.getString(resultSet.getColumnIndex('type')),
//           displayName: resultSet.getString(resultSet.getColumnIndex('displayName')),
//           icon: resultSet.getString(resultSet.getColumnIndex('icon')),
//           count: resultSet.getLong(resultSet.getColumnIndex('count'))
//         })
//       }
//
//       resultSet.close()
//       return documentTypes
//     } catch (error) {
//       console.error('获取文档类型失败:', error)
//       return []
//     }
//   }
//
//   // 获取文档类型图标
//   private getDocumentTypeIcon(type: string): string {
//     const iconMap: Record<string, string> = {
//       '身份证': '🆔',
//       '护照': '📘',
//       '驾驶证': '🚗',
//       '银行卡': '💳',
//       '其他': '📄'
//     }
//     const icon = iconMap[type]
//     return icon || '📄'
//   }
//
//   // 清空所有数据
//   async clearAllData(): Promise<boolean> {
//     if (!this.rdbStore) {
//       return false
//     }
//
//     try {
//       await this.rdbStore.execute('DELETE FROM documents')
//       await this.rdbStore.execute('DELETE FROM document_types')
//       console.log('所有数据已清空')
//       return true
//     } catch (error) {
//       console.error('清空数据失败:', error)
//       return false
//     }
//   }
//
//   // 关闭数据库连接
//   async close(): Promise<void> {
//     if (this.rdbStore) {
//       await this.rdbStore.close()
//       this.rdbStore = null
//       console.log('数据库连接已关闭')
//     }
//   }
// }