
export class DocumentItem {
  id: string
  name: string
  type: string
  number: string
  expiryDate: string
  imageUrl: string
  createTime: Date
  updateTime: Date
  // 新增字段：动态表单数据
  dynamicFields: Record<string, string> = {}
  // 新增字段：识别置信度
  recognitionConfidence: number = 0
  // 新增字段：原始图片路径
  originalImagePath: string = ''

  constructor(
    id: string = '',
    name: string = '',
    type: string = '',
    number: string = '',
    expiryDate: string = '',
    imageUrl: string = '',
    createTime: Date = new Date(),
    updateTime: Date = new Date(),
    dynamicFields: Record<string, string> = {},
    recognitionConfidence: number = 0,
    originalImagePath: string = ''
  ) {
    this.id = id
    this.name = name
    this.type = type
    this.number = number
    this.expiryDate = expiryDate
    this.imageUrl = imageUrl
    this.createTime = createTime
    this.updateTime = updateTime
    this.dynamicFields = dynamicFields
    this.recognitionConfidence = recognitionConfidence
    this.originalImagePath = originalImagePath
  }

  // 添加动态字段
  addDynamicField(key: string, value: string) {
    this.dynamicFields[key] = value
  }

  // 获取动态字段值
  getDynamicField(key: string): string {
    return this.dynamicFields[key] || ''
  }

  // 获取所有动态字段
  getAllDynamicFields(): Array<DynamicFieldItem> {
    const result: Array<DynamicFieldItem> = []
    let keys: string[] = Object.keys(this.dynamicFields);
    console.log("getAllDynamicFields", JSON.stringify(this.dynamicFields))
    keys.forEach((k) => {
      let val = this.dynamicFields[k]
      result.push({ key:k,value:val})
    })
    return result
  }

  // 转换为JSON对象（用于存储）
  toJSON(): DocumentItemJSON {
    const result: DocumentItemJSON = {
      id: this.id,
      name: this.name,
      type: this.type,
      number: this.number,
      expiryDate: this.expiryDate,
      imageUrl: this.imageUrl,
      createTime: this.createTime.toISOString(),
      updateTime: this.updateTime.toISOString(),
      dynamicFields: this.dynamicFields,
      recognitionConfidence: this.recognitionConfidence,
      originalImagePath: this.originalImagePath
    }
    return result
  }

  // 从JSON对象创建DocumentItem
  static fromJSON(json: DocumentItemJSON): DocumentItem {
    const dynamicFields: Record<string,string> = {}
    if (json.dynamicFields) {
      Object.keys(json.dynamicFields).forEach(key => {
        dynamicFields[key] = json.dynamicFields![key]
      })
    }
    
    const item = new DocumentItem(
      json.id || '',
      json.name || '',
      json.type || '',
      json.number || '',
      json.expiryDate || '',
      json.imageUrl || '',
      new Date(json.createTime || Date.now()),
      new Date(json.updateTime || Date.now()),
      dynamicFields,
      json.recognitionConfidence || 0,
      json.originalImagePath || ''
    )
    return item
  }
}

// 定义动态字段项接口
export interface DynamicFieldItem {
  key: string
  value: string
}

// 定义 JSON 接口
interface DocumentItemJSON {
  id?: string
  name?: string
  type?: string
  number?: string
  expiryDate?: string
  imageUrl?: string
  createTime?: string
  updateTime?: string
  dynamicFields?: Record<string, string>
  recognitionConfidence?: number
  originalImagePath?: string
} 