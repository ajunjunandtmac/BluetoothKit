//
//  BluetoothGATTDescription.swift
//  BluetoothSDK
//
//  Created by Steven Zhou on 2022/5/9
//  Copyright © 2022 Stationdm. All rights reserved.
//

import UIKit
import CoreBluetooth

public class BluetoothGATTProfile {
    let characteristics: [BluetoothGATTCharacteristic]
    let services: [BluetoothGATTService]
    public init(characteristics: [BluetoothGATTCharacteristic]) {
        self.characteristics = characteristics
        let services = characteristics.map { $0.service }
        let uniqueServices = Set(services)
        self.services = uniqueServices.map { $0 }
    }
}
