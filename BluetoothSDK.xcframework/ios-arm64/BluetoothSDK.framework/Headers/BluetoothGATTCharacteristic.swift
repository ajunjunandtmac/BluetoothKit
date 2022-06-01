//
//  BluetoothGATTCharacteristic.swift
//  BluetoothSDK
//
//  Created by Jessy Gu on 2022/5/18.
//  Copyright © 2022 Stationdm. All rights reserved.
//

import Foundation
import CoreBluetooth

public struct BluetoothGATTCharacteristicType: OptionSet {
    public let rawValue: Int
    public static let writeWithResponse = BluetoothGATTCharacteristicType(rawValue: 1 << 0)
    public static let writeWithoutResponse = BluetoothGATTCharacteristicType(rawValue: 1 << 1)
    public static let read = BluetoothGATTCharacteristicType(rawValue: 1 << 2)
    public static let notify = BluetoothGATTCharacteristicType(rawValue: 1 << 3)
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// A profile to describe a bluetooth characteristic
public class BluetoothGATTCharacteristic {
    var uuid: CBUUID

    public var characteristic: CBCharacteristic?
    public let service: BluetoothGATTService
    let type: BluetoothGATTCharacteristicType
    
    public init(uuid: CBUUID, type: BluetoothGATTCharacteristicType, service: BluetoothGATTService) {
        self.uuid = uuid
        self.type = type
        self.service = service
    }
}
