//
//  BlueToothManager.swift
//  BlueToothTest2.0
//
//  Created by iOS Dev on 08/12/25.
//

import CoreBluetooth
import Foundation

final class BlueToothManager: NSObject {
    
    static let shared = BlueToothManager()
    var scanningState: Bool = false
    var centralManager: CBCentralManager!
    var discoveredDevices: [UUID: BLEDevice] = [:]
    var deviceConnectionState: ConnectionState = .disconnected
    weak var bluetoothDelegate: BlueToothManagerDelegate?
    private var connectionTimeoutTimer: Timer?
    private var deviceScanningTime = 4.0
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
}
/// It initiallly check for the state of the bluetooth i.e if its on , off etc.
extension BlueToothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("Bluetooth: Unknown state")
        case .resetting:
            print("Bluetooth: Resetting")
        case .unsupported:
            print("Bluetooth: Device does NOT support Bluetooth")
        case .unauthorized:
            print("Bluetooth: Permission DENIED")
        case .poweredOff:
            print("Bluetooth: OFF")
        case .poweredOn:
            print("Bluetooth: ON")
            self.startScanning()
        @unknown default:
            break
        }
    }
}

/// Functions for scanning bluetooth devices
extension BlueToothManager {
    func startScanning(){
        guard centralManager.state == .poweredOn else {
            //TODO: need to show pop-up for turning on the bluetooth
            return
        }
        discoveredDevices = [:]
        scanningState = true
        bluetoothDelegate?.onScanningStateChange(scanningState)
        centralManager
            .scanForPeripherals(
                withServices: nil,
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
            )
        DispatchQueue.main.asyncAfter(deadline: .now() + deviceScanningTime) {
            self.stopScan()
        }
    }
    func stopScan(){
        scanningState = false
        bluetoothDelegate?.onScanningStateChange(scanningState)
        centralManager.stopScan()
    }
}

/// manager for showing the devices which we have recived.
extension BlueToothManager {
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        guard let name = peripheral.name else { return }
        let deviceUuid = peripheral.identifier
        print("Device: \(name), deviceId: \(deviceUuid)")
        
        if let existing = discoveredDevices[deviceUuid] {
            // Update RSSI only
            existing.rssi = RSSI.intValue
            discoveredDevices[deviceUuid] = existing
        }else{
            let newDevice = BLEDevice(
                peripheral: peripheral,
                name: name,
                deviceUuid: deviceUuid,
                rssi: RSSI.intValue
            )
            discoveredDevices[deviceUuid] = newDevice
        }
        let devicesArray = Array(discoveredDevices.values)
            .sorted { $0.rssi > $1.rssi }
        bluetoothDelegate?.onDeviceChange(devicesArray)
    }
}


/// Functions for connecting device and diss-connectiong device
extension BlueToothManager: CBPeripheralDelegate {
    func connect(to device: BLEDevice) {
        guard deviceConnectionState == .disconnected || deviceConnectionState == .failed || deviceConnectionState == .unKnownError else {
            return
        }
        device.peripheral.delegate = self
        deviceConnectionState = .connecting
        bluetoothDelegate?.onConnectionStateChange(deviceConnectionState)
        centralManager.connect(device.peripheral)
        
        startConnectionTimeout(for: device)
        centralManager.connect(device.peripheral)
    }
    
    func disconnect(from device: BLEDevice) {
        guard deviceConnectionState != .disconnected && deviceConnectionState != .disconnecting else { return }
        deviceConnectionState = .disconnecting
        bluetoothDelegate?.onConnectionStateChange(deviceConnectionState)
        centralManager.cancelPeripheralConnection(device.peripheral)
    }
    func disconnectAllDevices() {
        for device in discoveredDevices.values {
            // Only disconnect devices that are currently connected or connecting
            if deviceConnectionState == .connected || deviceConnectionState == .connecting {
                centralManager.cancelPeripheralConnection(device.peripheral)
            }
        }
        // Clear stored connected device in SharedPreferences
        SharedPreferenceManager.shared.clearConnectedDevice()
        deviceConnectionState = .disconnected
        bluetoothDelegate?.onConnectionStateChange(deviceConnectionState)
        print("All connected devices have been disconnected")
    }
    
    func disconnectSavedDevice() {
        guard let savedUUID = SharedPreferenceManager.shared.getSavedDeviceUUID(),
              let device = discoveredDevices[savedUUID] else {
            print("No saved device to disconnect")
            return
        }
        
        guard deviceConnectionState != .disconnected && deviceConnectionState != .disconnecting else {
            print("Device is already disconnected or disconnecting")
            return
        }
        
        deviceConnectionState = .disconnecting
        bluetoothDelegate?.onConnectionStateChange(deviceConnectionState)
        
        centralManager.cancelPeripheralConnection(device.peripheral)
        SharedPreferenceManager.shared.clearConnectedDevice()
        print("Disconnecting device: \(device.name)")
    }
    func startConnectionTimeout(for device: BLEDevice) {
        connectionTimeoutTimer?.invalidate()
        
        connectionTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.deviceConnectionState == .connecting {
                print("Connection Timeout for device: \(device.name)")
                
                self.centralManager.cancelPeripheralConnection(device.peripheral)
                self.deviceConnectionState = .failed
                SharedPreferenceManager.shared.clearConnectedDevice()
                self.bluetoothDelegate?.onConnectionStateChange(.failed)
            }
        }
    }

}

/// functions for manageing the connection state of the device...
extension BlueToothManager { ///extend with this "CBCentralManagerDelegate" if not already extended
 
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionTimeoutTimer?.invalidate()

        print("Device Connected: \(peripheral.name ?? "Unknown")")
        deviceConnectionState = .connected

        if let device = discoveredDevices[peripheral.identifier] {
            SharedPreferenceManager.shared.saveConnectedDevice(device)
        }

        bluetoothDelegate?.onConnectionStateChange(deviceConnectionState)

        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to Connect: \(peripheral.name ?? "Unknown") | Error: \(error?.localizedDescription ?? "none")")
        deviceConnectionState = .failed
        SharedPreferenceManager.shared.clearConnectedDevice()
        bluetoothDelegate?.onConnectionStateChange(deviceConnectionState)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionTimeoutTimer?.invalidate()
        if let error = error {
            print("Device Disconnected Unexpectedly: \(peripheral.name ?? "Unknown") | Reason: \(error.localizedDescription)")
            deviceConnectionState = .unKnownError
        } else {
            print("Device Disconnected by User: \(peripheral.name ?? "Unknown")")
            deviceConnectionState = .disconnected
        }
        SharedPreferenceManager.shared.clearConnectedDevice()
        bluetoothDelegate?.onConnectionStateChange(deviceConnectionState)
        
    }
}

///function for sending and receving the data
extension BlueToothManager {
    
    /// Send data to a specific characteristic of a device
    func sendData(_ data: Data, to device: BLEDevice) {

        // Print raw byte data
        let hexString = data.map { String(format: "%02X", $0) }.joined(separator: " ")
        let binaryString = data.map { String($0, radix: 2) }.joined(separator: " ")
        print("Sending Data → HEX: [\(hexString)]  BINARY: [\(binaryString)]")

        guard let savedUUID = SharedPreferenceManager.shared.getSavedWriteCharacteristicUUID() else {
            print("ERROR: No saved write characteristic UUID")
            return
        }
        let targetUUIDString = savedUUID.uuidString.uppercased()

        guard let characteristic = device.characteristics.first(where: {
            $0.key.uuidString.uppercased() == targetUUIDString
        })?.value else {

            print("ERROR: Characteristic \(targetUUIDString) not found in this device")
            print("Available characteristics:")
            for (key, _) in device.characteristics {
                print(" → \(key.uuidString)")
            }
            return
        }

        let props = characteristic.properties
        if !props.contains(.write) && !props.contains(.writeWithoutResponse) {
            print("ERROR: Characteristic does not support write → \(props)")
            return
        }

        print("Writing \(data.count) bytes to \(characteristic.uuid.uuidString)")
        device.peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }

    /// Read data from a specific characteristic of a device
    func readData(from device: BLEDevice, characteristicUUID: CBUUID) {
        guard let characteristic = device.characteristics[characteristicUUID],
              characteristic.properties.contains(.read) else {
            print("Characteristic not readable")
            return
        }
        device.peripheral.readValue(for: characteristic)
    }
    
    /// Subscribe for notifications/updates on a characteristic
    func subscribe(to device: BLEDevice, characteristicUUID: CBUUID) {
        guard let characteristic = device.characteristics[characteristicUUID],
              characteristic.properties.contains(.notify) else {
            print("Characteristic not notifiable")
            return
        }
        device.peripheral.setNotifyValue(true, for: characteristic)
    }
    
    /// Unsubscribe from notifications
    func unsubscribe(from device: BLEDevice, characteristicUUID: CBUUID) {
        guard let characteristic = device.characteristics[characteristicUUID] else { return }
        device.peripheral.setNotifyValue(false, for: characteristic)
    }
}

/// auto data recive
extension BlueToothManager { /// need to implemet this "CBPeripheralDelegate" I have already done in prev extention 
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    ///In this function we save the characteristic for the write channel
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {

        guard let characteristics = service.characteristics else { return }

        print("=== FOUND CHARACTERISTICS FOR \(peripheral.name ?? "Device") ===")

        for characteristic in characteristics {

            let props = characteristic.properties

            // Save characteristic inside the device model
            if let device = discoveredDevices[peripheral.identifier] {
                device.characteristics[characteristic.uuid] = characteristic
                discoveredDevices[peripheral.identifier] = device
            }

            // Auto-save WRITE characteristic
            if props.contains(.write) || props.contains(.writeWithoutResponse) {
                print("WRITE SUPPORTED: \(characteristic.uuid.uuidString)")
                SharedPreferenceManager.shared.saveWriteCharacteristicUUID(characteristic.uuid)
            }

            // Auto enable notifications
            if props.contains(.notify) || props.contains(.indicate) {
                peripheral.setNotifyValue(true, for: characteristic)
            }

            if props.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
        }

        print("=============================================\n")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        print("Data received: \(characteristic.uuid): \(data)")
        if let str = String(data: data, encoding: .utf8) {
            print("As String: \(str)")
        }
    }
}
