//
//  BluetoothError.swift
//  BluetoothSDK
//
//  Created by Jessy Gu on 2022/5/18.
//  Copyright © 2022 Stationdm. All rights reserved.
//

import Foundation

public enum BluetoothError: Error {
    case unsupported
    case poweredOff
    case unauthorized
    case unknown
    case scanTimeout
}

public enum BluetoothGATTError: Error {
    case gattInitialFailed
    case gattDisconnected
    case gattWriteFailed
    case gattReadFailed
    case gattNotifyFailed
    case writeNotSupport(characteristicUUID: String)
}
