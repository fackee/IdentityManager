import { abilityAccessCtrl, Context, PermissionRequestResult, common, Permissions } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

export class PermissionUtils {
  private static context: common.UIAbilityContext | null = null
  private static atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager()

  /**
   * 设置上下文
   * @param context 应用上下文
   */
  static setContext(context: common.UIAbilityContext) {
    PermissionUtils.context = context
  }

  /**
   * 申请相机权限
   * @returns Promise<boolean> 是否获得权限
   */
  static requestCameraPermission(): Promise<boolean> {
    return new Promise((resolve) => {
      if (!PermissionUtils.context) {
        console.error('Context not set')
        resolve(false)
        return
      }

      const permissions: Array<Permissions> = ['ohos.permission.CAMERA' as Permissions]
      PermissionUtils.atManager.requestPermissionsFromUser(
        PermissionUtils.context,
        permissions,
        (err: BusinessError, data: PermissionRequestResult) => {
          if (err) {
            console.error(`Request camera permission failed: ${JSON.stringify(err)}`)
            resolve(false)
          } else {
            console.log(`Request camera permission success: ${JSON.stringify(data)}`)
            resolve(data.authResults[0] === 0)
          }
        }
      )
    })
  }

  /**
   * 申请存储权限
   * @returns Promise<boolean> 是否获得权限
   */
  static requestStoragePermission(): Promise<boolean> {
    return new Promise((resolve) => {
      if (!PermissionUtils.context) {
        console.error('Context not set')
        resolve(false)
        return
      }

      const permissions: Array<Permissions> = [
        'ohos.permission.READ_MEDIA' as Permissions,
        'ohos.permission.WRITE_MEDIA' as Permissions
      ]
      PermissionUtils.atManager.requestPermissionsFromUser(
        PermissionUtils.context,
        permissions,
        (err: BusinessError, data: PermissionRequestResult) => {
          if (err) {
            console.error(`Request storage permission failed: ${JSON.stringify(err)}`)
            resolve(false)
          } else {
            console.log(`Request storage permission success: ${JSON.stringify(data)}`)
            resolve(data.authResults.every(authResult => authResult === 0))
          }
        }
      )
    })
  }

  /**
   * 申请蓝牙权限
   * @returns Promise<boolean> 是否获得权限
   */
  static requestBluetoothPermission(): Promise<boolean> {
    return new Promise((resolve) => {
      if (!PermissionUtils.context) {
        console.error('Context not set')
        resolve(false)
        return
      }

      const permissions: Array<Permissions> = [
        'ohos.permission.ACCESS_BLUETOOTH' as Permissions
      ]
      PermissionUtils.atManager.requestPermissionsFromUser(
        PermissionUtils.context,
        permissions,
        (err: BusinessError, data: PermissionRequestResult) => {
          if (err) {
            console.error(`Request bluetooth permission failed: ${JSON.stringify(err)}`)
            resolve(false)
          } else {
            console.log(`Request bluetooth permission success: ${JSON.stringify(data)}`)
            resolve(data.authResults.every(authResult => authResult === 0))
          }
        }
      )
    })
  }

  /**
   * 申请网络权限
   * @returns Promise<boolean> 是否获得权限
   */
  static requestNetworkPermission(): Promise<boolean> {
    return new Promise((resolve) => {
      if (!PermissionUtils.context) {
        console.error('Context not set')
        resolve(false)
        return
      }

      const permissions: Array<Permissions> = [
        'ohos.permission.INTERNET' as Permissions,
        'ohos.permission.ACCESS_NETWORK_STATE' as Permissions
      ]
      PermissionUtils.atManager.requestPermissionsFromUser(
        PermissionUtils.context,
        permissions,
        (err: BusinessError, data: PermissionRequestResult) => {
          if (err) {
            console.error(`Request network permission failed: ${JSON.stringify(err)}`)
            resolve(false)
          } else {
            console.log(`Request network permission success: ${JSON.stringify(data)}`)
            resolve(data.authResults.every(authResult => authResult === 0))
          }
        }
      )
    })
  }

  /**
   * 检查权限状态
   * @param permission 权限名称
   * @returns Promise<boolean> 是否有权限
   */
  static checkPermission(permission: Permissions): Promise<boolean> {
    return new Promise(async (resolve) => {
      if (!PermissionUtils.context) {
        console.error('Context not set')
        resolve(false)
        return
      }

      try {
        // 获取应用的tokenID
        const tokenID = PermissionUtils.context.applicationInfo.accessTokenId
        const result = await PermissionUtils.atManager.verifyAccessToken(tokenID, permission)
        resolve(result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)
      } catch (error) {
        console.error('Check permission failed:', error)
        resolve(false)
      }
    })
  }

  /**
   * 申请所有必要权限
   * @returns Promise<boolean> 是否获得所有权限
   */
  static requestAllPermissions(): Promise<boolean> {
    return new Promise(async (resolve) => {
      const cameraPermission = await PermissionUtils.requestCameraPermission()
      const storagePermission = await PermissionUtils.requestStoragePermission()
      const bluetoothPermission = await PermissionUtils.requestBluetoothPermission()
      const networkPermission = await PermissionUtils.requestNetworkPermission()

      resolve(cameraPermission && storagePermission && bluetoothPermission && networkPermission)
    })
  }

  /**
   * 显示权限说明对话框
   * @param permissionName 权限名称
   * @param description 权限说明
   */
  static showPermissionDialog(permissionName: string, description: string) {
    AlertDialog.show({
      title: `需要${permissionName}权限`,
      message: description,
      primaryButton: {
        value: '去设置',
        action: () => {
          // 跳转到应用设置页面
          console.log('跳转到应用设置页面')
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {
          console.log('用户取消权限申请')
        }
      }
    })
  }
} 