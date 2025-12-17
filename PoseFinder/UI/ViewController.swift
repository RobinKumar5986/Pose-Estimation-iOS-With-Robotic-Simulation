/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the application's view controller, responsible for coordinating
 the user interface, video feed, and PoseNet model.
*/

import AVFoundation
import UIKit
import VideoToolbox
import SceneKit

class ViewController: UIViewController {
    /// The view the controller uses to visualize the detected poses.
    @IBOutlet private var previewImageView: PoseImageView!
    
    private let videoCapture = VideoCapture()
    private var poseNet: PoseNet!
    private var currentFrame: CGImage?
    private var algorithm: Algorithm = .multiple
    private var poseBuilderConfiguration = PoseBuilderConfiguration()
    private var popOverPresentationManager: PopOverPresentationManager?

    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var configurationButton: UIButton!
    
    private lazy var simulate3D = Simulate3D()
    
    let blueToothManager = BlueToothManager.shared
    
    private lazy var bluetoothButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "externaldrive.connected.to.line.below.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .clear
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(onBluetoothButtonTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        UIApplication.shared.isIdleTimerDisabled = true
        blueToothManager.bluetoothDelegate = self
        setupHorizontalSplit()
        setupPoseNet()
        setupAndBeginCapturingVideoFrames()
        setupButtonsAppearance()
        setupBluetoothButton()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bringButtonsToFront()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bringButtonsToFront()
    }
    
    private func setupButtonsAppearance() {
        configurationButton.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        
        configurationButton.setTitle("Set Config", for: .normal)
        configurationButton.setTitleColor(.white, for: .normal)
        configurationButton.backgroundColor = .clear
        configurationButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        configurationButton.layer.cornerRadius = 8
        configurationButton.layer.shadowColor = UIColor.black.cgColor
        configurationButton.layer.shadowOpacity = 0.5
        configurationButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        configurationButton.layer.shadowRadius = 4
        configurationButton.imageEdgeInsets = .zero
        
        cameraButton.setImage(UIImage(systemName: "camera.rotate.fill"), for: .normal)
        cameraButton.tintColor = .white
        cameraButton.backgroundColor = .clear
        cameraButton.layer.cornerRadius = 28
        cameraButton.layer.shadowColor = UIColor.black.cgColor
        cameraButton.layer.shadowOpacity = 0.5
        cameraButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        cameraButton.layer.shadowRadius = 4
        cameraButton.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        view.addSubview(configurationButton)
        view.addSubview(cameraButton)

        NSLayoutConstraint.activate([
            cameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cameraButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cameraButton.widthAnchor.constraint(equalToConstant: 56),
            cameraButton.heightAnchor.constraint(equalToConstant: 56),
            
            configurationButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            configurationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            configurationButton.heightAnchor.constraint(equalToConstant: 44),
            configurationButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 140)
        ])
    }

    private func setupHorizontalSplit() {
        addChild(simulate3D)
        view.addSubview(simulate3D.view)
        simulate3D.didMove(toParent: self)

        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        simulate3D.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            previewImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            previewImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),

            simulate3D.view.topAnchor.constraint(equalTo: previewImageView.bottomAnchor),
            simulate3D.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            simulate3D.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            simulate3D.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        bringButtonsToFront()
    }
    
    private func bringButtonsToFront() {
        view.bringSubviewToFront(cameraButton)
        view.bringSubviewToFront(bluetoothButton)
        view.bringSubviewToFront(configurationButton)
    }
    
    private func setupBluetoothButton() {
        view.addSubview(bluetoothButton)
        NSLayoutConstraint.activate([
            bluetoothButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -35),
            bluetoothButton.topAnchor.constraint(equalTo: cameraButton.bottomAnchor, constant: 0),
            bluetoothButton.widthAnchor.constraint(equalToConstant: 56),
            bluetoothButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func setupPoseNet() {
        do {
            poseNet = try PoseNet()
            poseNet.delegate = self
        } catch {
            fatalError("Failed to load model. \(error.localizedDescription)")
        }
    }
    
    private func setupAndBeginCapturingVideoFrames() {
        videoCapture.setUpAVCapture { error in
            if let error = error {
                print("Failed to setup camera with error \(error)")
                return
            }
            self.videoCapture.delegate = self
            self.videoCapture.startCapturing()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        videoCapture.stopCapturing {
            super.viewWillDisappear(animated)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        videoCapture.startCapturing()
        blueToothManager.bluetoothDelegate = self
        bringButtonsToFront()
    }
    
    override func viewWillTransition(to size: CGSize,
                                    with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.bringButtonsToFront()
        }
        setupAndBeginCapturingVideoFrames()
    }
    
    @IBAction func onCameraButtonTapped(_ sender: Any) {
        videoCapture.flipCamera { error in
            if let error = error {
                print("Failed to flip camera with error \(error)")
            }
        }
    }
    
    @IBAction func onAlgorithmSegmentValueChanged(_ sender: UISegmentedControl) {
        guard let selectedAlgorithm = Algorithm(rawValue: sender.selectedSegmentIndex) else {
            return
        }
        algorithm = selectedAlgorithm
    }
    
    @IBAction func onBluetoothButtonTapped(_ sender: UIButton) {
        let bluetoothScreen = BlueToothScreen()
        bluetoothScreen.modalPresentationStyle = .fullScreen
        present(bluetoothScreen, animated: true)
    }
}

// MARK: - Navigation
extension ViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let uiNavigationController = segue.destination as? UINavigationController else {
            return
        }
        guard let configurationViewController = uiNavigationController.viewControllers.first
            as? ConfigurationViewController else {
                    return
        }

        configurationViewController.configuration = poseBuilderConfiguration
        configurationViewController.algorithm = algorithm
        configurationViewController.delegate = self

        popOverPresentationManager = PopOverPresentationManager(presenting: self,
                                                                presented: uiNavigationController)
        segue.destination.modalPresentationStyle = .custom
        segue.destination.transitioningDelegate = popOverPresentationManager
    }
}

// MARK: - ConfigurationViewControllerDelegate
extension ViewController: ConfigurationViewControllerDelegate {
    func configurationViewController(_ viewController: ConfigurationViewController,
                                    didUpdateConfiguration configuration: PoseBuilderConfiguration) {
        poseBuilderConfiguration = configuration
    }

    func configurationViewController(_ viewController: ConfigurationViewController,
                                    didUpdateAlgorithm algorithm: Algorithm) {
        self.algorithm = algorithm
    }
}

// MARK: - VideoCaptureDelegate
extension ViewController: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCapture, didCaptureFrame capturedImage: CGImage?) {
        guard currentFrame == nil else {
            return
        }
        guard let image = capturedImage else {
            fatalError("Captured image is null")
        }

        currentFrame = image
        poseNet.predict(image)
    }
}

// MARK: - PoseNetDelegate
extension ViewController: PoseNetDelegate {
    func poseNet(_ poseNet: PoseNet, didPredict predictions: PoseNetOutput) {
        defer {
            self.currentFrame = nil
        }
        
        guard let currentFrame = currentFrame else { return }
        
        let poseBuilder = PoseBuilder(output: predictions,
                                      configuration: poseBuilderConfiguration,
                                      inputImage: currentFrame)
        
        let poses = algorithm == .single ? [poseBuilder.pose] : poseBuilder.poses
        let angles = poses.compactMap { poseBuilder.computeAngles(for: $0) }
        
        var singlePose: [Pose] = []
        if let first = poses.first {
            singlePose = [first]
        }
        
        previewImageView.show(poses: singlePose, angles: angles, on: currentFrame)
        
        if let firstAngles = angles.first {
            let isFrontCamera = videoCapture.currentCameraPosition == .front
//            print("Camera: \(isFrontCamera ? "Front (Selfie)" : "Back")")
//            print("----- ANGLES FOR CURRENT FRAME -----")
//            for (joint, angle) in firstAngles {
//                print("\(joint): \(angle)")
//            }
//            print("------------------------------------")
            
            DispatchQueue.main.async {
                self.simulate3D.updateWithAngles(firstAngles,isFrontCamera: isFrontCamera )
            }
        }
    }
}

// MARK: - Angle Utils (Corrected for 0° to 360° Range)
extension PoseBuilder {
    func angle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
        let v1 = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let v2 = CGVector(dx: c.x - b.x, dy: c.y - b.y)

        let angle1 = atan2(v1.dy, v1.dx)
        let angle2 = atan2(v2.dy, v2.dx)

        var radians = angle2 - angle1
        if radians < 0 {
            radians += 2 * .pi
        }

        return radians * 180 / .pi
    }
    
    private func limbDistance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
    }

    private func shoulderAbductionProxyAngle(hip: CGPoint, shoulder: CGPoint, wrist: CGPoint) -> CGFloat {
        return angle(hip, shoulder, wrist)
    }
    
    private func isProjectionValid(shoulder: CGPoint, elbow: CGPoint, wrist: CGPoint) -> Bool {
        let expectedRatio: CGFloat = 1.0
        let projectionTolerance: CGFloat = 0.2
        
        let upperArmLength = limbDistance(shoulder, elbow)
        let forearmLength = limbDistance(elbow, wrist)
        
        guard upperArmLength > 0.0 && forearmLength > 0.0 else { return false }
        
        let currentRatio = forearmLength / upperArmLength
        
        return abs(currentRatio - expectedRatio) <= projectionTolerance
    }
    
    func calculateShoulderAngleWithDepthInference(for pose: Pose) -> [String: Any] {
        var results: [String: Any] = [:]

        func getPoint(_ joint: Joint.Name) -> CGPoint? {
            pose.joints[joint]?.position
        }
        
        var leftValid = false
        var rightValid = false
        
        if let h = getPoint(.leftHip), let s = getPoint(.leftShoulder),
           let e = getPoint(.leftElbow), let w = getPoint(.leftWrist)
        {
            let proxyAngle = shoulderAbductionProxyAngle(hip: h, shoulder: s, wrist: w)
            let isValid = isProjectionValid(shoulder: s, elbow: e, wrist: w)
            let status = isValid ? "VALID" : "UNCERTAIN_DEPTH_ROTATION"
            
            leftValid = isValid
            
            results["leftShoulder_Abduction_Proxy"] = proxyAngle
            results["leftShoulder_Abduction_Status"] = status
            results["is_valid_left"] = isValid
            
    //        print("Left Shoulder YZ Proxy Angle: \(proxyAngle)°, Status: \(status)")
        }
        
        if let h = getPoint(.rightHip), let s = getPoint(.rightShoulder),
           let e = getPoint(.rightElbow), let w = getPoint(.rightWrist)
        {
            let proxyAngle = shoulderAbductionProxyAngle(hip: h, shoulder: s, wrist: w)
            let isValid = isProjectionValid(shoulder: s, elbow: e, wrist: w)
            let status = isValid ? "VALID" : "UNCERTAIN_DEPTH_ROTATION"
            
            rightValid = isValid
            
            results["rightShoulder_Abduction_Proxy"] = proxyAngle
            results["rightShoulder_Abduction_Status"] = status
            results["is_valid_right"] = isValid
            
    //        print("Right Shoulder YZ Proxy Angle: \(proxyAngle)°, Status: \(status)")
        }
        
        // Ensure boolean flags are always present even if joints are missing
        results["is_valid_left"] = leftValid
        results["is_valid_right"] = rightValid
        
        return results
    }
    
}

extension PoseBuilder {
    func computeAngles(for pose: Pose) -> [String: CGFloat] {
        var angles: [String: CGFloat] = [:]

        func p(_ joint: Joint.Name) -> CGPoint? {
            pose.joints[joint]?.position
        }

        let shoulderInference = calculateShoulderAngleWithDepthInference(for: pose)
        
        // Proxy angles
        if let leftProxyAngle = shoulderInference["leftShoulder_Abduction_Proxy"] as? CGFloat {
            angles["leftShoulder_Abduction_Proxy"] = leftProxyAngle
        }
        if let rightProxyAngle = shoulderInference["rightShoulder_Abduction_Proxy"] as? CGFloat {
            angles["rightShoulder_Abduction_Proxy"] = rightProxyAngle
        }
        
        // Validity flags as 1.0 (valid) or 0.0 (invalid)
        let leftValid = (shoulderInference["is_valid_left"] as? Bool) ?? false
        let rightValid = (shoulderInference["is_valid_right"] as? Bool) ?? false
        
        angles["leftShoulder_Abduction_Valid"] = leftValid ? 1.0 : 0.0
        angles["rightShoulder_Abduction_Valid"] = rightValid ? 1.0 : 0.0
        
        // Standard 2D angles
        if let h = p(.leftHip), let s = p(.leftShoulder), let e = p(.leftElbow) {
            angles["leftShoulder"] = angle(h, s, e)
        }
        if let h = p(.rightHip), let s = p(.rightShoulder), let e = p(.rightElbow) {
            angles["rightShoulder"] = angle(h, s, e)
        }
        if let s = p(.leftShoulder), let e = p(.leftElbow), let w = p(.leftWrist) {
            angles["leftElbow"] = angle(s, e, w)
        }
        if let s = p(.rightShoulder), let e = p(.rightElbow), let w = p(.rightWrist) {
            angles["rightElbow"] = angle(s, e, w)
        }
        if let s = p(.leftShoulder), let h = p(.leftHip), let k = p(.leftKnee) {
            angles["leftHip"] = angle(s, h, k)
        }
        if let s = p(.rightShoulder), let h = p(.rightHip), let k = p(.rightKnee) {
            angles["rightHip"] = angle(s, h, k)
        }
        if let h = p(.leftHip), let k = p(.leftKnee), let a = p(.leftAnkle) {
            angles["leftKnee"] = angle(h, k, a)
        }
        if let h = p(.rightHip), let k = p(.rightKnee), let a = p(.rightAnkle) {
            angles["rightKnee"] = angle(h, k, a)
        }

        return angles
    }
}

extension ViewController: BlueToothManagerDelegate {
    func onDeviceChange(_ devices: [BLEDevice]) {
        //TODO: ...
    }

    func onScanningStateChange(_ isScanning: Bool) {
        //TODO: ...
    }

    func onConnectionStateChange(_ connectionState: ConnectionState) {
        //TODO: ...
    }
}
