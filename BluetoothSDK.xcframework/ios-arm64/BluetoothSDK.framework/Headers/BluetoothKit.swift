//
//  BluetoothKit.swift
//  BluetoothSDK
//
//  Created by Steven Zhou on 2022/5/9
//  Copyright © 2022 Stationdm. All rights reserved.
//      


@objc public class BluetoothKit: NSObject {
    
    /// SDK initialize
    /// - Parameter configuration: SDK configuration
    /// - Returns: Initialization results
    public static func initSDK(with configuration: BluetoothConfiguration = BluetoothConfiguration()) -> Result<Void, BluetoothError> {
        BLECentralManager.shared.configuration = configuration
        return BLECentralManager.shared.checkEnviornment()
    }
    
    /// User-initiated scan
    /// - Parameters:
    ///   - model: scan model
    ///   - delegate: scan status delegate
    public static func startActiveScan(with model: BLEScanModel, delegate: BluetoothDelegate) {
        BLECentralManager.shared.startScan(with: model, delegate: delegate)
    }
    
    /// User cancel scanning
    /// - Parameter delegate: scan status delegate
    public static func stopActiveScan(delegate: BluetoothDelegate? = nil) {
        BLECentralManager.shared.stopScan(delegate: delegate)
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
}
