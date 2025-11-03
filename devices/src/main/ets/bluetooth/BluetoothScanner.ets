import { connection } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export abstract class BluetoothScanCallback{
  /**
   * 返回deviceName,mac
   * */
  public abstract onScanning :(devices: Array<[string, string]>) => void
}

export class BluetoothScanner {
  private static callBack:BluetoothScanCallback;

  // 定义扫描结果上报回调函数
  onReceiveEvent = (data: Array<string>) => {
    console.info('bluetooth device: '+ JSON.stringify(data));
    let devices = new Array<[string, string]>();
    for (let index = 0; index < data.length; index++) {
      const mac = data[index];
      const deviceName = connection.getRemoteDeviceName(mac);
      console.info("bluetooth scanning:name" + deviceName+ ",mac"+ mac)
      devices.push([deviceName,mac])
    }
    BluetoothScanner.callBack.onScanning(devices);
  };

  /**
   * API version 17及以前的扫描结果上报方式只支持获取设备地址信息，需要connection.getRemoteDeviceName再次获取设备名称
   * */
  public startDiscovery(callBack:BluetoothScanCallback) {
    try {
      BluetoothScanner.callBack = callBack;
      connection.on('bluetoothDeviceFind', this.onReceiveEvent);
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
    try {
      // 判断本机设备是否正在进行扫描
      let scan = connection.isBluetoothDiscovering();
      if (!scan) {
        // 若当前不处于扫描过程，则开始扫描设备
        connection.startBluetoothDiscovery();
      }
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public isBluetoothDiscovering():boolean {
    return connection.isBluetoothDiscovering();
  }

  public stopDiscovery() {
    try {
      // 判断本机设备是否正在进行扫描
      let scan = connection.isBluetoothDiscovering();
      if (scan) {
        // 若当前处于扫描过程，则停止扫描设备
        connection.stopBluetoothDiscovery();
      }
      // 若不再需要使用扫描，可以取消订阅扫描上报结果
      connection.off('bluetoothDeviceFind', this.onReceiveEvent);
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public setScanMode() {
    try {
      // 获取当前本机的扫描模式
      let scanMode: connection.ScanMode = connection.getBluetoothScanMode();
      console.info('scanMode: ' + scanMode);
      if (scanMode != connection.ScanMode.SCAN_MODE_CONNECTABLE_GENERAL_DISCOVERABLE) {
        // 将本机设备的扫描模式设为可被发现和可被连接
        connection.setBluetoothScanMode(connection.ScanMode.SCAN_MODE_CONNECTABLE_GENERAL_DISCOVERABLE, 0);
      }
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public getPairedDevices() {
    try {
      // 获取已配对设备信息
      let devices = connection.getPairedDevices();
      console.info('pairedDevices: ' + JSON.stringify(devices));
      // 若已知道设备地址，可主动查询该设备是否是已配对的
      if (devices.length > 0) {
        let pairState = connection.getPairState(devices[0]);
        console.info('device: '+ devices[0] + ' pairState is ' + pairState);
      }
    } catch (err) {
      console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }
}