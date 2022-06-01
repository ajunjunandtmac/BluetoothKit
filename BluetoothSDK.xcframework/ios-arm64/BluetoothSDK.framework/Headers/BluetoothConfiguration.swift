//
//  BluetoothConfiguration.swift
//  BluetoothSDK
//
//  Created by Steven Zhou on 2022/5/9
//  Copyright © 2022 Stationdm. All rights reserved.
//

import UIKit

@objc public class BluetoothConfiguration: NSObject {
    let defaultBluetoothUnavailableMessage: String = "Bluetooth unavailable"
    let defaultBluetoothPowerOffMessage: String = "Bluetooth is turned off"
    let defaultBluetoothUnauthorizedMessage: String = "Bluetooth permission is not authorized"
    let defaultBluetoothScanTimeoutMessage: String = "Scan timeout, please rescan"
    let bluetoothUnavailableMessage: String
    let bluetoothPowerOffMessage: String
    let bluetoothUnauthorizedMessage: String
    let bluetoothScanTimeoutMessage: String
    
    public init(bluetoothUnavailableMessage: String? = nil, bluetoothPowerOffMessage: String? = nil, bluetoothUnauthorizedMessage: String? = nil, bluetoothScanTimeoutMessage: String? = nil) {
        self.bluetoothUnavailableMessage = bluetoothUnavailableMessage ?? defaultBluetoothUnavailableMessage
        self.bluetoothPowerOffMessage = bluetoothPowerOffMessage ?? defaultBluetoothPowerOffMessage
        self.bluetoothUnauthorizedMessage = bluetoothUnauthorizedMessage ?? defaultBluetoothUnauthorizedMessage
        self.bluetoothScanTimeoutMessage = bluetoothScanTimeoutMessage ?? defaultBluetoothScanTimeoutMessage
    }
}
