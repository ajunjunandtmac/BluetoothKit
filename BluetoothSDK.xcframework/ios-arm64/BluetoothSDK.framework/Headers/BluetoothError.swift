//
//  BluetoothError.swift
//  BluetoothSDK
//
//  Created by Jessy Gu on 2022/5/18.
//  Copyright © 2022 Stationdm. All rights reserved.
//

import Foundation

public enum BluetoothError: Error {
    case resetting
    case unsupported
    case poweredOff
    case unauthorized
    case unknown
    case scanTimeout
}

public enum BluetoothGATTError: Error {
    case gattInitialFailed
    case gattDisconnected
    case gattWriteFailed(errorMsg: String?)
    case gattReadFailed
    case gattNotifyFailed(errorMsg: String?)
    case writeNotSupport(characteristicUUID: String)
    case bluetoothReadyFailed
    case bluetoothScanFailed
}
