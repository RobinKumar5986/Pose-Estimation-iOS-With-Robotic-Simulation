//
//  BlueToothManagerDelegate.swift
//  BlueToothTest2.0
//
//  Created by iOS Dev on 08/12/25.
//

protocol BlueToothManagerDelegate: AnyObject {
    func onDeviceChange(_ devices: [BLEDevice])
    func onScanningStateChange(_ isScanning: Bool)
    func onConnectionStateChange(_ connectionState: ConnectionState)
}

