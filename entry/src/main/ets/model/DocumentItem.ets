export class DocumentItem {
  id: string
  name: string
  type: string
  number: string
  expiryDate: string
  imageUrl: Resource
  createTime: Date
  updateTime: Date
  // 新增字段：动态表单数据
  dynamicFields: Map<string, string> = new Map()
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
    imageUrl: Resource = $r('app.media.background'),
    createTime: Date = new Date(),
    updateTime: Date = new Date(),
    dynamicFields: Map<string, string> = new Map(),
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
    this.dynamicFields.set(key, value)
  }

  // 获取动态字段值
  getDynamicField(key: string): string {
    return this.dynamicFields.get(key) || ''
  }

  // 获取所有动态字段
  getAllDynamicFields(): Array<{key: string, value: string}> {
    return Array.from(this.dynamicFields.entries()).map(([key, value]) => ({key, value}))
  }

  // 转换为JSON对象（用于存储）
  toJSON(): object {
    return {
      id: this.id,
      name: this.name,
      type: this.type,
      number: this.number,
      expiryDate: this.expiryDate,
      imageUrl: this.imageUrl,
      createTime: this.createTime.toISOString(),
      updateTime: this.updateTime.toISOString(),
      dynamicFields: Object.fromEntries(this.dynamicFields),
      recognitionConfidence: this.recognitionConfidence,
      originalImagePath: this.originalImagePath
    }
  }

  // 从JSON对象创建DocumentItem
  static fromJSON(json: {
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
  }): DocumentItem {
    const item = new DocumentItem(
      json.id || '',
      json.name || '',
      json.type || '',
      json.number || '',
      json.expiryDate || '',
      json.imageUrl || $r('app.media.background'),
      new Date(json.createTime || Date.now()),
      new Date(json.updateTime || Date.now()),
      new Map(Object.entries(json.dynamicFields || {})),
      json.recognitionConfidence || 0,
      json.originalImagePath || ''
    )
    return item
  }
} 