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

        let cmd1 = "PLAY"
        bluetoothManager.sendData(encodeCommand(cmd1), to: device)
        print("Sent → \(cmd1)")

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {

            let cmd2 = "Rd1"
            self.bluetoothManager.sendData(self.encodeCommand(cmd2), to: device)
            print("Sent → \(cmd2)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {

                let cmd2 = "Rd0"
                self.bluetoothManager.sendData(self.encodeCommand(cmd2), to: device)
                print("Sent → \(cmd2)")
            }
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
