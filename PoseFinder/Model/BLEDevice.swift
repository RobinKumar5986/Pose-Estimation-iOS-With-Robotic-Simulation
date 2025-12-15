//
//  BLEDevice.swift
//  PoseFinder
//
//  Created by iOS Dev on 12/12/25.
//  Copyright © 2025 Apple. All rights reserved.
//


import Foundation
import CoreBluetooth

final class BLEDevice {
    let peripheral: CBPeripheral
    let name: String
    let deviceUuid: UUID
    var rssi: Int
    
    var characteristics: [CBUUID : CBCharacteristic] = [:]

    init(peripheral: CBPeripheral, name: String, deviceUuid: UUID, rssi: Int) {
        self.peripheral = peripheral
        self.name = name
        self.deviceUuid = deviceUuid
        self.rssi = rssi
    }
}

extension BLEDevice: Equatable {
    static func == (lhs: BLEDevice, rhs: BLEDevice) -> Bool {
        lhs.deviceUuid == rhs.deviceUuid
    }
}
enum ConnectionState: String {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case failed
    case unKnownError
}
