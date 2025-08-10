import { RecognitionRequest, RecognitionResponse, RecognitionField } from '../types/DocumentRecognition'
import { http } from '@kit.NetworkKit'

export class DocumentRecognitionService {
  private static readonly API_BASE_URL = 'https://api.example.com' // 替换为实际的API地址
  private static readonly RECOGNITION_ENDPOINT = '/document/recognize'

  // 识别文档
  static async recognizeDocument(imageBase64: string): Promise<RecognitionResponse> {
    try {
      const request: RecognitionRequest = {
        imageBase64: imageBase64,
        imageType: 'jpeg'
      }

      // 模拟API调用 - 在实际项目中替换为真实的HTTP请求
      return await this.mockRecognitionAPI(request)
      
      // 实际的HTTP请求代码（注释掉，因为需要真实的API地址）
      /*
      const httpRequest = http.createHttp()
      const response = await httpRequest.request(
        `${this.API_BASE_URL}${this.RECOGNITION_ENDPOINT}`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: JSON.stringify(request)
        }
      )
      
      if (response.responseCode === 200) {
        return JSON.parse(response.result.toString()) as RecognitionResponse
      } else {
        throw new Error(`API请求失败: ${response.responseCode}`)
      }
      */
    } catch (error) {
      console.error('文档识别失败:', error)
      return {
        success: false,
        documentType: '',
        confidence: 0,
        fields: [],
        error: error instanceof Error ? error.message : '未知错误'
      }
    }
  }

  // 模拟识别API（用于测试）
  private static async mockRecognitionAPI(request: RecognitionRequest): Promise<RecognitionResponse> {
    // 模拟网络延迟
    await new Promise(resolve => setTimeout(resolve, 2000))

    // 根据图片内容模拟不同的识别结果
    const imageLength = request.imageBase64.length
    const documentType = this.getMockDocumentType(imageLength)
    
    return {
      success: true,
      documentType: documentType,
      confidence: 0.85 + Math.random() * 0.1, // 85%-95%的置信度
      fields: this.getMockFields(documentType)
    }
  }

  // 获取模拟的文档类型
  private static getMockDocumentType(imageLength: number): string {
    const types = ['身份证', '护照', '驾驶证', '银行卡']
    const index = imageLength % types.length
    return types[index]
  }

  // 获取模拟的识别字段
  private static getMockFields(documentType: string): RecognitionField[] {
    const fieldTemplates: { [key: string]: RecognitionField[] } = {
      '身份证': [
        { key: 'name', value: '张三', confidence: 0.95, label: '姓名' },
        { key: 'gender', value: '男', confidence: 0.90, label: '性别' },
        { key: 'nation', value: '汉', confidence: 0.88, label: '民族' },
        { key: 'birth', value: '1990-01-01', confidence: 0.92, label: '出生日期' },
        { key: 'address', value: '北京市朝阳区', confidence: 0.85, label: '住址' },
        { key: 'number', value: '110101199001011234', confidence: 0.98, label: '公民身份号码' },
        { key: 'issue', value: '北京市公安局朝阳分局', confidence: 0.87, label: '签发机关' },
        { key: 'validity', value: '2025-12-31', confidence: 0.93, label: '有效期限' }
      ],
      '护照': [
        { key: 'surname', value: 'ZHANG', confidence: 0.94, label: '姓' },
        { key: 'given_name', value: 'SAN', confidence: 0.94, label: '名' },
        { key: 'nationality', value: 'CHN', confidence: 0.96, label: '国籍' },
        { key: 'birth_date', value: '01 JAN 1990', confidence: 0.92, label: '出生日期' },
        { key: 'passport_number', value: 'E12345678', confidence: 0.98, label: '护照号码' },
        { key: 'issue_date', value: '01 JAN 2020', confidence: 0.89, label: '签发日期' },
        { key: 'expiry_date', value: '01 JAN 2030', confidence: 0.91, label: '有效期至' },
        { key: 'authority', value: 'MPS Exit & Entry Administration', confidence: 0.86, label: '签发机关' }
      ],
      '驾驶证': [
        { key: 'name', value: '张三', confidence: 0.93, label: '姓名' },
        { key: 'gender', value: '男', confidence: 0.90, label: '性别' },
        { key: 'nationality', value: '中国', confidence: 0.95, label: '国籍' },
        { key: 'birth_date', value: '1990-01-01', confidence: 0.92, label: '出生日期' },
        { key: 'address', value: '北京市朝阳区', confidence: 0.84, label: '住址' },
        { key: 'license_number', value: '110101199001011234', confidence: 0.97, label: '驾驶证号码' },
        { key: 'issue_date', value: '2020-01-01', confidence: 0.88, label: '初次领证日期' },
        { key: 'validity', value: '2026-01-01', confidence: 0.91, label: '有效期限' },
        { key: 'vehicle_type', value: 'C1', confidence: 0.96, label: '准驾车型' }
      ],
      '银行卡': [
        { key: 'card_number', value: '6222 0000 0000 0000', confidence: 0.98, label: '卡号' },
        { key: 'card_type', value: '储蓄卡', confidence: 0.95, label: '卡类型' },
        { key: 'bank_name', value: '中国银行', confidence: 0.93, label: '发卡银行' },
        { key: 'validity', value: '12/25', confidence: 0.94, label: '有效期' },
        { key: 'holder_name', value: '张三', confidence: 0.89, label: '持卡人姓名' }
      ]
    }

    return fieldTemplates[documentType] || []
  }

  // 验证识别结果
  static validateRecognitionResult(result: RecognitionResponse): boolean {
    if (!result.success) {
      return false
    }

    if (!result.documentType || result.documentType.trim() === '') {
      return false
    }

    if (result.confidence < 0.5) {
      return false
    }

    if (!result.fields || result.fields.length === 0) {
      return false
    }

    return true
  }

  // 格式化识别结果用于显示
  static formatRecognitionResult(result: RecognitionResponse): string {
    if (!result.success) {
      return '识别失败'
    }

    let formatted = `文档类型: ${result.documentType}\n`
    formatted += `置信度: ${(result.confidence * 100).toFixed(1)}%\n\n`
    formatted += '识别字段:\n'

    result.fields.forEach(field => {
      formatted += `${field.label}: ${field.value}\n`
    })

    return formatted
  }
}
