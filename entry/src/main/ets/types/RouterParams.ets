/**
 * 路由参数类型定义
 */
export interface DocumentEditParams {
  mode?: string
  documentId?: string
  documentName?: string
  documentType?: string
  documentNumber?: string
  documentExpiry?: string
  documentImage?: string
}

export interface DocumentPrintParams {
  mode?: string
  documentId?: string
  documentName?: string
  documentType?: string
  documentNumber?: string
  documentExpiry?: string
  documentImage?: string
}

export interface DocumentDetailParams {
  documentId?: string
  documentName?: string
  documentType?: string
  documentNumber?: string
  documentExpiry?: string
  documentImage?: string
  createTime?: Date
  updateTime?: Date
  dynamicFields?: Record<string,string>

}

export interface UploadParams {
  mode?: 'camera' | 'gallery' | 'edit'
  imagePath?: string
  documentId?: string
  documentName?: string
  documentType?: string
  documentNumber?: string
  documentExpiry?: string
  documentImage?: string
}

export interface SettingsParams {
  // 设置页面参数
}

// 通用路由参数类型
export type RouterParams = DocumentEditParams | DocumentPrintParams | DocumentDetailParams | UploadParams | SettingsParams
