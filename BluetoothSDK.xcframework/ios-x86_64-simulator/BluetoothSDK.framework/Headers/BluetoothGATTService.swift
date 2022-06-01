//
//  BluetoothGATTService.swift
//  BluetoothSDK
//
//  Created by Jessy Gu on 2022/5/18.
//  Copyright © 2022 Stationdm. All rights reserved.
//

import Foundation
import CoreBluetooth

/// A profile to describe a bluetooth service
public class BluetoothGATTService {
    let uuid: CBUUID
    public var service: CBService?
    public init(uuid: CBUUID) {
        self.uuid = uuid
    }
}

extension BluetoothGATTService: Hashable, Equatable {
    public static func == (lhs: BluetoothGATTService, rhs: BluetoothGATTService) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}
