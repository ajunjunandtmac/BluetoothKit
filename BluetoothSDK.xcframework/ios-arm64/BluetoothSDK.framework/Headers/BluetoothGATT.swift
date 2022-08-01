//
//  BluetoothGATT.swift
//  BluetoothSDK
//
//  Created by Steven Zhou on 2022/5/9
//  Copyright © 2022 Stationdm. All rights reserved.
//

import CoreBluetooth
import UIKit

public protocol BluetoothGATTDelegate: AnyObject {
    func gatt(_ gatt: BluetoothGATT, didChange initializeStatus: BluetoothGattInitializeState)
    func gatt(_ gatt: BluetoothGATT, didChange connectStatus: BluetoothPeripheralConnectStatus)
    func gatt(_ gatt: BluetoothGATT, didRead RSSI: Int)
}

public extension BluetoothGATTDelegate {
    func gatt(_ gatt: BluetoothGATT, didChange initializeStatus: BluetoothGattInitializeState) { }
    func gatt(_ gatt: BluetoothGATT, didRead RSSI: Int) { }
}

public enum BluetoothGattInitializeState {
    case notStarted
    case initializing
    case initialized
    case failed
}

public enum BluetoothPeripheralConnectStatus {
    case disconnected(flag: BluetoothGATTDisconnectFlag)
    case connecting
    case connected
    case disconnecting

    var descriptionInternal: String {
        switch self {
        case .disconnected(let flag):
            return "disconnected, flag = \(flag)"
        case .connecting, .connected, .disconnecting:
            return String(describing: self)
        }
    }
}

extension BluetoothPeripheralConnectStatus: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected):
            return true
        case (.connecting, .connecting):
            return true
        case (.connected, .connected):
            return true
        case (.disconnecting, .disconnecting):
            return true
        default:
            return false
        }
    }
}

/// An abstract class which representing a Bluetooth peripheral
open class BluetoothGATT: NSObject, CBPeripheralDelegate {

    // MARK: - Protected property
    var localName: String?
    var autoReconnect = true
    var connectPriority: BluetoothGATTConnectPriority = .required
    let deviceId: String?
    var advertisementData: [String: Any]?
    var peripheral: CBPeripheral?
    var disconnectFlag: BluetoothGATTDisconnectFlag = .none
    var connectStatus: BluetoothPeripheralConnectStatus = .disconnected(flag: .none) {
        didSet {
            if connectStatus != oldValue {
                BTLogRecord.peripheralWillChangeConnectStates(uuid: getDeviceId() ?? "", preState: oldValue.descriptionInternal, newState: connectStatus.descriptionInternal).log()
                bluetoothGattDelegates.forEach { $0.gatt(self, didChange: connectStatus) }
            } else {
                BTLogRecord.peripheralReceiveUnchangedConnectStates(uuid: getDeviceId() ?? "", newState: connectStatus.descriptionInternal).log()
            }
        }
    }

    // MARK: - Private property
    private var gattProfile: BluetoothGATTProfile
    private let pointerArray: NSPointerArray = NSPointerArray.weakObjects()
    private var bluetoothGattDelegates: [BluetoothGATTDelegate] {
        let delegates: [BluetoothGATTDelegate] = self.pointerArray.getTargetObjects()
        return delegates
    }
    private var deviceInitialized = false
    private var isReadyToInitiate: Bool {
        let allServicesInitialized = gattProfile.services.allSatisfy { $0.service != nil }
        if !allServicesInitialized {
            let lackOfService = gattProfile.services.filter { $0.service == nil }
            let lackOfServiceUUIDs = lackOfService.map { $0.uuid.uuidString }
            let lackOfServiceUUIDString = lackOfServiceUUIDs.joined(separator: ",")
            BTLogRecord.lackOfServiceWhenPeripheralInitializing(peripheralUUID: getDeviceId() ?? "", lacServiceUUIDs: lackOfServiceUUIDString).log()
        }
        let allCharacteristicInitialized = gattProfile.characteristics.allSatisfy { $0.characteristic != nil }
        if !allCharacteristicInitialized {
            let lackOfChars = gattProfile.characteristics.filter { $0.characteristic == nil }
            let lackOfCharsUUIDs = lackOfChars.map { $0.uuid.uuidString }
            let lackOfCharsUUIDString = lackOfCharsUUIDs.joined(separator: ",")
            BTLogRecord.lackOfCharacteristicWhenPeripheralInitializing(peripheralUUID: getDeviceId() ?? "", lackCharUUIDs: lackOfCharsUUIDString).log()
        }
        return allServicesInitialized && allCharacteristicInitialized
    }
    private let taskQueue = BluetoothTaskQueue(type: .gatt)
    private var initializeStatus: BluetoothGattInitializeState = .notStarted {
        willSet {
            bluetoothGattDelegates.forEach { $0.gatt(self, didChange: newValue) }
        }
    }
    private var listeners: [CBUUID: ListenCallback?] = [:]
    private let notifyDataCombiner = BluetoothReceivableDataCombiner()
    private let connectionTimeoutMonitor = BluetoothGATTConnectionTimeoutMonitor(timeout: 10)

    // MARK: - Public constructor
    public required init(with discovery: BluetoothDiscovery) {
        deviceId = discovery.deviceId
        peripheral = discovery.peripheral
        localName = discovery.localName
        advertisementData = discovery.advertisementData
        gattProfile = BluetoothGATTProfile(characteristics: [])
        super.init()
        if type(of: self) == BluetoothGATT.self {
            fatalError("Bluetooth GATT can not be initialized directly")
        }
        gattProfile = setupGattProfile()
    }

    public required init(with deviceId: String) {
        self.deviceId = deviceId
        gattProfile = BluetoothGATTProfile(characteristics: [])
        super.init()
        gattProfile = setupGattProfile()
    }

    // FIXME: Need to know how to get the identifier of the ANCS device
    public required init(with peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.deviceId = peripheral.identifier.uuidString
        gattProfile = BluetoothGATTProfile(characteristics: [])
        super.init()
        gattProfile = setupGattProfile()
    }

    // MARK: - Open function

    /// must override this to fill all the services and characteristics information of the bluetooth peripheral
    /// - Returns: all the services and characteristics contains in the bluetooth peripheral
    open func setupGattProfile() -> BluetoothGATTProfile {
        fatalError("must be override")
    }

    open func maximumWritePayloadLength() -> Int {
        fatalError("must be override")
    }
    
    
    open func getDeviceModel() -> String {
        fatalError("must be override")
    }


    // MARK: - Public function

    /// get the identifier of the bluetooth peripheral
    /// - Returns: deviceId
    public func getDeviceId() -> String? {
        return deviceId ?? peripheral?.identifier.uuidString
    }

    public func getDeviceName() -> String? {
        return localName
    }

    public func getDeviceInitialized() -> Bool {
        return deviceInitialized
    }

    /// get the broadcast advertisementData of the bluetooth peripheral
    /// - Returns: advertisementData
    public func getAdvertisementData() -> [String: Any]? {
        return advertisementData
    }

    /// add observer to observe the status change of the bluetooth peripheral
    /// - Parameter delegate: the BluetoothGATTDelegate
    public func addBluetoothGattDelegate(_ delegate: BluetoothGATTDelegate, readBuffer: Bool) {
        pointerArray.addObject(delegate)
        if readBuffer {
            delegate.gatt(self, didChange: connectStatus)
        }
    }

    public func removeBluetoothGattDelegate(_ delegate: BluetoothGATTDelegate) {
        pointerArray.removeObject(delegate)
    }

    public func writeData<T: BluetoothSendableDataProtocol>(_ data: T, characteristic: BluetoothGATTCharacteristic, completion: BluetoothWriteResultCallback?) {
        guard let peripheral = peripheral else {
            completion?(.failure(BluetoothGATTError.gattDisconnected))
            return
        }

        var writeType: CBCharacteristicWriteType
        if characteristic.type.contains(.writeWithResponse) {
            writeType = .withResponse
        } else if characteristic.type.contains(.writeWithoutResponse) {
            writeType = .withoutResponse
        } else {
            completion?(.failure(BluetoothGATTError.writeNotSupport(characteristicUUID: characteristic.uuid.uuidString)))
            return
        }

        let data = data.bluetoothData()

        let writeTask = BluetoothWriteTask(queue: taskQueue, peripheral: peripheral, maximumWritePayloadLength: maximumWritePayloadLength(), value: data, characteristic: characteristic, writeType: writeType, callback: completion)
        taskQueue.push(writeTask)
        taskQueue.execute()
    }

    public func readData<T: BluetoothReceivableDataProtocol>(characteristic: BluetoothGATTCharacteristic, completion: BluetoothReadResultCallback<T>?) {
        guard let peripheral = peripheral else {
            completion?(.failure(BluetoothGATTError.gattDisconnected))
            return
        }
        let readTask = BluetoothReadTask(queue: taskQueue, peripheral: peripheral, characteristic: characteristic, callback: completion)
        taskQueue.push(readTask)
        taskQueue.execute()
    }
    
    public func readRssi(interval: TimeInterval) {
        guard let peripheral = peripheral, peripheral.state == .connected else {
            return
        }
        
        let readRSSITask = BluetoothReadRSSITask(queue: taskQueue, peripheral: peripheral) { res in
            switch res {
            case let .success(value):
                self.bluetoothGattDelegates.forEach {
                    $0.gatt(self, didRead: value)
                }
            case .failure:
                break
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(Int(interval*1000))) {
                self.readRssi(interval: interval)
            }
        }
        taskQueue.push(readRSSITask)
        taskQueue.execute()
    }

    public func listenTo<T: BluetoothReceivableDataProtocol>(characteristic: BluetoothGATTCharacteristic, notify: Bool, completion: BluetoothSetNotifyResultCallback?, notifyDataCallback: BluetoothReadResultCallback<T>?) {
        guard let peripheral = peripheral else {
            completion?(.failure(BluetoothGATTError.gattDisconnected))
            return
        }
        let setNotifyTask = BluetoothSetNotifyTask(queue: taskQueue, peripheral: peripheral, characteristic: characteristic, notify: notify) { result in
            switch result {
            case let .success(res):
                if res.notify {
                    self.listeners[characteristic.uuid] = { [weak self] dataResult in
                        switch dataResult {
                        case let .success(data):
                            let packet = T.init(bluetoothData: data)
                            if let fullData = self?.notifyDataCombiner.receive(headerDataFlag: packet.headerDataFlag(), tailDataFlag: packet.tailDataFlag(), payload: data) {
                                let fullPacket = T.init(bluetoothData: fullData)
                                notifyDataCallback?(.success(fullPacket))
                            }

                        case let .failure(error):
                            notifyDataCallback?(.failure(error))
                        }
                    }
                } else {
                    // remove from listener queue
                    self.listeners[characteristic.uuid] = nil
                }
            case .failure:
                break
            }
            completion?(result)
        }
        taskQueue.push(setNotifyTask)
        taskQueue.execute()
    }

    public func getConnectStatus() -> BluetoothPeripheralConnectStatus {
        return connectStatus
    }

    // MARK: - Protected function

    /// do some custom configuration of the peripheral by overriding the method
    func initiateDevice() {
        if deviceInitialized { return }
        taskQueue.process(event: .gattInitialized, error: nil)
        deviceInitialized = true
    }
    /// get the CBPeripheral object
    /// - Returns: CBPeripheral object
    func getPeripheral() -> CBPeripheral? {
        return peripheral
    }

    func onGattConnecting() {
        self.connectStatus = .connecting
        connectionTimeoutMonitor.startPeripheralConnectTimeoutMonitor(target: self)
    }

    func onGattConnected() {
        connectionTimeoutMonitor.cancelPeripheralConnectTimeoutMonitor(target: self)
        self.connectStatus = .connected
        if !deviceInitialized {
            discoverService()
        }
    }

    func onGattDisconnecting() {
        self.connectStatus = .disconnecting
    }

    func onGattDisconnected(flag: BluetoothGATTDisconnectFlag) {
        connectionTimeoutMonitor.cancelPeripheralConnectTimeoutMonitor(target: self)
        connectStatus = .disconnected(flag: flag)
        disconnectFlag = flag
        resetDevice()
        switch flag {
        case .byUser:
            autoReconnect = false
        case .bySystem:
            autoReconnect = true
        case .poweredOff:
            autoReconnect = true
        case .unpair:
            autoReconnect = false
        case .none:
            autoReconnect = false
        case .timeout:
            autoReconnect = false
        }
    }

    func onGattConnectionTimeout() {
        BTLogRecord.peripheralConnectionTimeout(uuid: getDeviceId() ?? "").log()
        BLECentralManager.shared.gattConnectTimeout(self)
    }

    // MARK: - Private function
    private func discoverService() {
        guard let peripheral = peripheral else {
            initializeStatus = .failed
            return
        }
        peripheral.delegate = self
        initializeStatus = .initializing
        let task = BluetoothGATTInitializeTask(queue: taskQueue, peripheral: peripheral, gattProfile: gattProfile) { result in
            switch result {
            case .failure:
                self.initializeStatus = .failed
            case .success:
                self.initializeStatus = .initialized
            }
        }
        taskQueue.push(task)
        taskQueue.execute()
    }

    private func resetDevice() {
        gattProfile.services.forEach { $0.service = nil }
        gattProfile.characteristics.forEach { $0.characteristic = nil }
        taskQueue.resetAfterDisconnected()
        deviceInitialized = false
    }

    public override var hash: Int {
        return deviceId?.hashValue ?? 0
    }

    // MARK: - CBPeripheralDelegate
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let servicesInPeripheral = peripheral.services
        gattProfile.services.forEach { gattService in
            BTLog("peripheral: \(self.getDeviceId() ?? "") discovering service: \(gattService.uuid.uuidString)")
            if let matchedGattService = servicesInPeripheral?.first(where: { $0.uuid.uuidString.uppercased() == gattService.uuid.uuidString.uppercased() }) {
                gattService.service = matchedGattService
                BTLog("peripheral: \(self.getDeviceId() ?? "") discovered matched service: \(matchedGattService.uuid.uuidString)")
                let matchedCharacteristics = gattProfile.characteristics.filter { $0.service.uuid.uuidString.uppercased() == matchedGattService.uuid.uuidString.uppercased() }
                let characteristicUUIDs = matchedCharacteristics.map { $0.uuid }
                peripheral.discoverCharacteristics(nil, for: matchedGattService)
                let characteristicUUIDString = characteristicUUIDs.map { $0.uuidString }.joined(separator: ",")
                BTLog("peripheral: \(self.getDeviceId() ?? "") begin discovering characteristics: \(characteristicUUIDString)")
            } else {
                taskQueue.process(event: .gattInitialized, error: BluetoothGATTError.gattInitialFailed)
                BTLog("peripheral: \(self.getDeviceId() ?? "") did not discovered the target service: \(gattService.uuid.uuidString)")
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let matchedGattService = gattProfile.services.first(where: { $0.uuid.uuidString.uppercased() == service.uuid.uuidString.uppercased() }) {
            let characteristicsInService = service.characteristics ?? []
            characteristicsInService.forEach {
                let property = $0.properties.rawValue
                BTLog("find real characteristic: \($0.uuid.uuidString), property: \(property) service: \($0.service?.uuid.uuidString ?? "unknown") in peripheral: \(peripheral.identifier.uuidString)")
            }
            let gattCharacteristics = gattProfile.characteristics.filter { $0.service.uuid.uuidString.uppercased() == matchedGattService.uuid.uuidString.uppercased() }
            gattCharacteristics.forEach { gattCharacteristic in
                BTLog("peripheral: \(self.getDeviceId() ?? "") discovering characteristic: \(gattCharacteristic.uuid.uuidString)")
                if let matchedGattChar = characteristicsInService.first(where: { $0.uuid.uuidString.uppercased() == gattCharacteristic.uuid.uuidString.uppercased() }) {
                    gattCharacteristic.characteristic = matchedGattChar
                    BTLog("peripheral: \(self.getDeviceId() ?? "") discovered matched characteristic: \(matchedGattChar.uuid.uuidString)")
                }
            }

            let notInitializedChars = gattCharacteristics.filter { $0.characteristic == nil }
            if notInitializedChars.isEmpty == false {
                taskQueue.process(event: .gattInitialized, error: BluetoothGATTError.gattInitialFailed)
                let charUUIDString = notInitializedChars.map { $0.uuid.uuidString }.joined(separator: ",")
                BTLog("peripheral: \(self.getDeviceId() ?? "") did not discovered the target characteristics: \(charUUIDString)")
            }
        }

        if isReadyToInitiate {
            initiateDevice()
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        taskQueue.process(event: .didWriteCharacteristic(characteristic), error: error)
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        taskQueue.process(event: .didUpdateCharacteristicNotificationState(characteristic), error: error)
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let responseChar = gattProfile.characteristics.first(where: { $0.uuid == characteristic.uuid }) else {
            return
        }

        if responseChar.type.contains(.read) {
            guard let data = characteristic.value else { return }
            let parsed = BluetoothIOTTool.Decoder.DecodeDataToHexString(data: data, connector: "")
            BTLog("peripheral: \(self.getDeviceId() ?? "") did read data: \(parsed) from characteristic: \(characteristic.uuid.uuidString)")
            taskQueue.process(event: .didReadCharacteristic(characteristic, data), error: error)
        }

        if responseChar.type.contains(.notify) {
            guard let listenerCallBack = listeners[characteristic.uuid], let listenerCallBack = listenerCallBack else {
                return
            }

            if let error = error {
                BTLog("peripheral: \(self.getDeviceId() ?? "") get notify data with error: \(error.localizedDescription) from characteristic: \(characteristic.uuid.uuidString)")
                listenerCallBack(.failure(.gattNotifyFailed(errorMsg: error.localizedDescription)))
            } else if let data = characteristic.value {
                let parsed = BluetoothIOTTool.Decoder.DecodeDataToHexString(data: data, connector: "", withHexPrefix: false)
                BTLogRecord.didReceiveData(peripheralUUID: self.getDeviceId() ?? "", charUUID: characteristic.uuid.uuidString, deviceModel: getDeviceModel(), data: parsed).log()
                listenerCallBack(.success(data))
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        let value = RSSI.intValue
        taskQueue.process(event: .didReadRSSIValue(value), error: error)
    }
}
