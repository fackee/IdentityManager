import { camera } from '@kit.MultimediaKit'
import { picker } from '@kit.MultimediaKit'
import { mediaLibrary } from '@kit.MultimediaKit'
import { ImageSelectionResult } from '../types/DocumentRecognition'
import { PermissionUtils } from './PermissionUtils'

export class ImageUtils {
  private static cameraManager: camera.CameraManager | null = null
  private static photoPicker: picker.PhotoPicker | null = null

  // 初始化相机管理器
  static async initializeCamera(context: Context): Promise<boolean> {
    try {
      ImageUtils.cameraManager = camera.getCameraManager(context)
      console.log('相机管理器初始化成功')
      return true
    } catch (error) {
      console.error('相机管理器初始化失败:', error)
      return false
    }
  }

  // 拍照
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

      // 初始化相机
      if (!ImageUtils.cameraManager) {
        await ImageUtils.initializeCamera(context)
      }

      if (!ImageUtils.cameraManager) {
        return {
          success: false,
          error: '相机初始化失败'
        }
      }

      // 获取相机列表
      const cameras = await ImageUtils.cameraManager.getCameras()
      if (cameras.length === 0) {
        return {
          success: false,
          error: '没有可用的相机'
        }
      }

      // 使用后置相机
      const backCamera = cameras.find(cam => cam.position === camera.Position.POSITION_BACK)
      const cameraDevice = backCamera || cameras[0]

      // 创建相机输入
      const cameraInput = await ImageUtils.cameraManager.createCameraInput(cameraDevice)
      await cameraInput.open()

      // 创建预览输出
      const previewOutput = await ImageUtils.cameraManager.createPreviewOutput()
      await previewOutput.release()

      // 创建照片输出
      const photoOutput = await ImageUtils.cameraManager.createPhotoOutput()
      await photoOutput.release()

      // 拍照
      const photo = await photoOutput.capture()
      
      // 关闭相机
      await cameraInput.close()

      // 处理照片
      const imagePath = await ImageUtils.savePhotoToGallery(photo)
      const imageBase64 = await ImageUtils.convertImageToBase64(imagePath)

      return {
        success: true,
        imagePath: imagePath,
        imageBase64: imageBase64
      }

    } catch (error) {
      console.error('拍照失败:', error)
      return {
        success: false,
        error: error instanceof Error ? error.message : '拍照失败'
      }
    }
  }

  // 从相册选择图片
  static async selectFromGallery(context: Context): Promise<ImageSelectionResult> {
    try {
      // 检查存储权限
      const hasPermission = await PermissionUtils.requestStoragePermission()
      if (!hasPermission) {
        return {
          success: false,
          error: '没有存储权限'
        }
      }

      // 创建图片选择器
      ImageUtils.photoPicker = picker.createPhotoPicker()
      
      // 设置选择选项
      const photoSelectOptions: picker.PhotoSelectOptions = {
        MIMEType: picker.PhotoViewMIMEType.IMAGE_TYPE,
        maxSelectNumber: 1
      }

      // 选择图片
      const photoAssets = await ImageUtils.photoPicker.select(photoSelectOptions)
      
      if (photoAssets.length === 0) {
        return {
          success: false,
          error: '未选择图片'
        }
      }

      const photoAsset = photoAssets[0]
      
      // 获取图片路径
      const imagePath = await ImageUtils.getImagePath(photoAsset)
      const imageBase64 = await ImageUtils.convertImageToBase64(imagePath)

      return {
        success: true,
        imagePath: imagePath,
        imageBase64: imageBase64
      }

    } catch (error) {
      console.error('选择图片失败:', error)
      return {
        success: false,
        error: error instanceof Error ? error.message : '选择图片失败'
      }
    }
  }

  // 保存照片到相册
  private static async savePhotoToGallery(photo: camera.Photo): Promise<string> {
    try {
      const media = mediaLibrary.getMediaLibrary(getContext())
      const fileAsset = await media.createAsset(
        mediaLibrary.MediaType.IMAGE,
        `document_${Date.now()}.jpg`
      )
      
      const fd = await fileAsset.open('rw')
      await fd.write(photo.buffer)
      await fd.close()
      
      return fileAsset.uri
    } catch (error) {
      console.error('保存照片失败:', error)
      throw error
    }
  }

  // 获取图片路径
  private static async getImagePath(photoAsset: picker.PhotoAsset): Promise<string> {
    try {
      const fd = await photoAsset.open('r')
      const buffer = await fd.read()
      await fd.close()
      
      // 保存到临时文件
      const media = mediaLibrary.getMediaLibrary(getContext())
      const fileAsset = await media.createAsset(
        mediaLibrary.MediaType.IMAGE,
        `selected_${Date.now()}.jpg`
      )
      
      const writeFd = await fileAsset.open('rw')
      await writeFd.write(buffer)
      await writeFd.close()
      
      return fileAsset.uri
    } catch (error) {
      console.error('获取图片路径失败:', error)
      throw error
    }
  }

  // 转换图片为Base64
  private static async convertImageToBase64(imagePath: string): Promise<string> {
    try {
      const media = mediaLibrary.getMediaLibrary(getContext())
      const fileAsset = await media.fetchFileAssets(mediaLibrary.FileKey.URI, imagePath)
      
      if (fileAsset.getCount() === 0) {
        throw new Error('图片文件不存在')
      }
      
      const asset = await fileAsset.getFirstObject()
      const fd = await asset.open('r')
      const buffer = await fd.read()
      await fd.close()
      
      // 转换为Base64
      const base64 = buffer.toString('base64')
      return base64
    } catch (error) {
      console.error('转换图片为Base64失败:', error)
      throw error
    }
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
    if (ImageUtils.cameraManager) {
      ImageUtils.cameraManager = null
    }
    if (ImageUtils.photoPicker) {
      ImageUtils.photoPicker = null
    }
  }
}
