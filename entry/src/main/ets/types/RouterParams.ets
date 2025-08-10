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
}

export interface UploadParams {
  mode?: 'camera' | 'gallery'
  imagePath?: string
}

export interface SettingsParams {
  // 设置页面参数
}

// 通用路由参数类型
export type RouterParams = DocumentEditParams | DocumentPrintParams | DocumentDetailParams | UploadParams | SettingsParams
