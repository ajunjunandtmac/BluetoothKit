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
    func gatt(_ gatt: BluetoothGATT, didChange connectStatus: CBPeripheralState)
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
    var connectStatus: CBPeripheralState {
        set {
            bluetoothGattDelegates.forEach { $0.gatt(self, didChange: newValue) }
        }

        get {
            return peripheral?.state ?? .disconnected
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
        let allCharacteristicInitialized = gattProfile.characteristics.allSatisfy { $0.characteristic != nil }
        return allServicesInitialized && allCharacteristicInitialized
    }
    private let taskQueue = BluetoothTaskQueue()
    private var initializeStatus: BluetoothGattInitializeState = .notStarted {
        willSet {
            bluetoothGattDelegates.forEach { $0.gatt(self, didChange: newValue) }
        }
    }
    private var listeners: [CBUUID: ListenCallback?] = [:]
    private let notifyDataCombiner = BluetoothReceivableDataCombiner()

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

    // MARK: - Open function

    /// must override this to fill all the services and characteristics information of the bluetooth peripheral
    /// - Returns: all the services and characteristics contains in the bluetooth peripheral
    open func setupGattProfile() -> BluetoothGATTProfile {
        fatalError("must be override")
    }
    
    open func maximumWritePayloadLength() -> Int {
        fatalError("must be override")
    }

    // MARK: - Public function

    /// get the identifier of the bluetooth peripheral
    /// - Returns: deviceId
    public func getDeviceId() -> String? {
        return deviceId
    }

    /// get the broadcast advertisementData of the bluetooth peripheral
    /// - Returns: advertisementData
    public func getAdvertisementData() -> [String: Any]? {
        return advertisementData
    }

    /// add observer to observe the status change of the bluetooth peripheral
    /// - Parameter delegate: the BluetoothGATTDelegate
    public func addBluetoothGattDelegate(_ delegate: BluetoothGATTDelegate) {
        pointerArray.addObject(delegate)
        delegate.gatt(self, didChange: connectStatus)
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

    // MARK: - Protected function
    
    /// do some custom configuration of the peripheral by overriding the method
    func initiateDevice() {
        if deviceInitialized { return }
        taskQueue.process(event: .didInitialized, error: nil)
        deviceInitialized = true
    }
    /// get the CBPeripheral object
    /// - Returns: CBPeripheral object
    func getPeripheral() -> CBPeripheral? {
        return peripheral
    }

    func onGattConnecting() {
        self.connectStatus = .connecting
    }

    func onGattConnected() {
        if !deviceInitialized {
            discoverService()
        }
        self.connectStatus = .connected
    }

    func onGattDisconnecting() {
        self.connectStatus = .disconnecting
    }

    func onGattDisconnected() {
        self.connectStatus = .disconnected
        if disconnectFlag != .byUser {
            disconnectFlag = .bySystem
        }
        resetDevice()
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
            if let matchedGattService = servicesInPeripheral?.first(where: { $0.uuid == gattService.uuid }) {
                gattService.service = matchedGattService
                let matchedCharacteristics = gattProfile.characteristics.filter { $0.service.uuid == matchedGattService.uuid }
                let characteristicUUIDs = matchedCharacteristics.map { $0.uuid }
                peripheral.discoverCharacteristics(characteristicUUIDs, for: matchedGattService)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let matchedGattService = gattProfile.services.first(where: { $0.uuid == service.uuid }) {
            let characteristicsInService = service.characteristics ?? []
            let gattCharacteristics = gattProfile.characteristics.filter { $0.service.uuid == matchedGattService.uuid }
            gattCharacteristics.forEach { gattCharacteristic in
                if let matchedGattChar = characteristicsInService.first(where: { $0.uuid == gattCharacteristic.uuid }) {
                    gattCharacteristic.characteristic = matchedGattChar
                }
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
            taskQueue.process(event: .didReadCharacteristic(characteristic, data), error: error)
        }
        
        if responseChar.type.contains(.notify) {
            guard let listenerCallBack = listeners[characteristic.uuid], let listenerCallBack = listenerCallBack else {
                return
            }
            if let data = characteristic.value {
                listenerCallBack(.success(data))
            } else if error != nil {
                listenerCallBack(.failure(.gattNotifyFailed))
            }
        }
    }
}
