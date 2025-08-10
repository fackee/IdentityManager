// 文档识别请求参数
export interface RecognitionRequest {
  imageBase64: string
  imageType: string
}

// 文档识别响应结果
export interface RecognitionResponse {
  success: boolean
  documentType: string
  confidence: number
  fields: RecognitionField[]
  error?: string
}

// 识别字段
export interface RecognitionField {
  key: string
  value: string
  confidence: number
  label: string
}

// 文档类型定义
export interface DocumentTypeInfo {
  type: string
  displayName: string
  icon: string
  count: number
}

// 拍照/相册选择结果
export interface ImageSelectionResult {
  success: boolean
  imagePath?: string
  imageBase64?: string
  error?: string
}

// 上传页面参数
export interface UploadPageParams {
  mode?: 'camera' | 'gallery'
  imagePath?: string
}
