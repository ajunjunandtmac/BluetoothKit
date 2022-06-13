//
//  BluetoothDelegate.swift
//  BluetoothSDK
//
//  Created by Jessy Gu on 2022/5/18.
//  Copyright © 2022 Stationdm. All rights reserved.
//

import Foundation

public protocol BluetoothDelegate: AnyObject {
    func bluetoothReady()
    func bluetoothDidBeginScanning()
    func bluetoothDidEndScan()
    func bluetoothDidMeetError(_ error: BluetoothError)
    func bluetoothDidDiscoverPeripherals(_ peripherals: [BluetoothDiscovery])
}
