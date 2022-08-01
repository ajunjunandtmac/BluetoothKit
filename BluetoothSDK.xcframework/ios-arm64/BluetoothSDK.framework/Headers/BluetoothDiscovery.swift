//
//  BluetoothDiscovery.swift
//  BluetoothSDK
//
//  Created by Steven Zhou on 2022/5/9
//  Copyright © 2022 Stationdm. All rights reserved.
//      

import CoreBluetooth

public class BluetoothDiscovery {
     // MARK: - Public property
    
    /// local name of the scanned bluetooth peripheral
    public var localName: String {
        return advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? ""
    }
    
    /// signal strength of the scanned bluetooth peripheral
    public var rssiValue: NSNumber {
        return RSSI
    }
    
    /// the unique identifier of the scanned bluetooth peripheral
    public var deviceId: String?
    
    // MARK: - Protected property
    var advertisementData: [String: Any]
    var RSSI: NSNumber
    var peripheral: CBPeripheral
    var serviceUUIDs: [CBUUID]? {
        return advertisementData[CBAdvertisementDataServiceUUIDsKey] as? Array<CBUUID>
    }
    var identifier: String {
        return peripheral.identifier.uuidString
    }
    
    // MARK: - Protected constructors
    init(advertisementData: [String: Any], RSSI: NSNumber, peripheral: CBPeripheral){
        self.advertisementData = advertisementData
        self.RSSI = RSSI
        self.peripheral = peripheral
//        BTLog([peripheral.name, peripheral.identifier.uuidString])
        if let deviceId = BluetoothUtils.getDeviceMacAddress(from: advertisementData) {
            // FIXME: try to get an unique identifier from the scanned peripheral
            self.deviceId = peripheral.identifier.uuidString
        } else {
            self.deviceId = peripheral.identifier.uuidString
//            BTLog("\(#file) no value with CBAdvertisementDataManufacturerDataKey!")
        }
    }
}

extension BluetoothDiscovery: Hashable, Equatable {
    public static func == (lhs: BluetoothDiscovery, rhs: BluetoothDiscovery) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
