//
//  DeviceConnectScreen.swift
//  BlueToothTest2.0
//
//  Created by iOS Dev on 08/12/25.
//

import UIKit
import CoreBluetooth

class DeviceConnectScreen: UIViewController, BlueToothManagerDelegate {

    var device: BLEDevice?
    let bluetoothManager = BlueToothManager.shared
    let backButton = UIButton(type: .system)

    private let connectionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Disconnected"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .medium)
        return label
    }()

    private let connectButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Connect", for: .normal)
        button.backgroundColor = .systemGreen
        button.tintColor = .white
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        return button
    }()

    private let sendDataButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Send Data", for: .normal)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = device?.name ?? "Device"
        bluetoothManager.bluetoothDelegate = self
        setupBackButton()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bluetoothManager.bluetoothDelegate = self

        if let savedUUID = SharedPreferenceManager.shared.getSavedDeviceUUID(),
           let currentDevice = device,
           savedUUID == currentDevice.deviceUuid {
            onConnectionStateChange(bluetoothManager.deviceConnectionState)
        } else {
            onConnectionStateChange(.disconnected)
        }
    }

    private func setupUI() {
        view.addSubview(connectionLabel)
        view.addSubview(connectButton)

        view.addSubview(sendDataButton)

        NSLayoutConstraint.activate([
            connectionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectionLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),

            connectButton.topAnchor.constraint(equalTo: connectionLabel.bottomAnchor, constant: 20),
            connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectButton.widthAnchor.constraint(equalToConstant: 140),
            connectButton.heightAnchor.constraint(equalToConstant: 50),

            sendDataButton.topAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: 20),
            sendDataButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sendDataButton.widthAnchor.constraint(equalToConstant: 140),
            sendDataButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        connectButton.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)

        sendDataButton.addTarget(self, action: #selector(sendDataTapped), for: .touchUpInside)
    }
    private func setupBackButton() {
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.setTitle(" Back", for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        backButton.tintColor = .label
        backButton.backgroundColor = UIColor.systemGray5
        backButton.layer.cornerRadius = 18
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        backButton.layer.shadowColor = UIColor.black.cgColor
        backButton.layer.shadowOpacity = 0.2
        backButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        backButton.layer.shadowRadius = 2
        
        view.addSubview(backButton)
        
        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            backButton.heightAnchor.constraint(equalToConstant: 36),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12)
        ])
    }
    @objc private func connectButtonTapped() {
        guard let device = device else { return }
        if bluetoothManager.deviceConnectionState == .connected {
            bluetoothManager.disconnect(from: device)
        } else {
            bluetoothManager.connect(to: device)
        }
    }

    
    @objc private func sendDataTapped() {
        guard let device = device else { return }
        guard bluetoothManager.deviceConnectionState == .connected else { return }
        
        let angles: [Int] = [
            2048, 1585, 2048, 2428,
            2048, 2355,  3000, 2965,
            2048, 2506, 2048, 1662,
            2048, 1740,  819, 1126
        ]

//        if let commandData = encodeMultiServoCommand(angles: angles) {
//            bluetoothManager.sendData(commandData, to: device)
//        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            var updatedAngles = angles
            let temp = updatedAngles[6]
            updatedAngles[6] = 400   // motor/servo 7
            if let commandData = self.encodeMultiServoCommand(
                angles: updatedAngles
            ) {
                self.bluetoothManager.sendData(commandData, to: device)
            }
            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
//                updatedAngles[6] = temp
//                if let commandData = self.encodeMultiServoCommand(
//                    angles: updatedAngles
//                ) {
//                    self.bluetoothManager.sendData(commandData, to: device)
//                }
//            })
        }
    }
    
    func encodeMultiServoCommand(angles: [Int]) -> Data? {
        guard angles.count == 16 else {
            print("ERROR: Must provide exactly 16 servo angles. Got \(angles.count)")
            return nil
        }
        
        for (index, angle) in angles.enumerated() {
            guard (0...3600).contains(angle) else {
                print("ERROR: Servo \(index + 1) angle \(angle) is out of range (0–3600)")
                return nil
            }
        }
        
        print("Sending Angles: \(angles)")
        
        var data = Data()
        
        data.append(UInt8(ascii: "M"))
        data.append(UInt8(ascii: "V"))
        data.append(UInt8(ascii: "S"))
        
        for angle in angles {
            let msb = UInt8((angle >> 8) & 0xFF) // high byte
            let lsb = UInt8(angle & 0xFF)        // low byte
//            print("msb: \(msb), lsb: \(lsb) \n\n")
            data.append(msb)
            data.append(lsb)
        }

        
        data.append(UInt8(ascii: "E"))
        data.append(UInt8(ascii: "R"))
        
//        let hexString = data.map { String(format: "%d", $0) }.joined(separator: " ")
//        print("Encoded Command (37 bytes) → HEX: \(hexString)")
//        
        return data
    }
    
    @objc private func backButtonTapped() {
        if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        } else if navigationController != nil {
            navigationController?.popViewController(animated: true)
        } else {
            removeFromParent()
            view.removeFromSuperview()
        }
    }

    func encodeCommand(_ cmd: String) -> Data {
        return cmd.data(using: .utf8) ?? Data()
    }
    func onDeviceChange(_ devices: [BLEDevice]) {
        //N.A
    }

    func onScanningStateChange(_ isScanning: Bool) {
        //N.A
    }

    func onConnectionStateChange(_ connectionState: ConnectionState) {
        DispatchQueue.main.async {
            switch connectionState {

            case .connecting:
                self.connectionLabel.text = "Connecting..."
                self.connectionLabel.textColor = .systemOrange
                self.connectButton.setTitle("Please wait...", for: .normal)
                self.connectButton.backgroundColor = .systemOrange
                self.connectButton.tintColor = .white
                self.connectButton.isEnabled = false
                self.connectButton.alpha = 0.5

                self.sendDataButton.isEnabled = false
                self.sendDataButton.alpha = 0.5

            case .disconnecting:
                self.connectionLabel.text = "Disconnecting..."
                self.connectionLabel.textColor = .systemOrange
                self.connectButton.setTitle("Please wait...", for: .normal)
                self.connectButton.backgroundColor = .systemOrange
                self.connectButton.tintColor = .white
                self.connectButton.isEnabled = false
                self.connectButton.alpha = 0.5

                self.sendDataButton.isEnabled = false
                self.sendDataButton.alpha = 0.5

            case .connected:
                self.connectionLabel.text = "Connected"
                self.connectionLabel.textColor = .systemGreen
                self.connectButton.setTitle("Disconnect", for: .normal)
                self.connectButton.backgroundColor = .systemRed
                self.connectButton.tintColor = .white
                self.connectButton.isEnabled = true
                self.connectButton.alpha = 1.0

                self.sendDataButton.isEnabled = true
                self.sendDataButton.alpha = 1.0

            case .disconnected, .failed, .unKnownError:
                self.connectionLabel.text = "Disconnected"
                self.connectionLabel.textColor = .systemRed
                self.connectButton.setTitle("Connect", for: .normal)
                self.connectButton.backgroundColor = .systemGreen
                self.connectButton.tintColor = .white
                self.connectButton.isEnabled = true
                self.connectButton.alpha = 1.0

                self.sendDataButton.isEnabled = false
                self.sendDataButton.alpha = 0.5
            }
        }
    }
}
