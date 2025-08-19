import { BusinessError } from '@kit.BasicServicesKit'
import { connection, access } from '@kit.ConnectivityKit'

export class BluetoothPermissionUtils {
  private static stateChangeCallback?: (state: access.BluetoothState) => void

  // 蓝牙状态变化回调
  private static onReceiveEvent = (data: access.BluetoothState) => {
    let btStateMessage = '';
    switch (data) {
      case access.BluetoothState.STATE_OFF:
        btStateMessage = '蓝牙已关闭';
        break;
      case access.BluetoothState.STATE_TURNING_ON:
        btStateMessage = '蓝牙正在开启';
        break;
      case access.BluetoothState.STATE_ON:
        btStateMessage = '蓝牙已开启';
        break;
      case access.BluetoothState.STATE_TURNING_OFF:
        btStateMessage = '蓝牙正在关闭';
        break;
      case access.BluetoothState.STATE_BLE_TURNING_ON:
        btStateMessage = 'BLE正在开启';
        break;
      case access.BluetoothState.STATE_BLE_ON:
        btStateMessage = 'BLE已开启';
        break;
      case access.BluetoothState.STATE_BLE_TURNING_OFF:
        btStateMessage = 'BLE正在关闭';
        break;
      default:
        btStateMessage = '未知状态';
        break;
    }
    console.info('蓝牙状态变化: ' + btStateMessage);
    
    if (BluetoothPermissionUtils.stateChangeCallback) {
      BluetoothPermissionUtils.stateChangeCallback(data);
    }
  };

  // 检查蓝牙权限和状态
  public static async checkBluetoothPermissions(): Promise<boolean> {
    try {
      // 获取当前蓝牙状态
      const state = access.getState();
      console.info('当前蓝牙状态:', state);
      
      if (state === access.BluetoothState.STATE_OFF) {
        console.error('蓝牙未开启')
        return false
      }
      
      if (state === access.BluetoothState.STATE_TURNING_ON) {
        console.info('蓝牙正在开启中，请稍候')
        return false
      }
      
      if (state === access.BluetoothState.STATE_TURNING_OFF) {
        console.error('蓝牙正在关闭中')
        return false
      }

      return true
    } catch (err) {
      console.error('检查蓝牙权限失败:', (err as BusinessError).message)
      return false
    }
  }

  // 请求蓝牙权限
  public static async requestBluetoothPermissions(): Promise<boolean> {
    try {
      // 这里可以添加权限请求逻辑
      // 例如请求位置权限等
      
      return true
    } catch (err) {
      console.error('请求蓝牙权限失败:', (err as BusinessError).message)
      return false
    }
  }

  // 开启蓝牙
  public static async enableBluetooth(): Promise<boolean> {
    try {
      // 监听蓝牙状态变化
      access.on('stateChange', BluetoothPermissionUtils.onReceiveEvent);
      
      // 获取当前蓝牙状态
      const state = access.getState();
      console.info('当前蓝牙状态:', state);
      
      if (state === access.BluetoothState.STATE_OFF) {
        // 蓝牙关闭，尝试开启
        console.info('尝试开启蓝牙...')
        access.enableBluetooth();
        
        // 等待蓝牙开启
        return new Promise((resolve) => {
          const timeout = setTimeout(() => {
            access.off('stateChange', BluetoothPermissionUtils.onReceiveEvent);
            resolve(false);
          }, 10000); // 10秒超时
          
          BluetoothPermissionUtils.stateChangeCallback = (newState: access.BluetoothState) => {
            if (newState === access.BluetoothState.STATE_ON) {
              clearTimeout(timeout);
              access.off('stateChange', BluetoothPermissionUtils.onReceiveEvent);
              BluetoothPermissionUtils.stateChangeCallback = undefined;
              resolve(true);
            } else if (newState === access.BluetoothState.STATE_OFF) {
              clearTimeout(timeout);
              access.off('stateChange', BluetoothPermissionUtils.onReceiveEvent);
              BluetoothPermissionUtils.stateChangeCallback = undefined;
              resolve(false);
            }
          };
        });
      } else if (state === access.BluetoothState.STATE_ON) {
        // 蓝牙已经开启
        console.info('蓝牙已经开启')
        return true;
      } else if (state === access.BluetoothState.STATE_TURNING_ON) {
        // 蓝牙正在开启中
        console.info('蓝牙正在开启中，请稍候')
        return false;
      }
      
      return false;
    } catch (err) {
      console.error('开启蓝牙失败:', (err as BusinessError).message)
      return false
    }
  }

  // 关闭蓝牙
  public static async disableBluetooth(): Promise<boolean> {
    try {
      const state = access.getState();
      if (state === access.BluetoothState.STATE_ON) {
        access.disableBluetooth();
        return true;
      }
      return false;
    } catch (err) {
      console.error('关闭蓝牙失败:', (err as BusinessError).message)
      return false
    }
  }

  // 获取蓝牙状态
  public static getBluetoothState(): access.BluetoothState {
    try {
      return access.getState();
    } catch (err) {
      console.error('获取蓝牙状态失败:', (err as BusinessError).message)
      return access.BluetoothState.STATE_OFF;
    }
  }

  // 监听蓝牙状态变化
  public static onBluetoothStateChange(callback: (state: access.BluetoothState) => void): void {
    try {
      BluetoothPermissionUtils.stateChangeCallback = callback;
      access.on('stateChange', BluetoothPermissionUtils.onReceiveEvent);
    } catch (err) {
      console.error('监听蓝牙状态变化失败:', (err as BusinessError).message)
    }
  }

  // 取消监听蓝牙状态变化
  public static offBluetoothStateChange(): void {
    try {
      BluetoothPermissionUtils.stateChangeCallback = undefined;
      access.off('stateChange', BluetoothPermissionUtils.onReceiveEvent);
    } catch (err) {
      console.error('取消监听蓝牙状态变化失败:', (err as BusinessError).message)
    }
  }
}

export default BluetoothPermissionUtils
