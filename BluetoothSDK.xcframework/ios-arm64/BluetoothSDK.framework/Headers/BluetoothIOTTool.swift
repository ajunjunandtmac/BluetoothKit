//
//  BluetoothIOTTool.swift
//  BluetoothSDK
//
//  Created by Jessy Gu on 2022/5/18.
//  Copyright © 2022 Stationdm. All rights reserved.
//

import Foundation

public class BluetoothIOTTool {
    public typealias HexString = String
    public typealias DecimalString = String
    public class Encoder {
        public static func BluetoothData(with bytes: [UInt8]) -> Data {
            return Data(bytes)
        }
        
        /// Data Encode
        /// - Parameter hexStringArray: [01 2C 33]
        public static func BluetoothData(with hexStringArray: [HexString]) -> Data {
            let bytes = hexStringArray.compactMap { (command) -> UInt8? in
                guard let uint32Value: UInt32 = Helper.Decimal(with: command) else { return nil }
                let uint8Value = UInt8(truncatingIfNeeded: uint32Value)
                return uint8Value
            }

            let data = BluetoothData(with: bytes)
            return data
        }

        /// Data Encode
        /// - Parameter hexString: 012C33
        public static func BluetoothData(with hexString: HexString) -> Data {
            var hex: HexString = ""
            var hexArray: [HexString] = []
            var reversedHexString = String(hexString.reversed())
            if reversedHexString.count % 2 == 1 {
                reversedHexString += "0"
            }
            for (index, char) in reversedHexString.enumerated() {
                let charString = String(char)
                if index % 2 == 0 {
                    hex = charString
                } else {
                    hex = charString + hex
                    hexArray.insert(hex, at: 0)
                }
            }

            return BluetoothData(with: hexArray)
        }

        public static func BluetoothData<T>(from value: T) -> Data {
            let data = withUnsafeBytes(of: value) { Data($0) }
            return data
        }

        public static func EncodeLittleEndianDecimalToByteArray<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
            withUnsafeBytes(of: value.littleEndian, Array.init)
        }

        public static func EncodeBigEndianDecimalToByteArray<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
            withUnsafeBytes(of: value.bigEndian, Array.init)
        }

        public static func Encode(from text: String, encoding: String.Encoding) -> Data? {
            return text.data(using: encoding)
        }
    }

    public class Decoder {
        public static func decode<T>(data: Data, to type: T.Type) -> T {
            let value: T = data.withUnsafeBytes { $0.load(as: T.self) }
            return value
        }

        public static func DecodeDataToBytes(data: Data) -> [UInt8] {
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
        public static func DecodeDataToHexString(data: Data, connector: String) -> String {
            let bytes = DecodeDataToBytes(data: data)
            let hexes = bytes.map { Helper.HexString(with: $0) }
            let retVal = hexes.joined(separator: connector)
            return retVal
        }
    }

    public class Helper {
        public static func HexString(with decimalString: DecimalString) -> HexString? {
            guard let decimalValue = UInt8(decimalString) else { return nil }
            let hexString = HexString(with: decimalValue)
            return hexString
        }

        public static func HexString(with byte: UInt8) -> HexString {
            var hexString = String(format: "%X", byte)
            if hexString.count % 2 != 0 {
                hexString = "0" + hexString
            }
            return hexString
        }

        /// 支持把hexString转换为实现ZJIOTDataStructure协议的类型
        public static func Decimal<T: BluetoothIOTDataProtocol>(with hexString: String) -> T? {
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
