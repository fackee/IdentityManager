import { camera } from '@kit.CameraKit'
import { image } from '@kit.ImageKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { picker } from '@kit.MultimediaKit'
import { mediaLibrary } from '@kit.MultimediaKit'
import { ImageSelectionResult } from '../types/DocumentRecognition'
import { PermissionUtils } from './PermissionUtils'

export class ImageUtils {
  private static cameraManager: camera.CameraManager | null = null
  private static photoPicker: picker.PhotoPicker | null = null
  private static photoSession: camera.PhotoSession | null = null
  private static cameraInput: camera.CameraInput | null = null
  private static previewOutput: camera.PreviewOutput | null = null
  private static photoOutput: camera.PhotoOutput | null = null

  // 设置拍照输出回调
  private static setPhotoOutputCb(photoOutput: camera.PhotoOutput): void {
    // 设置回调之后，调用photoOutput的capture方法，就会将拍照的buffer回传到回调中。
    photoOutput.on('photoAvailable', (errCode: BusinessError, photo: camera.Photo): void => {
      console.info('getPhoto start')
      console.error(`err: ${errCode}`)
      if (errCode || photo === undefined) {
        console.error('getPhoto failed')
        return
      }
      let imageObj = photo.main
      imageObj.getComponent(image.ComponentType.JPEG, (errCode: BusinessError, component: image.Component): void => {
        console.info('getComponent start')
        if (errCode || component === undefined) {
          console.error('getComponent failed')
          return
        }
        let buffer: ArrayBuffer
        if (component.byteBuffer) {
          buffer = component.byteBuffer
          // 这里可以处理拍照得到的buffer数据
          console.info('拍照成功，获得图片buffer')
        } else {
          console.error('byteBuffer is null')
          return
        }

        // buffer处理结束后需要释放该资源，如果未正确释放资源会导致后续拍照获取不到buffer。
        imageObj.release()
      })
    })
  }

  // 初始化相机管理器
  static async initializeCamera(context: Context): Promise<boolean> {
    try {
      ImageUtils.cameraManager = camera.getCameraManager(context)
      if (!ImageUtils.cameraManager) {
        console.error("camera.getCameraManager error")
        return false
      }
      
      // 监听相机状态变化
      ImageUtils.cameraManager.on('cameraStatus', (err: BusinessError, cameraStatusInfo: camera.CameraStatusInfo) => {
        if (err !== undefined && err.code !== 0) {
          console.error('cameraStatus with errorCode = ' + err.code)
          return
        }
        console.info(`camera : ${cameraStatusInfo.camera.cameraId}`)
        console.info(`status: ${cameraStatusInfo.status}`)
      })
      
      console.log('相机管理器初始化成功')
      return true
    } catch (error) {
      console.error('相机管理器初始化失败:', error)
      return false
    }
  }

  // 拍照
  static async takePhoto(context: Context, surfaceId: string): Promise<ImageSelectionResult> {
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
        const initialized = await ImageUtils.initializeCamera(context)
        if (!initialized) {
          return {
            success: false,
            error: '相机初始化失败'
          }
        }
      }

      // 获取相机列表
      let cameraArray: Array<camera.CameraDevice> = ImageUtils.cameraManager!.getSupportedCameras()
      if (cameraArray.length <= 0) {
        console.error("cameraManager.getSupportedCameras error")
        return {
          success: false,
          error: '没有可用的相机'
        }
      }

      // 打印相机信息
      for (let index = 0; index < cameraArray.length; index++) {
        console.info('cameraId : ' + cameraArray[index].cameraId)
        console.info('cameraPosition : ' + cameraArray[index].cameraPosition)
        console.info('cameraType : ' + cameraArray[index].cameraType)
        console.info('connectionType : ' + cameraArray[index].connectionType)
      }

      // 创建相机输入流
      let cameraInput: camera.CameraInput | undefined = undefined
      try {
        cameraInput = ImageUtils.cameraManager!.createCameraInput(cameraArray[0])
      } catch (error) {
        let err = error as BusinessError
        console.error('Failed to createCameraInput errorCode = ' + err.code)
        return {
          success: false,
          error: '创建相机输入失败'
        }
      }
      if (cameraInput === undefined) {
        return {
          success: false,
          error: '相机输入创建失败'
        }
      }

      // 监听cameraInput错误信息
      let cameraDevice: camera.CameraDevice = cameraArray[0]
      cameraInput.on('error', cameraDevice, (error: BusinessError) => {
        console.error(`Camera input error code: ${error.code}`)
      })

      // 打开相机
      await cameraInput.open()

      // 获取支持的模式类型
      let sceneModes: Array<camera.SceneMode> = ImageUtils.cameraManager!.getSupportedSceneModes(cameraArray[0])
      let isSupportPhotoMode: boolean = sceneModes.indexOf(camera.SceneMode.NORMAL_PHOTO) >= 0
      if (!isSupportPhotoMode) {
        console.error('photo mode not support')
        return {
          success: false,
          error: '不支持拍照模式'
        }
      }

      // 获取相机设备支持的输出流能力
      let cameraOutputCap: camera.CameraOutputCapability = ImageUtils.cameraManager!.getSupportedOutputCapability(cameraArray[0], camera.SceneMode.NORMAL_PHOTO)
      if (!cameraOutputCap) {
        console.error("cameraManager.getSupportedOutputCapability error")
        return {
          success: false,
          error: '获取相机输出能力失败'
        }
      }
      console.info("outputCapability: " + JSON.stringify(cameraOutputCap))

      let previewProfilesArray: Array<camera.Profile> = cameraOutputCap.previewProfiles
      if (!previewProfilesArray) {
        console.error("createOutput previewProfilesArray == null || undefined")
        return {
          success: false,
          error: '预览配置获取失败'
        }
      }

      let photoProfilesArray: Array<camera.Profile> = cameraOutputCap.photoProfiles
      if (!photoProfilesArray) {
        console.error("createOutput photoProfilesArray == null || undefined")
        return {
          success: false,
          error: '拍照配置获取失败'
        }
      }

      // 创建预览输出流
      let previewOutput: camera.PreviewOutput | undefined = undefined
      try {
        previewOutput = ImageUtils.cameraManager!.createPreviewOutput(previewProfilesArray[0], surfaceId)
      } catch (error) {
        let err = error as BusinessError
        console.error(`Failed to create the PreviewOutput instance. error code: ${err.code}`)
        return {
          success: false,
          error: '创建预览输出失败'
        }
      }
      if (previewOutput === undefined) {
        return {
          success: false,
          error: '预览输出创建失败'
        }
      }

      // 监听预览输出错误信息
      previewOutput.on('error', (error: BusinessError) => {
        console.error(`Preview output error code: ${error.code}`)
      })

      // 创建拍照输出流
      let photoOutput: camera.PhotoOutput | undefined = undefined
      try {
        photoOutput = ImageUtils.cameraManager!.createPhotoOutput(photoProfilesArray[0])
      } catch (error) {
        let err = error as BusinessError
        console.error('Failed to createPhotoOutput errorCode = ' + err.code)
        return {
          success: false,
          error: '创建拍照输出失败'
        }
      }
      if (photoOutput === undefined) {
        return {
          success: false,
          error: '拍照输出创建失败'
        }
      }

      // 调用回调函数来保存图片
      ImageUtils.setPhotoOutputCb(photoOutput)

      // 创建会话
      let photoSession: camera.PhotoSession | undefined = undefined
      try {
        photoSession = ImageUtils.cameraManager!.createSession(camera.SceneMode.NORMAL_PHOTO) as camera.PhotoSession
      } catch (error) {
        let err = error as BusinessError
        console.error('Failed to create the session instance. errorCode = ' + err.code)
        return {
          success: false,
          error: '创建拍照会话失败'
        }
      }
      if (photoSession === undefined) {
        return {
          success: false,
          error: '拍照会话创建失败'
        }
      }

      // 监听session错误信息
      photoSession.on('error', (error: BusinessError) => {
        console.error(`Capture session error code: ${error.code}`)
      })

      // 开始配置会话
      try {
        photoSession.beginConfig()
      } catch (error) {
        let err = error as BusinessError
        console.error('Failed to beginConfig. errorCode = ' + err.code)
        return {
          success: false,
          error: '开始配置会话失败'
        }
      }

      // 向会话中添加相机输入流
      try {
        photoSession.addInput(cameraInput)
      } catch (error) {
        let err = error as BusinessError
        console.error('Failed to addInput. errorCode = ' + err.code)
        return {
          success: false,
          error: '添加相机输入失败'
        }
      }

      // 向会话中添加预览输出流
      try {
        photoSession.addOutput(previewOutput)
      } catch (error) {
        let err = error as BusinessError
        console.error('Failed to addOutput(previewOutput). errorCode = ' + err.code)
        return {
          success: false,
          error: '添加预览输出失败'
        }
      }

      // 向会话中添加拍照输出流
      try {
        photoSession.addOutput(photoOutput)
      } catch (error) {
        let err = error as BusinessError
        console.error('Failed to addOutput(photoOutput). errorCode = ' + err.code)
        return {
          success: false,
          error: '添加拍照输出失败'
        }
      }

      // 提交会话配置
      await photoSession.commitConfig()

      // 启动会话
      await photoSession.start().then(() => {
        console.info('Promise returned to indicate the session start success.')
      })

      // 判断设备是否支持闪光灯
      let flashStatus: boolean = false
      try {
        flashStatus = photoSession.hasFlash()
      } catch (error) {
        let err = error as BusinessError
        console.error('Failed to hasFlash. errorCode = ' + err.code)
      }
      console.info('Returned with the flash light support status:' + flashStatus)

      if (flashStatus) {
        // 判断是否支持自动闪光灯模式
        let flashModeStatus: boolean = false
        try {
          let status: boolean = photoSession.isFlashModeSupported(camera.FlashMode.FLASH_MODE_AUTO)
          flashModeStatus = status
        } catch (error) {
          let err = error as BusinessError
          console.error('Failed to check whether the flash mode is supported. errorCode = ' + err.code)
        }
        if (flashModeStatus) {
          // 设置自动闪光灯模式
          try {
            photoSession.setFlashMode(camera.FlashMode.FLASH_MODE_AUTO)
          } catch (error) {
            let err = error as BusinessError
            console.error('Failed to set the flash mode. errorCode = ' + err.code)
          }
        }
      }

      // 判断是否支持连续自动变焦模式
      let focusModeStatus: boolean = false
      try {
        let status: boolean = photoSession.isFocusModeSupported(camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO)
        focusModeStatus = status
      } catch (error) {
        let err = error as BusinessError
        console.error('Failed to check whether the focus mode is supported. errorCode = ' + err.code)
      }

      if (focusModeStatus) {
        // 设置连续自动变焦模式
        try {
          photoSession.setFocusMode(camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO)
        } catch (error) {
          let err = error as BusinessError
          console.error('Failed to set the focus mode. errorCode = ' + err.code)
        }
      }

      // 获取相机支持的可变焦距比范围
      let zoomRatioRange: Array<number> = []
      try {
        zoomRatioRange = photoSession.getZoomRatioRange()
      } catch (error) {
        let err = error as BusinessError
        console.error('Failed to get the zoom ratio range. errorCode = ' + err.code)
      }
      if (zoomRatioRange.length <= 0) {
        return {
          success: false,
          error: '获取变焦范围失败'
        }
      }

      // 设置可变焦距比
      try {
        photoSession.setZoomRatio(zoomRatioRange[0])
      } catch (error) {
        let err = error as BusinessError
        console.error('Failed to set the zoom ratio value. errorCode = ' + err.code)
      }

      let photoCaptureSetting: camera.PhotoCaptureSetting = {
        quality: camera.QualityLevel.QUALITY_LEVEL_HIGH, // 设置图片质量高
        rotation: camera.ImageRotation.ROTATION_0 // 设置图片旋转角度0
      }

      // 使用当前拍照设置进行拍照
      return new Promise<ImageSelectionResult>((resolve) => {
        photoOutput!.capture(photoCaptureSetting, (err: BusinessError) => {
          if (err) {
            console.error(`Failed to capture the photo ${err.message}`)
            resolve({
              success: false,
              error: '拍照失败'
            })
            return
          }
          console.info('Callback invoked to indicate the photo capture request success.')
          
          // 拍照成功后，延迟一段时间再关闭相机，确保拍照完成
          setTimeout(async () => {
            try {
              // 停止当前会话
              await photoSession!.stop()

              // 释放相机输入流
              await cameraInput!.close()

              // 释放预览输出流
              await previewOutput!.release()

              // 释放拍照输出流
              await photoOutput!.release()

              // 释放会话
              await photoSession!.release()

              resolve({
                success: true,
                imagePath: '拍照成功',
                imageBase64: ''
              })
            } catch (error) {
              console.error('关闭相机失败:', error)
              resolve({
                success: false,
                error: '关闭相机失败'
              })
            }
          }, 1000)
        })
      })

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
    if (ImageUtils.photoSession) {
      ImageUtils.photoSession = null
    }
    if (ImageUtils.cameraInput) {
      ImageUtils.cameraInput = null
    }
    if (ImageUtils.previewOutput) {
      ImageUtils.previewOutput = null
    }
    if (ImageUtils.photoOutput) {
      ImageUtils.photoOutput = null
    }
  }
}
