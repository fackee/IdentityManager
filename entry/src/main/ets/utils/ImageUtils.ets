import { camera, cameraPicker as picker } from '@kit.CameraKit'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import {
  PhotoPickerComponent,
  PickerController,
  PickerOptions,
  DataType,
  BaseItemInfo,
  ItemInfo,
  PhotoBrowserInfo,
  ItemType,
  ClickType,
  MaxCountType,
  PhotoBrowserRange,
  ReminderMode,
  photoAccessHelper
} from '@kit.MediaLibraryKit';
import { ImageSelectionResult } from '../types/DocumentRecognition'
import { PermissionUtils } from './PermissionUtils'

export class ImageUtils {
  // 相册选择相关状态（已废弃，现在直接在页面中使用PhotoPickerComponent）
  private static selectionCallback: ((result: ImageSelectionResult) => void) | null = null

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
    try {
      // 这里需要实现将图片URI转换为base64的逻辑
      // 由于HarmonyOS的API限制，这里暂时返回一个占位符
      // 在实际应用中，需要使用文件系统API读取图片数据并转换为base64
      console.log('转换图片URI为base64:', uri)
      
      // 模拟转换过程
      return 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k='
    } catch (error) {
      console.error('图片转换失败:', error)
      throw new Error('图片转换失败')
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
    // 清理相册选择相关状态
    ImageUtils.selectionCallback = null;
  }
}
