//
//  Simulate3D.swift
//  PoseFinder
//
//  Created by iOS Dev on 01/12/25.
//  Copyright © 2025 Apple. All rights reserved.
//

import SceneKit
import UIKit

class Simulate3D: UIViewController {

    private var gameView: SCNView!
    private var gameScene: SCNScene!
    private var cameraNode: SCNNode!
    private var bodyNode: SCNNode!

    private var leftShoulder: SCNNode!
    private var leftElbow: SCNNode!
    private var rightShoulder: SCNNode!
    private var rightElbow: SCNNode!
    private var leftHip: SCNNode!
    private var leftKnee: SCNNode!
    private var rightHip: SCNNode!
    private var rightKnee: SCNNode!
    private var bluetoothManager = BlueToothManager.shared
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        createRobot()
    }

    private func setupScene() {
        gameView = SCNView()
        gameView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        gameView.allowsCameraControl = true
        gameView.autoenablesDefaultLighting = true
        view = gameView

        gameScene = SCNScene()
        gameView.scene = gameScene
        gameView.isPlaying = true

        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 3, 10)
        gameScene.rootNode.addChildNode(cameraNode)
    }

    private func createRobot() {
        bodyNode = node(
            box: SCNBox(width: 2, height: 3, length: 1, chamferRadius: 0),
            color: .gray,
            pos: SCNVector3(0, 3, 0)
        )
        gameScene.rootNode.addChildNode(bodyNode)
        bodyNode.rotation = SCNVector4(0, 1, 0, Float.pi)

        bodyNode.addChildNode(
            node(
                sphere: SCNSphere(radius: 0.6),
                color: .yellow,
                pos: SCNVector3(0, 2, 0)
            )
        )

        leftShoulder = joint(color: .red, pos: SCNVector3(-1.5, 1.2, 0))
        bodyNode.addChildNode(leftShoulder)
        leftShoulder.addChildNode(limb(length: 1.5, color: .blue))
        leftElbow = joint(color: .green, pos: SCNVector3(0, -0.8, 0))
        leftShoulder.childNodes.last!.addChildNode(leftElbow)
        leftElbow.addChildNode(limb(length: 1.2, color: .cyan))

        rightShoulder = joint(color: .red, pos: SCNVector3(1.5, 1.2, 0))
        bodyNode.addChildNode(rightShoulder)
        rightShoulder.addChildNode(limb(length: 1.5, color: .blue))
        rightElbow = joint(color: .green, pos: SCNVector3(0, -0.8, 0))
        rightShoulder.childNodes.last!.addChildNode(rightElbow)
        rightElbow.addChildNode(limb(length: 1.2, color: .cyan))

        leftHip = joint(color: .orange, pos: SCNVector3(-0.6, -1.5, 0))
        bodyNode.addChildNode(leftHip)
        leftHip.addChildNode(limb(length: 1.7, color: .purple))
        leftKnee = joint(color: .brown, pos: SCNVector3(0, -0.9, 0))
        leftHip.childNodes.last!.addChildNode(leftKnee)
        leftKnee.addChildNode(limb(length: 1.5, color: .magenta))

        rightHip = joint(color: .orange, pos: SCNVector3(0.6, -1.5, 0))
        bodyNode.addChildNode(rightHip)
        rightHip.addChildNode(limb(length: 1.7, color: .purple))
        rightKnee = joint(color: .brown, pos: SCNVector3(0, -0.9, 0))
        rightHip.childNodes.last!.addChildNode(rightKnee)
        rightKnee.addChildNode(limb(length: 1.5, color: .magenta))
    }

    private func node(sphere: SCNSphere, color: UIColor, pos: SCNVector3)
        -> SCNNode
    {
        sphere.firstMaterial?.diffuse.contents = color
        let node = SCNNode(geometry: sphere)
        node.position = pos
        return node
    }

    private func node(box: SCNBox, color: UIColor, pos: SCNVector3) -> SCNNode {
        box.firstMaterial?.diffuse.contents = color
        let node = SCNNode(geometry: box)
        node.position = pos
        return node
    }

    private func joint(color: UIColor, pos: SCNVector3) -> SCNNode {
        let node = SCNNode(geometry: SCNSphere(radius: 0.4))
        node.geometry?.firstMaterial?.diffuse.contents = color
        node.position = pos
        return node
    }

    private func limb(length: CGFloat, color: UIColor) -> SCNNode {
        let box = SCNBox(
            width: 0.5,
            height: length,
            length: 0.5,
            chamferRadius: 0.1
        )
        box.firstMaterial?.diffuse.contents = color
        let node = SCNNode(geometry: box)
        node.position = SCNVector3(0, -length / 2, 0)
        return node
    }

    func updateWithAngles(
        _ angles: [String: CGFloat],
        isFrontCamera: Bool = false
    ) {
        let zero: CGFloat = 0

        // Initial extraction
        var lShoulderAbduction = angles["leftShoulder_Abduction_Proxy"] ?? zero
        var rShoulderAbduction = angles["rightShoulder_Abduction_Proxy"] ?? zero

        let leftValid = (angles["leftShoulder_Abduction_Valid"] ?? 0.0) == 1.0
        let rightValid = (angles["rightShoulder_Abduction_Valid"] ?? 0.0) == 1.0

        let lShoulder = angles["leftShoulder"] ?? zero
        let rShoulder = angles["rightShoulder"] ?? zero
        var lElbow = angles["leftElbow"] ?? zero
        var rElbow = angles["rightElbow"] ?? zero

        var lHip = angles["leftHip"] ?? zero
        var rHip = angles["rightHip"] ?? zero
        let lKnee = angles["leftKnee"] ?? zero
        let rKnee = angles["rightKnee"] ?? zero

        let quick: TimeInterval = 0.03  //Smooth but fast update

        func applyRotationAction(
            to node: SCNNode?,
            angleDegrees: CGFloat,
            axis: SCNVector3,
            duration: TimeInterval = quick
        ) {
            guard let node = node else { return }

            let radians = Float(angleDegrees * .pi / 180.0)
            let rotationVector = SCNVector4(axis.x, axis.y, axis.z, radians)
            let action = SCNAction.rotate(
                toAxisAngle: rotationVector,
                duration: duration
            )
            action.timingMode = .easeOut

            node.runAction(action, forKey: "rotate")
        }
        if lElbow > 180 {
            lElbow = lElbow - 180
        } else {
            lElbow = 180 - lElbow
            lElbow = -1 * lElbow
        }
        if rElbow < 180 {
            rElbow = 180 - rElbow
            rElbow = -1 * rElbow
        } else {
            rElbow = 180 - rElbow
            rElbow = -1 * rElbow
        }
        lHip = 180 - lHip
        lHip = -lHip
        rHip = 180 - rHip
        rHip = -rHip

        sendData(
            leftShoulder: Int(rShoulder),
            leftElbow: Int(rElbow),
            rightShoulder: Int(lShoulder),
            rightElbow: Int(lElbow),
            rightHip: Int(lHip),
            leftHip: Int(rHip),
            isFrontCamera: isFrontCamera
        )
        ///note: for the robo left is right due to camera perception...

        //        let leftAbductionRotation = -lShoulderAbduction
        //        let rightAbductionRotation = rShoulderAbduction
        //
        // MARK: - Arms (Z-axis rotation)
        applyRotationAction(
            to: leftShoulder,
            angleDegrees: lShoulder,
            axis: SCNVector3(0, 0, 1)
        )
        applyRotationAction(
            to: leftElbow,
            angleDegrees: lElbow,
            axis: SCNVector3(0, 0, 1)
        )

        applyRotationAction(
            to: rightShoulder,
            angleDegrees: rShoulder,
            axis: SCNVector3(0, 0, 1)
        )
        applyRotationAction(
            to: rightElbow,
            angleDegrees: rElbow,
            axis: SCNVector3(0, 0, 1)
        )

        // MARK: - Legs (X-axis rotation) – matches startAnimation() perfectly
        applyRotationAction(
            to: leftHip,
            angleDegrees: lHip,
            axis: SCNVector3(0, 0, 1)
        )
        applyRotationAction(
            to: rightHip,
            angleDegrees: rHip,
            axis: SCNVector3(0, 0, 1)
        )
        //    applyRotationAction(to: leftKnee,  angleDegrees: 180 - lKnee, axis: SCNVector3(1, 0, 0))
        //    applyRotationAction(to: rightKnee, angleDegrees: 180 - rKnee, axis: SCNVector3(1, 0, 0))
    }
    private func sendData(
        leftShoulder: Int?,
        leftElbow: Int?,
        rightShoulder: Int?,
        rightElbow: Int?,
        rightHip: Int?,
        leftHip: Int?,
        isFrontCamera: Bool
    ) {
        if bluetoothManager.isCommandWritten {
            let minimumDelay: TimeInterval = 0.5
            
            if let lastSendTime = SharedPreferenceManager.shared.getLastServoCommandTime(),
               Date().timeIntervalSince(lastSendTime) < minimumDelay {
                return
            }
            
            guard let savedUUID = SharedPreferenceManager.shared.getSavedDeviceUUID() else { return }
            guard let device = bluetoothManager.getDevice(by: savedUUID) else { return }
            guard bluetoothManager.deviceConnectionState == .connected else { return }
            
            var angles: [Int] = [
                2048, 1585, 2048, 2428,
                2048, 2355, 500, 2965,
                2048, 2506, 2048, 1662,
                2048, 1740, 819, 1126,
            ]
            
            if !isFrontCamera {
                
                angles[6] = MapperHelper.mapBackCameraLeftSholder(rightShoulder ?? angles[6])
                angles[5] = MapperHelper.mapBackCameraLeftElbow(rightElbow ?? angles[5])
                
                angles[13] = MapperHelper.mapBackCameraRightElbow(leftElbow ?? angles[13])
                angles[14] = MapperHelper.mapBackCameraRightSholder(leftShoulder ?? angles[14])
                if let rightShoulder = rightShoulder, rightShoulder > 225 {
                    angles[4] = MapperHelper.mapBackCameraLeftHip(rightHip ?? angles[4])
                }
                if let leftShoulder = leftShoulder, leftShoulder > 45 {
                    angles[12] = MapperHelper.mapBackCameraRightHip(leftHip ?? angles[12])
                }
            } else {
                angles[6] = MapperHelper.mapLeftSolder(leftShoulder ?? angles[6])
                angles[5] = MapperHelper.mapLeftElbow(leftElbow ?? angles[5])
                
                angles[13] = MapperHelper.mapRightElbow(rightElbow ?? angles[13])
                angles[14] = MapperHelper.mapRightSolder(rightShoulder ?? angles[14])
                
                if let leftShoulder = leftShoulder, let leftHip = leftHip , leftShoulder >= leftHip {
                    angles[4] = MapperHelper.mapLeftHip(leftHip)
                }
                if let rightShoulder = rightShoulder,let rightHip = rightHip , rightShoulder >= (
                    180 + (-rightHip)
                ) {
                    angles[12] = MapperHelper.mapRightHip(rightHip )
                }
            }
            
            if let commandData = encodeMultiServoCommand(angles: angles) {
                bluetoothManager.sendData(commandData, to: device)
                SharedPreferenceManager.shared.saveLastServoCommandTime()
            }
        }
    }
    
    private func encodeMultiServoCommand(angles: [Int]) -> Data? {
        guard angles.count == 16 else {
            print(
                "ERROR: Must provide exactly 16 servo angles. Got \(angles.count)"
            )
            return nil
        }

        for (index, angle) in angles.enumerated() {
            guard (0...3600).contains(angle) else {
                print(
                    "ERROR: Servo \(index + 1) angle \(angle) is out of range (0–3600)"
                )
                return nil
            }
        }

        print("Sending Angles: \(angles)")

        var data = Data()

        data.append(UInt8(ascii: "M"))
        data.append(UInt8(ascii: "V"))
        data.append(UInt8(ascii: "S"))

        for angle in angles {
            let msb = UInt8((angle >> 8) & 0xFF)  // high byte
            let lsb = UInt8(angle & 0xFF)  // low byte
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

}
