//
//  BluetoothKit.swift
//  BluetoothSDK
//
//  Created by Steven Zhou on 2022/5/9
//  Copyright © 2022 Stationdm. All rights reserved.
//      

import CoreBluetooth


@objc public class BluetoothKit: NSObject {
    public typealias BluetoothCentralManagerStateCallback = (_ state: Result<Void, BluetoothError>) -> Void
    /// SDK initialize
    /// - Parameter configuration: SDK configuration
    /// - scanModel: ScanModel
    /// - Returns: Initialization results
    public static func initSDK(with configuration: BluetoothConfiguration = BluetoothConfiguration(), scanModel: BLEScanModel, centralStateCallback: @escaping BluetoothCentralManagerStateCallback) {
        let manager = BLECentralManager.shared
        manager.configuration = configuration
        manager.centralStateCallback = centralStateCallback
        manager.scanModel = scanModel
        manager.setup()
    }
    
    /// User-initiated scan
    /// - Parameters:
    ///   - delegate: scan status delegate
    public static func startActiveScan(delegate: BluetoothDelegate) {
        BLECentralManager.shared.startActiveScan(delegate: delegate)
    }
    
    /// User cancel scanning
    /// - Parameter delegate: scan status delegate
    public static func stopActiveScan(delegate: BluetoothDelegate? = nil) {
        BLECentralManager.shared.stopScan(delegate: delegate)
    }
    
    public static func clearAllScannedPeripherals() {
        BLECentralManager.shared.removeScannedPeripherals()
    }
    
    /// Connecting scanned peripherals
    /// - Parameter discovery: scanned bluetooth object
    /// - Returns: the connecting bluetooth GATT
    public static func connectBluetoothDiscovery<T: BluetoothGATT>(_ discovery: BluetoothDiscovery) -> T {
        return BLECentralManager.shared.connectBluetoothDiscovery(discovery)
    }
    
    /// Connect GATT via deviceId
    /// - Parameter deviceId: the unique identification of device peripherals
    /// - Returns: the connecting bluetooth GATT
    public static func connectGatt<T: BluetoothGATT>(with deviceId: String) -> T {
        return BLECentralManager.shared.connectGatt(deviceId: deviceId)
    }
    
    public static func connectGatt<T: BluetoothGATT>(with peripheral: CBPeripheral) -> T {
        return BLECentralManager.shared.connectGatt(peripheral: peripheral)
    }
    
    /// Disconnect GATT
    /// - Parameter gatt: the GATT target
    public static func disconnectDevice(_ gatt: BluetoothGATT) {
        BLECentralManager.shared.disconnectDevice(gatt)
    }
    
    /// Reconnect GATT
    /// - Parameter gatt: the GATT target
    public static func reconnectDevice(_ gatt: BluetoothGATT) {
        BLECentralManager.shared.reconnectGatt(gatt)
    }
    
    public static var isScanning: Bool {
        return BLECentralManager.shared.isScanning
    }
    
    public static func logFileURLList() -> [URL] {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            return []
        }
        
        let logDir = documentsURL.appendingPathComponent("bluetooth")
        guard let fileUrls = try? FileManager.default.contentsOfDirectory(atPath: logDir.path) else {
            return []
        }
        let urlList = fileUrls.map { filePath -> URL in
            let fullPath = logDir.appendingPathComponent(filePath)
            return fullPath
        }
        return urlList
    }
}
