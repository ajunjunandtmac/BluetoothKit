//
//  BLEScanModel.swift
//  BluetoothSDK
//
//  Created by Steven Zhou on 2022/5/9
//  Copyright © 2022 Stationdm. All rights reserved.
//      

import UIKit
import CoreBluetooth

@objc public class BLEScanModel: NSObject {
    let advServiceUUIDs: [CBUUID]
    let timeout: Double
    
    /// Scan configurations
    /// - Parameters:
    ///   - advServiceUUIDs: advertisement UUID
    ///   - timeout: negative or 0 value means no timeout limited
    public init(advServiceUUIDs: [CBUUID], timeout: Double) {
        self.advServiceUUIDs = advServiceUUIDs
        self.timeout = timeout
        super.init()
    }
}
