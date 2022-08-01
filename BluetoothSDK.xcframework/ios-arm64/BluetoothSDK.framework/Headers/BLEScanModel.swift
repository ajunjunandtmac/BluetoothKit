//
//  BLEScanModel.swift
//  BluetoothSDK
//
//  Created by Steven Zhou on 2022/5/9
//  Copyright © 2022 Stationdm. All rights reserved.
//

import UIKit
import CoreBluetooth
public class BLEScanModel {
    var advServiceUUIDs: [CBUUID] = []
    var implementedServiceUUIDs: [CBUUID] = []
    var timeout: Double = 0
    init() { }

    /// Scan configurations
    /// - Parameters:
    ///   - advServiceUUIDs: advertisement UUID
    ///   - timeout: negative or 0 value means no timeout limited
    convenience public init(advServiceUUIDs: [CBUUID], implementedServiceUUIDs: [CBUUID], timeout: Double) {
        self.init()
        self.advServiceUUIDs = advServiceUUIDs
        self.implementedServiceUUIDs = implementedServiceUUIDs
        self.timeout = timeout
    }
}
