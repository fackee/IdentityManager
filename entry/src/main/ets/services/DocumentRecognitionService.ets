import { RecognitionRequest, RecognitionResponse, RecognitionField } from '../types/DocumentRecognition'
import { http } from '@kit.NetworkKit'
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { buffer } from '@kit.ArkTS';

interface Response {
  success: boolean;
  response: string;
}

interface Request {
  prompt: string;
  image_base64: string;
  max_tokens: number;
  temperature: number;
}

interface DocumentType {
  '身份证': string[];
  '居住证': string[];
  '签证': string[];
  '护照': string[];
  '户口本': string[];
  '军人证': string[];
  '团员证': string[];
  '党员证': string[];
  '港澳通行证': string[];
  '从业资格证': string[];
  '英语四六级证': string[];
  '汽车驾驶证': string[];
  '国有土地使用证': string[];
  '行驶证': string[];
  '养路费证': string[];
  '营运证': string[];
  '营业执照': string[];
  '经营许可证': string[];
  '税务登记证': string[];
  '卫生许可证': string[];
  '消防许可证': string[];
  '结婚证': string[];
  '涉外婚姻证明': string[];
  '离婚证': string[];
  '出生证': string[];
  '预防接种证': string[];
  '节育证': string[];
  '养老保险证': string[];
  '毕业证': string[];
  '学位证': string[];
}

export class DocumentRecognitionService {
  // 代理服务配置
  private static readonly BASE_URL = 'http://47.111.83.157/llm'
  private static readonly SECRET_KEY = 'ECCF5F79691CAD50AF6328E42EFC749E'
  private static readonly APP_ID = 'freelancer.zhujx'
  private static readonly MULTIMODAL_ENDPOINT = '/api/multimodal'

  // 识别文档 - 使用代理服务
  static async recognizeDocument(imageBase64: string): Promise<RecognitionResponse> {
    try {
      console.log('开始使用代理服务识别文档...')

      // 调用代理服务进行图片识别
      const result = await DocumentRecognitionService.callProxyService(imageBase64)
      if (result.success) {
        console.log('代理服务识别成功')
        return DocumentRecognitionService.parseProxyResponse(result.response)
      }

      // 如果代理服务失败，使用备用模拟API
      console.log('代理服务识别失败，使用备用API...')
      return await DocumentRecognitionService.callBackupAPI(imageBase64)

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

  // 调用代理服务进行图片识别
  private static async callProxyService(imageBase64: string): Promise<Response> {
    try {
      const httpRequest = http.createHttp()

      // 构建请求体
      const requestBody: Request = {
        prompt: DocumentRecognitionService.buildPrompt(),
        image_base64: imageBase64,
        max_tokens: 2000,
        temperature: 0.1
      }

      // 生成认证头
      const authHeaders = await DocumentRecognitionService.generateAuthHeaders()

      const response = await httpRequest.request(
        `${DocumentRecognitionService.BASE_URL}${DocumentRecognitionService.MULTIMODAL_ENDPOINT}`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'X-Timestamp': authHeaders['X-Timestamp'],
            'X-AppId': authHeaders['X-AppId'],
            'X-Nonce': authHeaders['X-Nonce'],
            'X-Signature': authHeaders['X-Signature']
          },
          extraData: JSON.stringify(requestBody)
        }
      )

      if (response.responseCode === 200) {
        const result = JSON.parse(response.result.toString()) as Response
        console.log('代理服务响应:', result)
        return {
          success: true,
          response: result.response || ''
        }
      } else {
        console.error(`代理服务请求失败: ${response.result.toString()}`)
        throw new Error(`API请求失败: ${response.responseCode}`)
      }
    } catch (error) {
      console.error('调用代理服务失败:', error)
      throw new Error(error instanceof Error ? error.message : String(error))
    }
  }

  // 生成认证头
  private static async generateAuthHeaders(): Promise<Record<string, string>> {
    const timestamp = Math.floor(Date.now() / 1000).toString()
    const nonce = DocumentRecognitionService.generateNonce()

    // 构造签名字符串：secret-key + timestamp + appid + nonce
    const signString =
      `${DocumentRecognitionService.SECRET_KEY}${timestamp}${DocumentRecognitionService.APP_ID}${nonce}`

    // 生成签名 (使用SHA256加密)
    const signature = await DocumentRecognitionService.sha256(signString)

    return {
      "X-Timestamp": timestamp,
      "X-AppId": DocumentRecognitionService.APP_ID,
      "X-Nonce": nonce,
      "X-Signature": signature
    }
  }

  // 生成随机nonce
  private static generateNonce(): string {
    const chars = '0123456789abcdef'
    let result = ''
    for (let i = 0; i < 8; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    return result
  }

  // SHA256摘要算法实现
  private static async sha256(str: string): Promise<string> {
    try {
      let mdAlgName = 'SHA256'; // 摘要算法名
      let md = cryptoFramework.createMd(mdAlgName);
      
      // 将字符串转换为Uint8Array
      await md.update({ data: new Uint8Array(buffer.from(str, 'utf-8').buffer) });
      let mdResult = await md.digest();
      
      // 将结果转换为十六进制字符串
      return Array.from(mdResult.data)
        .map(byte => byte.toString(16).padStart(2, '0'))
        .join('');
    } catch (error) {
      console.error('SHA256计算失败:', error);
      // 如果加密库不可用，回退到简单哈希
      return DocumentRecognitionService.simpleHash(str);
    }
  }

  private static simpleHash(str: string): string {
    // 简单的哈希算法作为备用方案
    let hash = 0
    if (str.length === 0) {
      return hash.toString()
    }

    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i)
      hash = ((hash << 5) - hash) + char
      hash = hash & hash // 转换为32位整数
    }

    return Math.abs(hash).toString(16)
  }

  // 构建提示词
  private static buildPrompt(): string {
    return `请分析这张图片，判断是否为证件，如果是证件则识别证件类型并提取关键信息。

支持的证件类型列表（请严格按照以下列表识别，不在列表中的证件类型请归类为"其他"）：
- 身份证
- 居住证
- 签证
- 护照
- 户口本
- 军人证
- 团员证
- 党员证
- 港澳通行证
- 从业资格证
- 英语四六级证
- 汽车驾驶证
- 国有土地使用证
- 行驶证
- 养路费证
- 营运证
- 营业执照
- 经营许可证
- 税务登记证
- 卫生许可证
- 消防许可证
- 结婚证
- 涉外婚姻证明
- 离婚证
- 出生证
- 预防接种证
- 节育证
- 养老保险证
- 毕业证
- 学位证

请按照以下JSON格式返回结果：
{
  "isDocument": true/false,
  "documentType": "证件类型（必须是上述列表中的一种，如果不是证件或不在列表中请返回'其他'）",
  "confidence": 0.95,
  "message": "如果不是证件，请在此说明原因",
  "fields": [
    {
      "key": "name",
      "value": "姓名",
      "label": "姓名",
      "confidence": 0.95
    }
  ]
}

需要提取的字段包括但不限于：
- 姓名/持卡人姓名/持有人姓名
- 证件号码/证号/编号
- 性别
- 民族/国籍
- 出生日期/出生年月
- 住址/地址
- 签发机关/发证机关
- 有效期限/有效期至/有效期
- 发卡银行（银行卡）
- 准驾车型（驾驶证）
- 车牌号码（行驶证）
- 企业名称（营业执照等）
- 经营范围（营业执照等）
- 注册地址（营业执照等）
- 法定代表人（营业执照等）
- 注册资本（营业执照等）
- 成立日期（营业执照等）
- 学校名称（毕业证、学位证等）
- 专业（毕业证、学位证等）
- 学历层次（毕业证、学位证等）
- 毕业时间（毕业证、学位证等）
- 学位类型（学位证等）

请确保返回的是有效的JSON格式，不要包含其他文字说明。如果图片不是证件，请将isDocument设置为false，并在message中说明原因。`
  }

  // 解析代理服务响应
  private static parseProxyResponse(response: string): RecognitionResponse {
    try {
      // 尝试从响应中提取JSON
      const jsonMatch = response.match(/\{[\s\S]*\}/)
      if (!jsonMatch) {
        console.error('无法从响应中提取JSON:', response)
        throw new Error('无法从响应中提取JSON')
      }

      const parsedData = JSON.parse(jsonMatch[0]) as RecognitionResponse

      // 检查是否为证件
      if (parsedData.success === false) {
        return {
          success: true,
          documentType: '非证件',
          confidence: 0.9,
          fields: [],
          error: '上传的图片不是证件'
        }
      }

      // 验证证件类型是否在支持列表中
      const supportedTypes = [
        '身份证', '居住证', '签证', '护照', '户口本', '军人证', '团员证', '党员证',
        '港澳通行证', '从业资格证', '英语四六级证', '汽车驾驶证', '国有土地使用证',
        '行驶证', '养路费证', '营运证', '营业执照', '经营许可证', '税务登记证',
        '卫生许可证', '消防许可证', '结婚证', '涉外婚姻证明', '离婚证', '出生证',
        '预防接种证', '节育证', '养老保险证', '毕业证', '学位证'
      ]

      let documentType = parsedData.documentType || '其他'
      if (!supportedTypes.includes(documentType)) {
        documentType = '其他'
      }

      return {
        success: true,
        documentType: documentType,
        confidence: parsedData.confidence || 0.8,
        fields: parsedData.fields || []
      }
    } catch (error) {
      console.error('解析代理服务响应失败:', error)
      console.error('原始响应:', response)

      // 如果解析失败，尝试从文本中提取信息
      return DocumentRecognitionService.extractInfoFromText(response)
    }
  }

  // 从文本中提取信息（备用方案）
  private static extractInfoFromText(text: string): RecognitionResponse {
    const fields: RecognitionField[] = []
    let documentType = '其他'
    let confidence = 0.7
    let isDocument = true
    let message = ''

    // 简单的文本分析，提取可能的证件信息
    const lines = text.split('\n')
    const textLower = text.toLowerCase()

    // 检查是否为证件
    const nonDocumentKeywords =
      ['照片', '风景', '人物', '动物', '植物', '建筑', '食物', '商品', '广告', '海报', '传单', '报纸', '杂志', '书籍',
        '文件', '合同', '发票', '收据', '账单']
    for (const keyword of nonDocumentKeywords) {
      if (textLower.includes(keyword)) {
        isDocument = false
        message = `检测到非证件内容：${keyword}`
        break
      }
    }

    if (!isDocument) {
      return {
        success: true,
        documentType: '非证件',
        confidence: 0.8,
        fields: [],
        error: message
      }
    }

    // 识别证件类型
    const documentTypeMap: DocumentType = {
      '身份证': ['身份证', '居民身份证', '身份证明'],
      '居住证': ['居住证', '暂住证'],
      '签证': ['签证', 'visa'],
      '护照': ['护照', 'passport'],
      '户口本': ['户口本', '户口簿', '户籍'],
      '军人证': ['军人证', '军官证', '士兵证'],
      '团员证': ['团员证', '共青团'],
      '党员证': ['党员证', '党员'],
      '港澳通行证': ['港澳通行证', '港澳证'],
      '从业资格证': ['从业资格证', '资格证', '职业资格'],
      '英语四六级证': ['英语四六级', 'cet', '四级', '六级'],
      '汽车驾驶证': ['驾驶证', '驾照', '驾驶执照'],
      '国有土地使用证': ['土地使用证', '土地证'],
      '行驶证': ['行驶证', '车辆行驶证'],
      '养路费证': ['养路费证', '养路费'],
      '营运证': ['营运证', '营运许可证'],
      '营业执照': ['营业执照', '工商执照'],
      '经营许可证': ['经营许可证', '经营执照'],
      '税务登记证': ['税务登记证', '税务证'],
      '卫生许可证': ['卫生许可证', '卫生证'],
      '消防许可证': ['消防许可证', '消防证'],
      '结婚证': ['结婚证', '结婚证明'],
      '涉外婚姻证明': ['涉外婚姻', '涉外结婚'],
      '离婚证': ['离婚证', '离婚证明'],
      '出生证': ['出生证', '出生证明'],
      '预防接种证': ['预防接种证', '接种证'],
      '节育证': ['节育证', '节育证明'],
      '养老保险证': ['养老保险证', '养老证'],
      '毕业证': ['毕业证', '毕业证书'],
      '学位证': ['学位证', '学位证书']
    }

    const documentTypeEntries: Array<[string, string[]]> = Object.entries(documentTypeMap) as Array<[string, string[]]>
    for (let i = 0; i < documentTypeEntries.length; i++) {
      const type: string = documentTypeEntries[i][0]
      const keywords: string[] = documentTypeEntries[i][1]
      for (const keyword of keywords) {
        if (textLower.includes(keyword.toLowerCase())) {
          documentType = type
          confidence = 0.9
          break
        }
      }
      if (documentType !== '其他') {
        break
      }
    }

    // 提取字段信息
    for (const line of lines) {
      const trimmedLine = line.trim()

      // 提取姓名
      if (trimmedLine.includes('姓名') || trimmedLine.includes('name') || trimmedLine.includes('持卡人') ||
      trimmedLine.includes('持有人')) {
        const match = trimmedLine.match(/[：:]\s*(.+)/)
        if (match) {
          fields.push({
            key: 'name',
            value: match[1].trim(),
            label: '姓名',
            confidence: 0.8
          })
        }
      }

      // 提取证件号码
      if (trimmedLine.includes('号码') || trimmedLine.includes('number') || trimmedLine.includes('证号') ||
      trimmedLine.includes('编号')) {
        const match = trimmedLine.match(/[：:]\s*(.+)/)
        if (match) {
          fields.push({
            key: 'number',
            value: match[1].trim(),
            label: '证件号码',
            confidence: 0.8
          })
        }
      }

      // 提取性别
      if (trimmedLine.includes('性别') || trimmedLine.includes('sex')) {
        const match = trimmedLine.match(/[：:]\s*(.+)/)
        if (match) {
          fields.push({
            key: 'gender',
            value: match[1].trim(),
            label: '性别',
            confidence: 0.8
          })
        }
      }

      // 提取出生日期
      if (trimmedLine.includes('出生') || trimmedLine.includes('birth')) {
        const match = trimmedLine.match(/[：:]\s*(.+)/)
        if (match) {
          fields.push({
            key: 'birth',
            value: match[1].trim(),
            label: '出生日期',
            confidence: 0.8
          })
        }
      }

      // 提取地址
      if (trimmedLine.includes('地址') || trimmedLine.includes('住址') || trimmedLine.includes('address')) {
        const match = trimmedLine.match(/[：:]\s*(.+)/)
        if (match) {
          fields.push({
            key: 'address',
            value: match[1].trim(),
            label: '地址',
            confidence: 0.8
          })
        }
      }

      // 提取签发机关
      if (trimmedLine.includes('签发') || trimmedLine.includes('发证') || trimmedLine.includes('机关')) {
        const match = trimmedLine.match(/[：:]\s*(.+)/)
        if (match) {
          fields.push({
            key: 'issue',
            value: match[1].trim(),
            label: '签发机关',
            confidence: 0.8
          })
        }
      }

      // 提取有效期
      if (trimmedLine.includes('有效期') || trimmedLine.includes('期限')) {
        const match = trimmedLine.match(/[：:]\s*(.+)/)
        if (match) {
          fields.push({
            key: 'validity',
            value: match[1].trim(),
            label: '有效期限',
            confidence: 0.8
          })
        }
      }
    }

    return {
      success: true,
      documentType: documentType,
      confidence: confidence,
      fields: fields
    }
  }

  // 调用备用API
  private static async callBackupAPI(imageBase64: string): Promise<RecognitionResponse> {
    try {
      const request: RecognitionRequest = {
        imageBase64: imageBase64,
        imageType: 'jpeg'
      }

      // 模拟API调用 - 在实际项目中替换为真实的HTTP请求
      return await DocumentRecognitionService.mockRecognitionAPI(request)

      // 实际的HTTP请求代码（注释掉，因为需要真实的API地址）
      /*
      const httpRequest = http.createHttp()
      const response = await httpRequest.request(
        `${DocumentRecognitionService.BACKUP_API_BASE_URL}${DocumentRecognitionService.RECOGNITION_ENDPOINT}`,
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
      console.error('备用API调用失败:', error)
      throw new Error(error instanceof Error ? error.message : String(error))
    }
  }

  // 模拟识别API（用于测试）
  private static async mockRecognitionAPI(request: RecognitionRequest): Promise<RecognitionResponse> {
    // 模拟网络延迟
    await new Promise<void>(resolve => setTimeout(resolve, 2000))

    // 根据图片内容模拟不同的识别结果
    const imageLength = request.imageBase64.length
    const documentType = DocumentRecognitionService.getMockDocumentType(imageLength)

    return {
      success: true,
      documentType: documentType,
      confidence: 0.85 + Math.random() * 0.1, // 85%-95%的置信度
      fields: DocumentRecognitionService.getMockFields(documentType)
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
    const fieldTemplates: Record<string, RecognitionField[]> = {
      '身份证': [
        {
          key: 'name',
          value: '张三',
          confidence: 0.95,
          label: '姓名'
        },
        {
          key: 'gender',
          value: '男',
          confidence: 0.90,
          label: '性别'
        },
        {
          key: 'nation',
          value: '汉',
          confidence: 0.88,
          label: '民族'
        },
        {
          key: 'birth',
          value: '1990-01-01',
          confidence: 0.92,
          label: '出生日期'
        },
        {
          key: 'address',
          value: '北京市朝阳区',
          confidence: 0.85,
          label: '住址'
        },
        {
          key: 'number',
          value: '110101199001011234',
          confidence: 0.98,
          label: '公民身份号码'
        },
        {
          key: 'issue',
          value: '北京市公安局朝阳分局',
          confidence: 0.87,
          label: '签发机关'
        },
        {
          key: 'validity',
          value: '2025-12-31',
          confidence: 0.93,
          label: '有效期限'
        }
      ],
      '护照': [
        {
          key: 'surname',
          value: 'ZHANG',
          confidence: 0.94,
          label: '姓'
        },
        {
          key: 'given_name',
          value: 'SAN',
          confidence: 0.94,
          label: '名'
        },
        {
          key: 'nationality',
          value: 'CHN',
          confidence: 0.96,
          label: '国籍'
        },
        {
          key: 'birth_date',
          value: '01 JAN 1990',
          confidence: 0.92,
          label: '出生日期'
        },
        {
          key: 'passport_number',
          value: 'E12345678',
          confidence: 0.98,
          label: '护照号码'
        },
        {
          key: 'issue_date',
          value: '01 JAN 2020',
          confidence: 0.89,
          label: '签发日期'
        },
        {
          key: 'expiry_date',
          value: '01 JAN 2030',
          confidence: 0.91,
          label: '有效期至'
        },
        {
          key: 'authority',
          value: 'MPS Exit & Entry Administration',
          confidence: 0.86,
          label: '签发机关'
        }
      ],
      '驾驶证': [
        {
          key: 'name',
          value: '张三',
          confidence: 0.93,
          label: '姓名'
        },
        {
          key: 'gender',
          value: '男',
          confidence: 0.90,
          label: '性别'
        },
        {
          key: 'nationality',
          value: '中国',
          confidence: 0.95,
          label: '国籍'
        },
        {
          key: 'birth_date',
          value: '1990-01-01',
          confidence: 0.92,
          label: '出生日期'
        },
        {
          key: 'address',
          value: '北京市朝阳区',
          confidence: 0.84,
          label: '住址'
        },
        {
          key: 'license_number',
          value: '110101199001011234',
          confidence: 0.97,
          label: '驾驶证号码'
        },
        {
          key: 'issue_date',
          value: '2020-01-01',
          confidence: 0.88,
          label: '初次领证日期'
        },
        {
          key: 'validity',
          value: '2026-01-01',
          confidence: 0.91,
          label: '有效期限'
        },
        {
          key: 'vehicle_type',
          value: 'C1',
          confidence: 0.96,
          label: '准驾车型'
        }
      ],
      '银行卡': [
        {
          key: 'card_number',
          value: '6222 0000 0000 0000',
          confidence: 0.98,
          label: '卡号'
        },
        {
          key: 'card_type',
          value: '储蓄卡',
          confidence: 0.95,
          label: '卡类型'
        },
        {
          key: 'bank_name',
          value: '中国银行',
          confidence: 0.93,
          label: '发卡银行'
        },
        {
          key: 'validity',
          value: '12/25',
          confidence: 0.94,
          label: '有效期'
        },
        {
          key: 'holder_name',
          value: '张三',
          confidence: 0.89,
          label: '持卡人姓名'
        }
      ]
    }

    const fields = fieldTemplates[documentType]
    return fields || []
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

  // 测试代理服务连接
  static async testProxyConnection(): Promise<boolean> {
    try {
      const httpRequest = http.createHttp()

      const response = await httpRequest.request(
        `${DocumentRecognitionService.BASE_URL}/health`,
        {
          method: http.RequestMethod.GET,
          header: {
            'Content-Type': 'application/json'
          }
        }
      )

      if (response.responseCode === 200) {
        console.log('代理服务连接正常')
        return true
      } else {
        console.error('代理服务连接失败:', response.responseCode)
        return false
      }
    } catch (error) {
      console.error('测试代理服务连接失败:', error)
      return false
    }
  }
}
