//
//  MainScreen.swift
//  PoseFinder
//
//  Created by iOS Dev on 12/12/25.
//  Copyright © 2025 Apple. All rights reserved.
//


import UIKit
import CoreBluetooth

class BlueToothScreen: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let bluetoothManager = BlueToothManager.shared
    var devices: [BLEDevice] = []

    let tableView = UITableView()
    let reloadButton = UIButton(type: .system)
    let backButton = UIButton(type: .system)
    
    var connectedDeviceUUID: UUID? {
        return SharedPreferenceManager.shared.getSavedDeviceUUID()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Bluetooth"
        navigationItem.backButtonTitle = "Back"
        bluetoothManager.bluetoothDelegate = self
        setupBackButton()
        setupTableView()
        setupReloadButton()
        bluetoothManager.disconnectAllDevices()
        if bluetoothManager.centralManager.state == .poweredOn {
            bluetoothManager.startScanning()
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bluetoothManager.bluetoothDelegate = self
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    private func setupReloadButton() {
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        reloadButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        reloadButton.backgroundColor = .systemBlue
        reloadButton.tintColor = .white
        reloadButton.layer.cornerRadius = 28
        reloadButton.layer.shadowColor = UIColor.black.cgColor
        reloadButton.layer.shadowOpacity = 0.3
        reloadButton.layer.shadowOffset = CGSize(width: 2, height: 2)
        reloadButton.layer.shadowRadius = 4
        reloadButton.addTarget(self, action: #selector(reloadTapped), for: .touchUpInside)
        view.addSubview(reloadButton)

        NSLayoutConstraint.activate([
            reloadButton.widthAnchor.constraint(equalToConstant: 56),
            reloadButton.heightAnchor.constraint(equalToConstant: 56),
            reloadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            reloadButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
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

   
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor
                .constraint(equalTo: backButton.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DeviceCell.self, forCellReuseIdentifier: "DeviceCell")
        tableView.tableFooterView = UIView()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        devices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let device = devices[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath) as! DeviceCell
        
        let isConnected = device.deviceUuid == connectedDeviceUUID && bluetoothManager.deviceConnectionState == .connected
        cell.configure(with: device, isConnected: isConnected)
        return cell
    }


    /// table click listner
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let device = devices[indexPath.row]
        
        if !bluetoothManager.scanningState {
            let connectVC = DeviceConnectScreen()
            connectVC.device = device
            connectVC.modalPresentationStyle = .fullScreen
            present(connectVC, animated: true) {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
    @objc private func reloadTapped() {
        if !bluetoothManager.scanningState {
            bluetoothManager.startScanning()
        }
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
}

/// delicate change observer
extension BlueToothScreen: BlueToothManagerDelegate {
    func onConnectionStateChange(_ connectionState: ConnectionState) {
        if connectionState != .connected {
            SharedPreferenceManager.shared.clearConnectedDevice()
            self.tableView.reloadData()
        }
    }

    func onScanningStateChange(_ isScanning: Bool) {
        DispatchQueue.main.async {
            self.reloadButton.isEnabled = !isScanning
            self.reloadButton.backgroundColor = isScanning ? .lightGray : .systemBlue
        }
    }
    func onDeviceChange(_ devices: [BLEDevice]) {
        self.devices = devices.sorted { $0.rssi > $1.rssi }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
}
/// Custom cell for BLE device
class DeviceCell: UITableViewCell {
    let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        contentView.backgroundColor = UIColor.systemGray5
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    func configure(with device: BLEDevice, isConnected: Bool) {
        nameLabel.text = "\(device.name) | RSSI: \(device.rssi)"
        contentView.backgroundColor = isConnected ? UIColor.systemGreen.withAlphaComponent(0.5) : UIColor.systemGray5
    }
}
