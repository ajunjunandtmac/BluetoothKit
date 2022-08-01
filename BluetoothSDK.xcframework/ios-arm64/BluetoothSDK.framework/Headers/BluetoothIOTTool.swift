//
//  BluetoothIOTTool.swift
//  BluetoothSDK
//
//  Created by Jessy Gu on 2022/5/18.
//  Copyright © 2022 Stationdm. All rights reserved.
//

import Foundation

class BluetoothIOTTool {
    typealias HexString = String
    typealias DecimalString = String

    class Decoder {
        static func decode<T>(data: Data, to type: T.Type) -> T {
            let value: T = data.withUnsafeBytes { $0.load(as: T.self) }
            return value
        }

        static func DecodeDataToBytes(data: Data) -> [UInt8] {
            let fileBytes: [UInt8] = data.map({ $0 })
            return fileBytes
        }
        
        /// convert Data to hex string
        /// e.g. if joinSeparator = ","
        /// will convert to "55,aa,8b,07"
        /// - Parameters:
        ///   - data: data
        ///   - connector: join mark
        /// - Returns: hexString with connector
        static func DecodeDataToHexString(data: Data, connector: String, withHexPrefix: Bool = false) -> String {
            let bytes = DecodeDataToBytes(data: data)
            let hexes = bytes.map { withHexPrefix ? "0x\(Helper.HexString(with: $0))" : Helper.HexString(with: $0) }
            let retVal = hexes.joined(separator: connector)
            return retVal
        }
        
        static func DecodeDataToAsciiString(data: Data) -> String? {
            let ascii = String(data: data, encoding: .ascii)
            return ascii
        }
    }

    class Helper {
        static func HexString(with decimalString: DecimalString) -> HexString? {
            guard let decimalValue = UInt8(decimalString) else { return nil }
            let hexString = HexString(with: decimalValue)
            return hexString
        }

        static func HexString(with byte: UInt8) -> HexString {
            var hexString = String(format: "%X", byte)
            if hexString.count % 2 != 0 {
                hexString = "0" + hexString
            }
            return hexString
        }

        /// 支持把hexString转换为实现ZJIOTDataStructure协议的类型
        static func Decimal<T: BluetoothIOTDataProtocol>(with hexString: String) -> T? {
            let scanner = Scanner(string: hexString)
            let tTypeString = T.TypeString().lowercased()
            // iOS 13
            // scanner.scanInt(representation: .hexadecimal)
            if tTypeString.contains("string") {
                var uint64value: UInt64 = 0
                if scanner.scanHexInt64(&uint64value) {
                    let decimalString = String(format: "%lu", uint64value)
                    return decimalString as? T
                }
            }

            if tTypeString.contains("uint32") {
                var uint32value: UInt32 = 0
                if scanner.scanHexInt32(&uint32value) {
                    return uint32value as? T
                }
            }

            if tTypeString.contains("uint64") {
                var uint64value: UInt64 = 0
                if scanner.scanHexInt64(&uint64value) {
                    return uint64value as? T
                }
            }
            return nil
        }
    }
}
