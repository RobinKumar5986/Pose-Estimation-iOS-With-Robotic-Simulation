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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        UIApplication.shared.isIdleTimerDisabled = true
        
        setupHorizontalSplit()
        setupPoseNet()
        setupAndBeginCapturingVideoFrames()
        setupButtonsAppearance()

    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bringButtonsToFront()
    }
    private func setupButtonsAppearance() {
            
        configurationButton.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        
        // MARK: - Configuration Button (Bottom-Center, Text Only)
        configurationButton.setTitle("Set Config", for: .normal)
        configurationButton.setTitleColor(.white, for: .normal)
        configurationButton.backgroundColor = .clear
        configurationButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        configurationButton.layer.cornerRadius = 8
        configurationButton.layer.shadowColor = UIColor.black.cgColor
        configurationButton.layer.shadowOpacity = 0.5
        configurationButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        configurationButton.layer.shadowRadius = 4
        
        // Remove imageEdgeInsets since it has no image
        configurationButton.imageEdgeInsets = .zero
        
        // MARK: - Camera Button (Top-Right)
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

        // MARK: - Constraints
        NSLayoutConstraint.activate([
            
            // Camera button – Top Right
            cameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cameraButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cameraButton.widthAnchor.constraint(equalToConstant: 56),
            cameraButton.heightAnchor.constraint(equalToConstant: 56),
            
            // Configuration button – Bottom Center
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
            // Top Half: Camera Feed + Pose Overlay
            previewImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            previewImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),

            // Bottom Half: 3D Simulation
            simulate3D.view.topAnchor.constraint(equalTo: previewImageView.bottomAnchor),
            simulate3D.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            simulate3D.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            simulate3D.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        bringButtonsToFront()
    }
    
    private func bringButtonsToFront() {
        if let cameraButton = cameraButton {
            view.bringSubviewToFront(cameraButton)
        }
        if let configButton = configurationButton {
            view.bringSubviewToFront(configButton)
        }

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
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
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
            print("----- ANGLES FOR CURRENT FRAME -----")
            for (joint, angle) in firstAngles {
                print("\(joint): \(angle)")
            }
            print("------------------------------------")
            
            DispatchQueue.main.async {
                self.simulate3D.updateWithAngles(firstAngles)
            }
        }
    }
}

// MARK: - Angle Utils (Corrected for 0° to 360° Range)
extension PoseBuilder {
    /// Calculates the directional angle (in degrees) from the vector BA to the vector BC,
    /// where B is the vertex, giving a result in the range [0, 360).
    func angle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
        // Vector 1: BA (from vertex b to point a)
        let v1 = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        // Vector 2: BC (from vertex b to point c)
        let v2 = CGVector(dx: c.x - b.x, dy: c.y - b.y)

        // 1. Calculate the angle of each vector relative to the positive x-axis using atan2
        // atan2(y, x) returns the angle in radians in the range (-π, π]
        let angle1 = atan2(v1.dy, v1.dx)
        let angle2 = atan2(v2.dy, v2.dx)

        // 2. Find the difference. The angle is calculated counter-clockwise from v1 to v2.
        var radians = angle2 - angle1

        // 3. Normalize the angle to be in the range [0, 2π)
        if radians < 0 {
            radians += 2 * .pi
        }

        // 4. Convert radians to degrees
        return radians * 180 / .pi
    }
}

// The computeAngles function remains valid, as it correctly uses the joints (A, B, C)
// and relies on the updated angle function for the calculation.
extension PoseBuilder {
    func computeAngles(for pose: Pose) -> [String: CGFloat] {
        var angles: [String: CGFloat] = [:]

        func p(_ joint: Joint.Name) -> CGPoint? {
            pose.joints[joint]?.position
        }

        // The angle function defined in the first extension is the one that is used here.
        // It now calculates the directional angle [0, 360).

        // Left Shoulder Angle (Vertex: Left Shoulder, Angle from Hip-Shoulder to Elbow-Shoulder)
        if let h = p(.leftHip), let s = p(.leftShoulder), let e = p(.leftElbow) {
            // (A=h, B=s, C=e) -> Angle from BA (Hip->Shoulder) to BC (Elbow->Shoulder)
            angles["leftShoulder"] = angle(h, s, e)
        }
        
        // Right Shoulder Angle (Vertex: Right Shoulder, Angle from Hip-Shoulder to Elbow-Shoulder)
        if let h = p(.rightHip), let s = p(.rightShoulder), let e = p(.rightElbow) {
            angles["rightShoulder"] = angle(h, s, e)
        }

        // Left Elbow Angle (Vertex: Left Elbow, Angle from Shoulder-Elbow to Wrist-Elbow)
        if let s = p(.leftShoulder), let e = p(.leftElbow), let w = p(.leftWrist) {
            // (A=s, B=e, C=w) -> Angle from BA (Shoulder->Elbow) to BC (Wrist->Elbow)
            angles["leftElbow"] = angle(s, e, w)
        }
        
        // Right Elbow Angle (Vertex: Right Elbow, Angle from Shoulder-Elbow to Wrist-Elbow)
        if let s = p(.rightShoulder), let e = p(.rightElbow), let w = p(.rightWrist) {
            angles["rightElbow"] = angle(s, e, w)
        }

        // Left Hip Angle (Vertex: Left Hip, Angle from Shoulder-Hip to Knee-Hip)
        if let s = p(.leftShoulder), let h = p(.leftHip), let k = p(.leftKnee) {
            // (A=s, B=h, C=k) -> Angle from BA (Shoulder->Hip) to BC (Knee->Hip)
            angles["leftHip"] = angle(s, h, k)
        }
        
        // Right Hip Angle (Vertex: Right Hip, Angle from Shoulder-Hip to Knee-Hip)
        if let s = p(.rightShoulder), let h = p(.rightHip), let k = p(.rightKnee) {
            angles["rightHip"] = angle(s, h, k)
        }

        // Left Knee Angle (Vertex: Left Knee, Angle from Hip-Knee to Ankle-Knee)
        if let h = p(.leftHip), let k = p(.leftKnee), let a = p(.leftAnkle) {
            // (A=h, B=k, C=a) -> Angle from BA (Hip->Knee) to BC (Ankle->Knee)
            angles["leftKnee"] = angle(h, k, a)
        }
        
        // Right Knee Angle (Vertex: Right Knee, Angle from Hip-Knee to Ankle-Knee)
        if let h = p(.rightHip), let k = p(.rightKnee), let a = p(.rightAnkle) {
            angles["rightKnee"] = angle(h, k, a)
        }

        return angles
    }
}
