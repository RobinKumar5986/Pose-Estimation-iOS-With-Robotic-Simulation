//
//  Simulate3D.swift
//  PoseFinder
//
//  Created by iOS Dev on 01/12/25.
//  Copyright © 2025 Apple. All rights reserved.
//

import UIKit
import SceneKit

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
        bodyNode = node(box: SCNBox(width: 2, height: 3, length: 1, chamferRadius: 0), color: .gray, pos: SCNVector3(0, 3, 0))
        gameScene.rootNode.addChildNode(bodyNode)
        bodyNode.rotation = SCNVector4(0, 1, 0, Float.pi)
        
        bodyNode.addChildNode(node(sphere: SCNSphere(radius: 0.6), color: .yellow, pos: SCNVector3(0, 2, 0)))
        
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
    
    private func node(sphere: SCNSphere, color: UIColor, pos: SCNVector3) -> SCNNode {
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
        let box = SCNBox(width: 0.5, height: length, length: 0.5, chamferRadius: 0.1)
        box.firstMaterial?.diffuse.contents = color
        let node = SCNNode(geometry: box)
        node.position = SCNVector3(0, -length/2, 0)
        return node
    }
    
    func updateWithAngles(_ angles: [String: CGFloat]) {
        let zero: CGFloat = 0
        let lShoulder = angles["leftShoulder"] ?? zero
        let rShoulder = angles["rightShoulder"] ?? zero
        var lElbow = angles["leftElbow"] ?? zero
        var rElbow = angles["rightElbow"] ?? zero
        
        
        let lHip = angles["leftHip"] ?? zero
        let rHip = angles["rightHip"] ?? zero
        let lKnee = angles["leftKnee"] ?? zero
        let rKnee = angles["rightKnee"] ?? zero
        
        let leftDir: CGFloat = -1
        let quick: TimeInterval = 0.03  //Smooth but fast update
        
        func applyRotationAction(to node: SCNNode?, angleDegrees: CGFloat, axis: SCNVector3, duration: TimeInterval = quick) {
            guard let node = node else { return }
            
            let radians = Float(angleDegrees * .pi / 180.0)
            let rotationVector = SCNVector4(axis.x, axis.y, axis.z, radians)
            let action = SCNAction.rotate(toAxisAngle: rotationVector, duration: duration)
            action.timingMode = .easeOut
            
            node.runAction(action, forKey: "rotate")
        }
        if(lElbow > 180){
            lElbow = lElbow - 180
        }else{
            lElbow = 180 - lElbow
            lElbow = -1 * lElbow
        }
        if(rElbow < 180){
            rElbow = 180 - rElbow
            rElbow = -1 * rElbow
        }else{
            rElbow = 180 - rElbow
            rElbow = -1 * rElbow
        }
        // MARK: - Arms (Z-axis rotation)
        applyRotationAction(to: leftShoulder,  angleDegrees: lShoulder , axis: SCNVector3(0, 0, 1))
        applyRotationAction(to: leftElbow,     angleDegrees: lElbow, axis: SCNVector3(0, 0, 1))

        applyRotationAction(to: rightShoulder, angleDegrees: rShoulder, axis: SCNVector3(0, 0, 1))
        applyRotationAction(to: rightElbow,    angleDegrees: rElbow , axis: SCNVector3(0, 0, 1))
        
        // MARK: - Legs (X-axis rotation) – matches startAnimation() perfectly
//        applyRotationAction(to: leftHip,   angleDegrees: 180 - lHip,  axis: SCNVector3(1, 0, 0))
//        applyRotationAction(to: rightHip,  angleDegrees: 180 - rHip,  axis: SCNVector3(1, 0, 0))
//        applyRotationAction(to: leftKnee,  angleDegrees: 180 - lKnee, axis: SCNVector3(1, 0, 0))
//        applyRotationAction(to: rightKnee, angleDegrees: 180 - rKnee, axis: SCNVector3(1, 0, 0))
    }
}
