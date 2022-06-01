//
//  BluetoothIOTDataProtocol.swift
//  BluetoothSDK
//
//  Created by Jessy Gu on 2022/5/18.
//  Copyright © 2022 Stationdm. All rights reserved.
//

import Foundation

public protocol BluetoothIOTDataProtocol {
    associatedtype StructureType
    static func TypeString() -> String
}
