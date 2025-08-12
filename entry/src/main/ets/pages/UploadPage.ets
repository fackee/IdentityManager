import { DocumentItem } from '../model/DocumentItem'
import { DocumentType } from '../model/DocumentType'
import { ImageUtils } from '../utils/ImageUtils'
import { DocumentRecognitionService } from '../services/DocumentRecognitionService'
import { LocalDatabaseManager } from '../manager/LocalDatabaseManager'
import { RecognitionResponse, RecognitionField, UploadPageParams,
  ImageSelectionResult } from '../types/DocumentRecognition'
import { PermissionUtils } from '../utils/PermissionUtils'
import image from '@kit.ImageKit'
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

@Entry
@Component
struct UploadPage {
  @State currentStep: number = 0
  @State selectedImage: Resource | null = null
  @State imagePath: string = ''
  @State imageBase64: string = ''
  @State isProcessing: boolean = false
  @State recognitionResult: RecognitionResponse | null = null
  @State dynamicFields: Map<string, string> = new Map()
  @State documentType: string = ''
  @State confidence: number = 0

  // 相册选择相关状态
  @State showPhotoPicker: boolean = false
  @State pickerOptions: PickerOptions = new PickerOptions()
  @State pickerController: PickerController = new PickerController()
  @State selectedUris: Array<string> = new Array<string>()
  @State currentUri: string = ''
  @State isBrowserShow: boolean = false

  private databaseManager: LocalDatabaseManager = LocalDatabaseManager.getInstance()

  // 获取Context的辅助方法
  private getContext(): Context | undefined {
    let uiContext: UIContext = this.getUIContext();
    let context: Context | undefined = uiContext.getHostContext();
    return context;
  }

  aboutToAppear() {
    // 初始化数据库
    this.databaseManager.initialize(getContext())
    
    // 初始化相册选择器
    this.initializePhotoPicker()
    
    // 检查是否有传入的参数
    const params = this.getUIContext().getRouter().getParams() as UploadPageParams
    if (params?.mode) {
      this.selectUploadMethod(params.mode)
    }
  }

  // 初始化相册选择器
  private initializePhotoPicker(): void {
    // 设置picker宫格页数据类型
    this.pickerOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_VIDEO_TYPE // 图片和照片都显示。
    // 最大选择数量。
    this.pickerOptions.maxSelectNumber = 1;
    // 超出最大选择数量时。
    this.pickerOptions.maxSelectedReminderMode = ReminderMode.TOAST;
    // 是否展示搜索框，默认false。
    this.pickerOptions.isSearchSupported = true;
    // 是否支持拍照，默认false。
    this.pickerOptions.isPhotoTakingSupported = true;
  }

  // 资源被选中回调，返回资源的信息，以及选中方式。
  private onItemClicked(itemInfo: ItemInfo, clickType: ClickType): boolean {
    if (!itemInfo) {
      return false;
    }
    let type: ItemType | undefined = itemInfo.itemType;
    let uri: string | undefined = itemInfo.uri;
    if (type === ItemType.CAMERA) {
      // 点击相机item。
      return true; // 返回true则拉起系统相机，若应用需要自行处理则返回false。
    } else {
      if (clickType === ClickType.SELECTED) {
        // 应用做自己的业务处理。
        if (uri) {
          this.selectedUris.push(uri);
          this.pickerOptions.preselectedUris = [...this.selectedUris];
        }
        return true; // 返回true则勾选，否则则不响应勾选。
      } else {
        if (uri) {
          this.selectedUris = this.selectedUris.filter((item: string) => {
            return item != uri;
          });
          this.pickerOptions.preselectedUris = [...this.selectedUris];
        }
      }
      return true;
    }
  }

  // 进入大图的回调。
  private onEnterPhotoBrowser(photoBrowserInfo: PhotoBrowserInfo): boolean {
    this.isBrowserShow = true;
    return true;
  }

  // 退出大图的回调。
  private onExitPhotoBrowser(photoBrowserInfo: PhotoBrowserInfo): boolean {
    this.isBrowserShow = false;
    return true;
  }

  // 接收到该回调后，便可通过pickerController相关接口向picker发送数据，在此之前不生效。
  private onPickerControllerReady(): void {
  }

  // 大图左右滑动的回调。
  private onPhotoBrowserChanged(browserItemInfo: BaseItemInfo): boolean {
    this.currentUri = browserItemInfo.uri ?? '';
    return true;
  }

  // 已勾选图片被删除时的回调。
  private onSelectedItemsDeleted(baseItemInfos: Array<BaseItemInfo>): void {
  }

  // 超过最大选择数量再次点击时的回调。
  private onExceedMaxSelected(exceedMaxCountType: MaxCountType): void {
  }

  // 当前相册被删除时的回调。
  private onCurrentAlbumDeleted(): void {
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button('返回')
          .onClick(() => {
            this.goBack()
          })
        
        Text('添加证件')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })

      // 步骤指示器
      Row() {
        ForEach([1, 2, 3, 4], (step: number) => {
          Text(step.toString())
            .fontSize(14)
            .fontColor(this.currentStep >= step ? Color.White : '#666666')
            .backgroundColor(this.currentStep >= step ? '#007DFF' : '#F0F0F0')
            .width(24)
            .height(24)
            .borderRadius(12)
            .textAlign(TextAlign.Center)
            .margin({ right: 8 })
        })
      }
      .justifyContent(FlexAlign.Center)
      .margin({ top: 20, bottom: 30 })

      // 内容区域
      if (this.currentStep === 0) {
        this.UploadMethodSelection()
      } else if (this.currentStep === 1) {
        this.ImageCapture()
      } else if (this.currentStep === 2) {
        this.ImagePreview()
      } else if (this.currentStep === 3) {
        this.RecognitionResult()
      }

      // 相册选择组件
      if (this.showPhotoPicker) {
        Stack() {
          // 半透明背景
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#00000080')
            .onClick(() => {
              this.showPhotoPicker = false
            })

          // 相册选择器
          Column() {
            // 顶部工具栏
            Row() {
              Button('取消')
                .onClick(() => {
                  this.showPhotoPicker = false
                })
              
              Text('选择图片')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .margin({ left: 16 })

              Blank()

              Button('确定')
                .backgroundColor('#007DFF')
                .fontColor(Color.White)
                .onClick(() => {
                  this.confirmPhotoSelection()
                })
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 12, bottom: 12 })

            // 相册选择组件
            PhotoPickerComponent({
              pickerOptions: this.pickerOptions,
              onItemClicked: (itemInfo: ItemInfo, clickType: ClickType): boolean => this.onItemClicked(itemInfo, clickType),
              onEnterPhotoBrowser: (photoBrowserInfo: PhotoBrowserInfo): boolean => this.onEnterPhotoBrowser(photoBrowserInfo),
              onExitPhotoBrowser: (photoBrowserInfo: PhotoBrowserInfo): boolean => this.onExitPhotoBrowser(photoBrowserInfo),
              onPickerControllerReady: (): void => this.onPickerControllerReady(),
              onPhotoBrowserChanged: (browserItemInfo: BaseItemInfo): boolean => this.onPhotoBrowserChanged(browserItemInfo),
              onSelectedItemsDeleted: (BaseItemInfo: Array<BaseItemInfo>) => this.onSelectedItemsDeleted(BaseItemInfo),
              onExceedMaxSelected: (exceedMaxCountType: MaxCountType) => this.onExceedMaxSelected(exceedMaxCountType),
              onCurrentAlbumDeleted: () => this.onCurrentAlbumDeleted(),
              pickerController: this.pickerController,
            })
            .width('100%')
            .height('80%')

            // 底部选择栏
            if (this.isBrowserShow) {
              // 已选择的图片缩略图。
              Row() {
                ForEach(this.selectedUris, (uri: string) => {
                  if (uri === this.currentUri) {
                    Image(uri).height(50).width(50)
                      .onClick(() => {
                      })
                      .borderWidth(1)
                      .borderColor('red')
                  } else {
                    Image(uri).height(50).width(50).onClick(() => {
                      this.pickerController.setData(DataType.SET_SELECTED_URIS, this.selectedUris);
                      this.pickerController.setPhotoBrowserItem(uri, PhotoBrowserRange.ALL);
                    })
                  }
                }, (uri: string) => JSON.stringify(uri))
              }.alignSelf(ItemAlign.Center).margin(this.selectedUris.length ? 10 : 0)
            } else {
              // 进入大图，预览已选择的图片。
              Button('预览').width('33%').alignSelf(ItemAlign.Start).height('5%').margin(10).onClick(() => {
                if (this.selectedUris.length > 0) {
                  this.pickerController.setPhotoBrowserItem(this.selectedUris[0], PhotoBrowserRange.SELECTED_ONLY);
                }
              })
            }
          }
          .width('100%')
          .height('100%')
          .backgroundColor(Color.White)
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
        .zIndex(1000)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }

  @Builder
  UploadMethodSelection() {
    Column() {
      Text('选择上传方式')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 40 })

      Button('拍照上传')
        .width('80%')
        .height(56)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .margin({ bottom: 20 })
        .onClick(() => {
          this.selectUploadMethod('camera')
        })

      Button('从相册选择')
        .width('80%')
        .height(56)
        .backgroundColor(Color.White)
        .fontColor('#007DFF')
        .border({ width: 2, color: '#007DFF' })
        .onClick(async () => {
          // 检查存储权限
          const hasPermission = await PermissionUtils.requestStoragePermission()
          if (!hasPermission) {
            this.getUIContext().showAlertDialog({
              title: '权限错误',
              message: '没有存储权限，无法访问相册',
              primaryButton: {
                value: '确定',
                action: () => {
                  console.log('用户确认权限错误')
                }
              }
            })
            return
          }
          
          // 显示相册选择器
          this.showPhotoPicker = true
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ImageCapture() {
    Column() {
      Text('拍摄证件照片')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      if (this.imagePath) {
        Image(this.imagePath)
          .width('80%')
          .height(300)
          .borderRadius(12)
          .objectFit(ImageFit.Cover)
          .margin({ bottom: 40 })
      } else {
        Image($r('app.media.background'))
          .width('80%')
          .height(300)
          .borderRadius(12)
          .margin({ bottom: 40 })
      }

      Row() {
        Button('重新拍摄')
          .width(120)
          .height(48)
          .backgroundColor('#F0F0F0')
          .fontColor('#666666')
          .margin({ right: 20 })
          .onClick(() => {
            this.currentStep = 0
          })

        Button('下一步')
          .width(120)
          .height(48)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .onClick(() => {
            this.currentStep = 2
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ImagePreview() {
    Column() {
      Text('预览')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      if (this.imagePath) {
        Image(this.imagePath)
          .width('90%')
          .height(400)
          .borderRadius(12)
          .objectFit(ImageFit.Cover)
          .margin({ bottom: 30 })
      } else {
        Image($r('app.media.background'))
          .width('90%')
          .height(400)
          .borderRadius(12)
          .margin({ bottom: 30 })
      }

      Row() {
        Button('重新选择')
          .width(120)
          .height(48)
          .backgroundColor('#F0F0F0')
          .fontColor('#666666')
          .margin({ right: 20 })
          .onClick(() => {
            this.currentStep = 0
          })

        Button('开始识别')
          .width(120)
          .height(48)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .onClick(() => {
            this.startRecognition()
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  RecognitionResult() {
    Column() {
      Text('识别结果')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 30 })

      if (this.isProcessing) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .margin({ bottom: 16 })
          Text('正在识别中...')
            .fontSize(16)
            .fontColor('#666666')
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      } else if (this.recognitionResult && this.recognitionResult.success) {
        Column() {
          // 文档类型和置信度
          Row() {
            Text(`文档类型: ${this.documentType}`)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Blank()
            Text(`置信度: ${(this.confidence * 100).toFixed(1)}%`)
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
          .margin({ bottom: 20 })

          // 动态表单字段
          Column() {
            ForEach(Array.from(this.dynamicFields.entries()), (entry: [string, string]) => {
              this.DynamicField(entry[0], entry[1])
            })
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(12)
          .padding(20)
          .margin({ bottom: 30 })

          Row() {
            Button('重新识别')
              .width(120)
              .height(48)
              .backgroundColor('#F0F0F0')
              .fontColor('#666666')
              .margin({ right: 20 })
              .onClick(() => {
                this.currentStep = 2
              })

            Button('保存')
              .width(120)
              .height(48)
              .backgroundColor('#007DFF')
              .fontColor(Color.White)
              .onClick(() => {
                this.saveDocument()
              })
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      } else {
        Column() {
          Text('识别失败')
            .fontSize(18)
            .fontColor('#FF4444')
            .margin({ bottom: 16 })
          
          if (this.recognitionResult?.error) {
            Text(this.recognitionResult.error)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 30 })
          }

          Row() {
            Button('重新识别')
              .width(120)
              .height(48)
              .backgroundColor('#F0F0F0')
              .fontColor('#666666')
              .margin({ right: 20 })
              .onClick(() => {
                this.currentStep = 2
              })

            Button('返回')
              .width(120)
              .height(48)
              .backgroundColor('#007DFF')
              .fontColor(Color.White)
              .onClick(() => {
                this.currentStep = 0
              })
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ left: 20, right: 20 })
  }

  @Builder
  DynamicField(key: string, value: string) {
    Row() {
      Text(key)
        .fontSize(16)
        .fontColor('#666666')
        .width('30%')
      
      TextInput({ text: value })
        .width('70%')
        .height(40)
        .backgroundColor('#F8F9FA')
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .onChange((newValue: string) => {
          this.dynamicFields.set(key, newValue)
        })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  private async selectUploadMethod(method: string) {
    console.log('选择上传方式:', method)
    
    try {
      if (method === 'camera') {
        // 使用新的cameraPicker API进行拍照
        const context = this.getContext();
        if (!context) {
          this.getUIContext().showAlertDialog({
            title: '错误',
            message: '无法获取应用上下文',
            primaryButton: {
              value: '确定',
              action: () => {
                console.log('用户确认错误')
              }
            }
          })
          return;
        }
        
        const result = await ImageUtils.takePhoto(context)
        if (result?.success && result.imagePath) {
          this.imagePath = result.imagePath
          this.imageBase64 = result.imageBase64 || ''
          this.currentStep = 1
        } else {
          // 显示错误信息
          this.getUIContext().showAlertDialog({
            title: '错误',
            message: result?.error || '获取图片失败',
            primaryButton: {
              value: '确定',
              action: () => {
                console.log('用户确认错误')
              }
            }
          })
        }
      } else if (method === 'gallery') {
        // 检查存储权限
        const hasPermission = await PermissionUtils.requestStoragePermission()
        if (!hasPermission) {
          this.getUIContext().showAlertDialog({
            title: '权限错误',
            message: '没有存储权限，无法访问相册',
            primaryButton: {
              value: '确定',
              action: () => {
                console.log('用户确认权限错误')
              }
            }
          })
          return
        }
        
        // 显示相册选择器
        this.showPhotoPicker = true
      } else {
        // 显示错误信息
        this.getUIContext().showAlertDialog({
          title: '错误',
          message: '不支持的上传方式',
          primaryButton: {
            value: '确定',
            action: () => {
              console.log('用户确认错误')
            }
          }
        })
      }
    } catch (error) {
      console.error('选择上传方式失败:', error)
      this.getUIContext().showAlertDialog({
        title: '错误',
        message: '获取图片失败',
        primaryButton: {
          value: '确定',
          action: () => {
            console.log('用户确认错误')
          }
        }
      })
    }
  }

  private async startRecognition() {
    if (!this.imagePath && !this.imageBase64) {
      this.getUIContext().showAlertDialog({
        title: '错误',
        message: '没有可识别的图片',
        primaryButton: {
          value: '确定',
          action: () => {
            console.log('用户确认错误')
          }
        }
      })
      return
    }

    this.currentStep = 3
    this.isProcessing = true

    try {
      let imageData = this.imageBase64
      
      // 如果是从相册选择的图片（有imagePath但没有imageBase64），需要将图片转换为base64
      if (this.imagePath && !this.imageBase64) {
        try {
          imageData = await ImageUtils.convertImageUriToBase64(this.imagePath)
        } catch (error) {
          console.error('图片转换失败:', error)
          this.getUIContext().showAlertDialog({
            title: '错误',
            message: '图片转换失败',
            primaryButton: {
              value: '确定',
              action: () => {
                console.log('用户确认错误')
              }
            }
          })
          this.isProcessing = false
          return
        }
      }

      // 调用识别服务
      const result = await DocumentRecognitionService.recognizeDocument(imageData)
      
      this.recognitionResult = result
      this.isProcessing = false

      if (result.success) {
        this.documentType = result.documentType
        this.confidence = result.confidence
        
        // 初始化动态字段
        this.dynamicFields.clear()
        result.fields.forEach(field => {
          this.dynamicFields.set(field.label, field.value)
        })
      }
    } catch (error) {
      console.error('识别失败:', error)
      this.isProcessing = false
      this.recognitionResult = {
        success: false,
        documentType: '',
        confidence: 0,
        fields: [],
        error: '识别失败'
      }
    }
  }

  private async saveDocument() {
    try {
             // 创建文档对象
       const document = new DocumentItem(
         '', // ID将由数据库管理器生成
         this.documentType, // 使用识别出的文档类型作为名称
         this.documentType,
         this.dynamicFields.get('证件号码') || this.dynamicFields.get('护照号码') || this.dynamicFields.get('驾驶证号码') || '',
         this.dynamicFields.get('有效期限') || this.dynamicFields.get('有效期至') || '',
         this.imagePath, // imageUrl
         new Date(), // createTime
         new Date(), // updateTime
         this.dynamicFields, // dynamicFields
         this.confidence, // recognitionConfidence
         this.imagePath // originalImagePath
       )

      // 保存到数据库
      const success = await this.databaseManager.addDocument(document)
      
      if (success) {
        this.getUIContext().showAlertDialog({
          title: '成功',
          message: '文档保存成功',
          primaryButton: {
            value: '确定',
            action: () => {
              this.goBack()
            }
          }
        })
      } else {
        this.getUIContext().showAlertDialog({
          title: '错误',
          message: '保存失败',
          primaryButton: {
            value: '确定',
            action: () => {
              console.log('用户确认错误')
            }
          }
        })
      }
    } catch (error) {
      console.error('保存文档失败:', error)
      this.getUIContext().showAlertDialog({
        title: '错误',
        message: '保存失败',
        primaryButton: {
          value: '确定',
          action: () => {
            console.log('用户确认错误')
          }
        }
      })
    }
  }

  private confirmPhotoSelection() {
    if (this.selectedUris.length > 0) {
      this.imagePath = this.selectedUris[0];
      this.imageBase64 = ''; // 清空base64，因为图片已经加载到imagePath
      this.currentStep = 1;
      this.showPhotoPicker = false;
      this.selectedUris = []; // 清空已选择的图片
      this.pickerOptions.preselectedUris = []; // 清空预选的图片
    } else {
      this.showPhotoPicker = false;
    }
  }

  private goBack() {
    this.getUIContext().getRouter().back()
  }
} 