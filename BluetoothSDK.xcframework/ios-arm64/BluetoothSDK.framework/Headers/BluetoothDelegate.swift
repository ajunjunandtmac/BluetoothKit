//
//  BluetoothDelegate.swift
//  BluetoothSDK
//
//  Created by Jessy Gu on 2022/5/18.
//  Copyright © 2022 Stationdm. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol BluetoothDelegate: AnyObject {
    func bluetoothDidBeginScanning()
    func bluetoothDidEndScan()
    func bluetoothDidDiscoverPeripherals(_ peripherals: [BluetoothDiscovery])
    func bluetoothDidDiscoverConnectedPeripherals(_ peripherals: [CBPeripheral])
}
