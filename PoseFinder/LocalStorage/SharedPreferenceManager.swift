//
//  SharedPreferenceManager.swift
//  BlueToothTest2.0
//
//  Created by iOS Dev on 08/12/25.
//

import Foundation
import CoreBluetooth

final class SharedPreferenceManager {

    static let shared = SharedPreferenceManager()

    private let connectedDeviceKey = "connected_device_uuid"
    private let writeCharacteristicKey = "write_characteristic_uuid"
    private let lastServoCommandKey = "last_servo_command_timestamp"
    
    private init() {}

    // MARK: - Save Connected Device UUID
    func saveConnectedDevice(_ device: BLEDevice) {
        UserDefaults.standard.set(device.deviceUuid.uuidString, forKey: connectedDeviceKey)
    }

    // MARK: - Get Connected Device UUID
    func getSavedDeviceUUID() -> UUID? {
        guard let uuidString = UserDefaults.standard.string(forKey: connectedDeviceKey) else {
            return nil
        }
        return UUID(uuidString: uuidString)
    }

    // MARK: - Clear Device
    func clearConnectedDevice() {
        UserDefaults.standard.removeObject(forKey: connectedDeviceKey)
        UserDefaults.standard.removeObject(forKey: writeCharacteristicKey)
    }

    // MARK: - Save Write Characteristic UUID
    func saveWriteCharacteristicUUID(_ uuid: CBUUID) {
        UserDefaults.standard.set(uuid.uuidString, forKey: writeCharacteristicKey)
    }

    // MARK: - Load Write Characteristic UUID
    func getSavedWriteCharacteristicUUID() -> CBUUID? {
        guard let uuidString = UserDefaults.standard.string(forKey: writeCharacteristicKey) else {
            return nil
        }
        return CBUUID(string: uuidString)
    }
    
    // MARK: - Last Servo Command Timestamp
    func saveLastServoCommandTime(_ date: Date = Date()) {
        UserDefaults.standard.set(date, forKey: lastServoCommandKey)
    }
    func getLastServoCommandTime() -> Date? {
        return UserDefaults.standard
            .object(forKey: lastServoCommandKey) as? Date
    }

    func clearLastServoCommandTime() {
        UserDefaults.standard.removeObject(forKey: lastServoCommandKey)
    }
}
