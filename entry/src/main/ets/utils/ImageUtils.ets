import { camera, cameraPicker as picker } from '@kit.CameraKit'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import image from '@ohos.multimedia.image'
import util from '@ohos.util'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import dataSharePredicates from '@ohos.data.dataSharePredicates'
import { ImageSelectionResult } from '../types/DocumentRecognition'
import { PermissionUtils } from './PermissionUtils'

// 媒体数据处理器
class MediaDataHandler implements photoAccessHelper.MediaAssetDataHandler<ArrayBuffer> {
  private resolve: (value: string) => void
  private reject: (reason: Error) => void

  constructor(resolve: (value: string) => void, reject: (reason: Error) => void) {
    this.resolve = resolve
    this.reject = reject
    
    // 绑定方法以保持this上下文
    this.onDataPrepared = this.onDataPrepared.bind(this)
    this.onError = this.onError.bind(this)
  }

  onDataPrepared = (imageData: ArrayBuffer): void => {
    try {
      console.log('接收到图片数据，大小:', imageData.byteLength)
      let base64 = new util.Base64Helper
      let arrayStr = base64.encodeToStringSync(new Uint8Array(imageData))
      console.log('图片数据转换为base64成功, 大小', `${arrayStr.length}`)
      this.resolve(`${arrayStr}`)
    } catch (error) {
      console.error('图片数据转换失败:', error)
      this.reject(new Error(`图片数据转换失败: ${error instanceof Error ? error.message : '未知错误'}`))
    }
  }

  onError = (error: Error): void => {
    console.error('MediaDataHandler错误:', error)
    this.reject(error)
  }
}

export class ImageUtils {
  // 相册选择相关状态（已废弃，现在直接在页面中使用PhotoPickerComponent）
  private static selectionCallback: ((result: ImageSelectionResult) => void) | null = null

  // 获取Context的辅助方法
  private static getContext(): Context | undefined {
    try {
      // 这里需要从当前页面获取Context
      // 由于这是静态方法，我们需要通过其他方式获取Context
      // 暂时返回undefined，实际使用时需要从页面传入
      return undefined
    } catch (error) {
      console.error('获取Context失败:', error)
      return undefined
    }
  }

  // 创建拍照配置文件
  static createPickerProfile(context: Context): picker.PickerProfile {
    let pathDir = context.filesDir;
    let fileName = `${new Date().getTime()}`;
    let filePath = pathDir + `/${fileName}.jpg`;
    
    // 创建文件
    try {
      fileIo.createRandomAccessFileSync(filePath, fileIo.OpenMode.CREATE);
    } catch (error) {
      console.error('创建文件失败:', error);
      // 如果创建失败，使用临时文件名
      filePath = pathDir + `/${fileName}.tmp`;
      fileIo.createRandomAccessFileSync(filePath, fileIo.OpenMode.CREATE);
    }
    
    let uri = fileUri.getUriFromPath(filePath);
    let pickerProfile: picker.PickerProfile = {
      cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK,
      saveUri: uri
    };
    return pickerProfile;
  }

  // 获取拍照结果
  static async getPickerResult(context: Context, pickerProfile: picker.PickerProfile): Promise<picker.PickerResult> {
    let result: picker.PickerResult =
      await picker.pick(context, [picker.PickerMediaType.PHOTO], pickerProfile);
    console.info(`picker resultCode: ${result.resultCode}, resultUri: ${result.resultUri}, mediaType: ${result.mediaType}`);
    return result;
  }

  // 拍照（使用新的cameraPicker API）
  static async takePhoto(context: Context): Promise<ImageSelectionResult> {
    try {
      // 检查相机权限
      const hasPermission = await PermissionUtils.requestCameraPermission()
      if (!hasPermission) {
        return {
          success: false,
          error: '没有相机权限'
        }
      }

      // 创建拍照配置文件
      const pickerProfile = ImageUtils.createPickerProfile(context);
      
      // 执行拍照
      const result = await ImageUtils.getPickerResult(context, pickerProfile);
      
      if (result.resultCode === 0 && result.resultUri) {
        // 拍照成功
        console.info('拍照成功，图片URI:', result.resultUri);
        return {
          success: true,
          imagePath: result.resultUri,
          imageBase64: '' // 暂时为空，需要时可以转换
        }
      } else {
        // 拍照失败或被取消
        console.error('拍照失败或被取消，resultCode:', result.resultCode);
        return {
          success: false,
          error: result.resultCode === -1 ? '用户取消拍照' : '拍照失败'
        }
      }

    } catch (error) {
      console.error('拍照失败:', error)
      return {
        success: false,
        error: error instanceof Error ? error.message : '拍照失败'
      }
    }
  }

  // 从相册选择图片（已废弃，现在直接在页面中使用PhotoPickerComponent）
  static async selectFromGallery(context: Context): Promise<ImageSelectionResult> {
    console.warn('selectFromGallery方法已废弃，请直接在页面中使用PhotoPickerComponent')
    return {
      success: false,
      error: '方法已废弃'
    }
  }

  // 将图片URI转换为base64
  static async convertImageUriToBase64(uri: string): Promise<string> {
    return new Promise((resolve, reject) => {
      try {
        // 检查URI是否有效
        if (!uri || uri.trim() === '') {
          reject(new Error('无效的图片URI'))
          return
        }

        // 如果是文件路径，检查文件是否存在
        if (uri.startsWith('file://') || !uri.startsWith('http')) {
          try {
            // 尝试获取文件信息来验证文件是否存在
            const filePath = uri.startsWith('file://') ? uri.substring(7) : uri
            const fileInfo = fileIo.statSync(filePath)
            if (!fileInfo.isFile()) {
              reject(new Error(`文件不存在或不是有效文件: ${uri}`))
              return
            }
          } catch (fileError) {
            console.error('文件检查失败:', fileError)
            // 如果文件检查失败，仍然尝试创建ImageSource，但记录警告
            console.warn('文件检查失败，尝试直接创建ImageSource:', uri)
          }
        }

        // 创建ImageSource并转换为base64
        image.createImagePacker().packing(image.createImageSource(uri), { 
          format: 'image/jpg', 
          quality: 100, 
          bufferSize: 50 * 1024 * 1024 
        })
        .then((value: ArrayBuffer) => {
          let base64 = new util.Base64Helper
          let arrayStr = base64.encodeToStringSync(new Uint8Array(value))
          resolve(`data:image/jpg;base64,${arrayStr}`)
        })
        .catch((err: Error) => {
          console.error('图片转换失败:', err)
          reject(new Error(`图片转换失败: ${err.message}`))
        })
      } catch (error) {
        console.error('convertImageUriToBase64 初始化失败:', error)
        reject(new Error(`图片转换初始化失败: ${error instanceof Error ? error.message : '未知错误'}`))
      }
    })
  }

  // 处理相册图片URI转换为base64（专门处理MediaLibraryKit返回的URI）
  static async convertGalleryImageToBase64(uri: string, context?: Context): Promise<string> {
    return new Promise((resolve, reject) => {
      try {
        if (!uri || uri.trim() === '') {
          reject(new Error('无效的图片URI'))
          return
        }

        console.log('开始处理相册图片URI:', uri)

        // 获取Context
        const appContext = context || ImageUtils.getContext()
        if (!appContext) {
          reject(new Error('无法获取应用上下文'))
          return
        }

        // 获取PhotoAccessHelper实例
        const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(appContext)
        
        // 使用新的API获取图片数据
        const processImage = async () => {
          try {
            // 创建查询条件
            let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates()
            predicates.equalTo(photoAccessHelper.PhotoKeys.URI, uri)
            
            // 设置查询选项
            let fetchOptions: photoAccessHelper.FetchOptions = {
              fetchColumns: [photoAccessHelper.PhotoKeys.TITLE, photoAccessHelper.PhotoKeys.URI],
              predicates: predicates
            }

            console.log('开始查询图片资源，URI:', uri)
            
            // 获取图片资源
            let fetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> = await phAccessHelper.getAssets(fetchOptions)
            let photoAsset: photoAccessHelper.PhotoAsset = await fetchResult.getFirstObject()
            
            if (!photoAsset) {
              throw new Error('未找到对应的图片资源')
            }
            
            console.log('获取到图片资源，URI:', photoAsset.uri)
            console.log('图片标题:', photoAsset.get(photoAccessHelper.PhotoKeys.TITLE))
            
            // 请求图片数据
            let requestOptions: photoAccessHelper.RequestOptions = {
              deliveryMode: photoAccessHelper.DeliveryMode.HIGH_QUALITY_MODE,
            }
            
            console.log('开始请求图片数据...')
            await photoAccessHelper.MediaAssetManager.requestImageData(
              appContext, 
              photoAsset, 
              requestOptions, 
              new MediaDataHandler(resolve, reject)
            )
            
            console.log('图片数据请求已发送')
            fetchResult.close()
            
          } catch (apiError) {
            console.error('新API处理失败，尝试备用方法:', apiError)
            reject(new Error(`API处理失败: ${apiError instanceof Error ? apiError.message : '未知错误'}`))
          }
        }

        // 执行异步处理
        processImage().catch((error: Error) => {
          console.error('processImage 失败:', error)
          reject(new Error(`相册图片转换失败: ${error instanceof Error ? error.message : '未知错误'}`))
        })
        
      } catch (error) {
        console.error('convertGalleryImageToBase64 失败:', error)
        reject(new Error(`相册图片转换失败: ${error instanceof Error ? error.message : '未知错误'}`))
      }
    })
  }

  // 处理HarmonyOS相册内部路径
  static async convertHarmonyOSPhotoPath(uri: string): Promise<string> {
    return new Promise(async (resolve, reject) => {
      try {
        console.log('处理HarmonyOS相册路径:', uri)
        
        // 如果是media/Photo格式的路径，尝试转换为file://路径
        if (uri.includes('media/Photo')) {
          try {
            // 尝试在系统相册目录中查找文件
            const systemPhotoPath = `/storage/emulated/0/Pictures/${uri}`
            console.log('尝试系统相册路径:', systemPhotoPath)
            
            const fileInfo = fileIo.statSync(systemPhotoPath)
            if (fileInfo.isFile()) {
              console.log('找到系统相册文件，大小:', fileInfo.size)
              const fileUri = `file://${systemPhotoPath}`
              const result = await ImageUtils.convertImageUriToBase64(fileUri)
              resolve(result)
              return
            }
          } catch (pathError) {
            console.log('系统相册路径不存在:', pathError)
          }
          
          // 尝试其他可能的路径
          const possiblePaths = [
            `/storage/emulated/0/DCIM/${uri}`,
            `/storage/emulated/0/Pictures/${uri}`,
            `/data/media/0/Pictures/${uri}`,
            `/data/media/0/DCIM/${uri}`
          ]
          
          for (const path of possiblePaths) {
            try {
              console.log('尝试路径:', path)
              const fileInfo = fileIo.statSync(path)
              if (fileInfo.isFile()) {
                console.log('找到文件:', path)
                const fileUri = `file://${path}`
                const result = await ImageUtils.convertImageUriToBase64(fileUri)
                resolve(result)
                return
              }
            } catch (error) {
              console.log('路径不存在:', path)
            }
          }
        }
        
        // 如果所有路径都失败，抛出错误
        reject(new Error(`无法找到相册文件: ${uri}`))
      } catch (error) {
        console.error('convertHarmonyOSPhotoPath 失败:', error)
        reject(new Error(`HarmonyOS相册路径转换失败: ${error instanceof Error ? error.message : '未知错误'}`))
      }
    })
  }

  // 调试方法：打印URI信息
  static async debugUriInfo(uri: string): Promise<void> {
    console.log('=== URI调试信息 ===')
    console.log('原始URI:', uri)
    console.log('URI类型:', typeof uri)
    console.log('URI长度:', uri?.length)
    
    if (uri) {
      console.log('是否以file://开头:', uri.startsWith('file://'))
      console.log('是否以http开头:', uri.startsWith('http'))
      console.log('是否以content://开头:', uri.startsWith('content://'))
      console.log('是否以data:开头:', uri.startsWith('data:'))
      
      if (uri.startsWith('file://')) {
        const filePath = uri.substring(7)
        console.log('文件路径:', filePath)
        try {
          const fileInfo = fileIo.statSync(filePath)
          console.log('文件存在:', true)
          console.log('文件大小:', fileInfo.size)
          console.log('是否为文件:', fileInfo.isFile())
        } catch (error) {
          console.log('文件不存在或无法访问:', error)
        }
      }
    }
    console.log('==================')
  }

  // 压缩图片
  static async compressImage(imagePath: string, quality: number = 0.8): Promise<string> {
    try {
      // 这里可以实现图片压缩逻辑
      // 由于HarmonyOS的图片处理API限制，这里暂时返回原路径
      console.log('图片压缩功能待实现')
      return imagePath
    } catch (error) {
      console.error('图片压缩失败:', error)
      return imagePath
    }
  }

  // 清理资源
  static cleanup() {
    // 清理相册选择相关状态
    ImageUtils.selectionCallback = null;
  }
}
