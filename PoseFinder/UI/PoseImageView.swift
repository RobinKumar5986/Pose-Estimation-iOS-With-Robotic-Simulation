/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation details of a view that visualizes the detected poses.
*/

import UIKit

@IBDesignable
class PoseImageView: UIImageView {

    /// A data structure used to describe a visual connection between two joints.
    struct JointSegment {
        let jointA: Joint.Name
        let jointB: Joint.Name
    }

    /// An array of joint-pairs that define the lines of a pose's wireframe drawing.
    static let jointSegments = [
        // The connected joints that are on the left side of the body.
        JointSegment(jointA: .leftHip, jointB: .leftShoulder),
        JointSegment(jointA: .leftShoulder, jointB: .leftElbow),
        JointSegment(jointA: .leftElbow, jointB: .leftWrist),
        JointSegment(jointA: .leftHip, jointB: .leftKnee),
        JointSegment(jointA: .leftKnee, jointB: .leftAnkle),
        // The connected joints that are on the right side of the body.
        JointSegment(jointA: .rightHip, jointB: .rightShoulder),
        JointSegment(jointA: .rightShoulder, jointB: .rightElbow),
        JointSegment(jointA: .rightElbow, jointB: .rightWrist),
        JointSegment(jointA: .rightHip, jointB: .rightKnee),
        JointSegment(jointA: .rightKnee, jointB: .rightAnkle),
        // The connected joints that cross over the body.
        JointSegment(jointA: .leftShoulder, jointB: .rightShoulder),
        JointSegment(jointA: .leftHip, jointB: .rightHip)
    ]

    /// The width of the line connecting two joints.
    @IBInspectable var segmentLineWidth: CGFloat = 2
    /// The color of the line connecting two joints.
    @IBInspectable var segmentColor: UIColor = UIColor.systemTeal
    /// The radius of the circles drawn for each joint.
    @IBInspectable var jointRadius: CGFloat = 4
    /// The color of the circles drawn for each joint.
    @IBInspectable var jointColor: UIColor = UIColor.systemPink


    private func clearOldAngleLayers() {
        layer.sublayers?.removeAll(where: { $0 is CATextLayer })
    }


    // MARK: - Rendering methods

    /// Returns an image showing the detected poses.
    ///
    /// - parameters:
    ///     - poses: An array of detected poses.
    ///     - angles: Angle dictionary for each pose.
    ///     - frame: The image used to detect the poses and used as the background for the returned image.
    func show(poses: [Pose], angles: [[String: CGFloat]], on frame: CGImage) {
        
        clearOldAngleLayers()
        
        let dstImageSize = CGSize(width: frame.width, height: frame.height)
        let dstImageFormat = UIGraphicsImageRendererFormat()
        
        dstImageFormat.scale = 1
        let renderer = UIGraphicsImageRenderer(size: dstImageSize,
                                               format: dstImageFormat)
        
        let dstImage = renderer.image { rendererContext in
            // Draw the current frame as the background for the new image.
            draw(image: frame, in: rendererContext.cgContext)
            
            for (index, pose) in poses.enumerated() {
                let angleDict = angles[index]
                
                // MARK: - Draw skeleton lines
                for segment in PoseImageView.jointSegments {
                    let jointA = pose[segment.jointA]
                    let jointB = pose[segment.jointB]
                    
                    guard jointA.isValid, jointB.isValid else { continue }
                    
                    drawLine(from: jointA,
                             to: jointB,
                             in: rendererContext.cgContext)
                }
                
                // MARK: - Draw joint circles
                for joint in pose.joints.values where joint.isValid {
                    draw(circle: joint, in: rendererContext.cgContext)
                }
                
                // Helper to get a joint position quickly
                func point(_ name: Joint.Name) -> CGPoint? {
                    pose.joints[name]?.position
                }
                
                // Offsets – tweak these if labels overlap too much
                let offsetX: CGFloat = -25
                let offsetY: CGFloat = -25
                
                // MARK: - Shoulder angles
                if let s = point(.leftShoulder), let angle = angleDict["leftShoulder"] {
                    drawAngle(text: "\(Int(angle))° Ls",
                              at: CGPoint(x: s.x + offsetX, y: s.y + offsetY),
                              jointName: "leftShoulder")
                }
                if let s = point(.rightShoulder), let angle = angleDict["rightShoulder"] {
                    drawAngle(text: "\(Int(angle))° Rs",
                              at: CGPoint(x: s.x + offsetX, y: s.y + offsetY),
                              jointName: "rightShoulder")
                }

                
                // MARK: - Elbow angles
                if let e = point(.leftElbow), let angle = angleDict["leftElbow"] {
                    drawAngle(text: "\(Int(angle))° Le",
                              at: CGPoint(x: e.x + offsetX, y: e.y + offsetY),
                              jointName: "leftElbow")
                }
                if let e = point(.rightElbow), let angle = angleDict["rightElbow"] {
                    drawAngle(text: "\(Int(angle))° Re",
                              at: CGPoint(x: e.x + offsetX, y: e.y + offsetY),
                              jointName: "rightElbow")
                }

                
                // MARK: - Hip angles
                if let h = point(.leftHip), let angle = angleDict["leftHip"] {
                    drawAngle(text: "\(Int(angle))° Lh",
                              at: CGPoint(x: h.x + offsetX, y: h.y + 40),
                              jointName: "leftHip")
                }
                if let h = point(.rightHip), let angle = angleDict["rightHip"] {
                    drawAngle(text: "\(Int(angle))° Rh",
                              at: CGPoint(x: h.x + offsetX, y: h.y + 40),
                              jointName: "rightHip")
                }

                
                // MARK: - Knee angles
                if let k = point(.leftKnee), let angle = angleDict["leftKnee"] {
                    drawAngle(text: "\(Int(angle))° Ln",
                              at: CGPoint(x: k.x + offsetX, y: k.y + 45),
                              jointName: "leftKnee")
                }
                if let k = point(.rightKnee), let angle = angleDict["rightKnee"] {
                    drawAngle(text: "\(Int(angle))° Rn",
                              at: CGPoint(x: k.x + offsetX, y: k.y + 45),
                              jointName: "rightKnee")
                }
                
                // MARK: - Shoulder Abduction Proxy angles (YZ plane inference – shown in GREEN)
                if let s = point(.leftShoulder), let proxyAngle = angleDict["leftShoulder_Abduction_Proxy"] {
                    drawAngle(text: "\(Int(proxyAngle))° Lyz",
                              at: CGPoint(x: s.x + offsetX, y: s.y + offsetY - 50),
                              jointName: "leftShoulder",
                              color: .green)
                }
                if let s = point(.rightShoulder), let proxyAngle = angleDict["rightShoulder_Abduction_Proxy"] {
                    drawAngle(text: "\(Int(proxyAngle))° Ryz",
                              at: CGPoint(x: s.x + offsetX, y: s.y + offsetY - 50),
                              jointName: "rightShoulder",
                              color: .green)
                }
                
            }
        }
        
        image = dstImage
    }

    /// Vertically flips and draws the given image.
    ///
    /// - parameters:
    ///     - image: The image to draw onto the context (vertically flipped).
    ///     - cgContext: The rendering context.
    func draw(image: CGImage, in cgContext: CGContext) {
        cgContext.saveGState()
        // The given image is assumed to be upside down; therefore, the context
        // is flipped before rendering the image.
        cgContext.scaleBy(x: 1.0, y: -1.0)
        // Render the image, adjusting for the scale transformation performed above.
        let drawingRect = CGRect(x: 0, y: -image.height, width: image.width, height: image.height)
        cgContext.draw(image, in: drawingRect)
        cgContext.restoreGState()
    }

    /// Draws a line between two joints.
    ///
    /// - parameters:
    ///     - parentJoint: A valid joint whose position is used as the start position of the line.
    ///     - childJoint: A valid joint whose position is used as the end of the line.
    ///     - cgContext: The rendering context.
    func drawLine(from parentJoint: Joint,
                  to childJoint: Joint,
                  in cgContext: CGContext) {
        cgContext.setStrokeColor(segmentColor.cgColor)
        cgContext.setLineWidth(segmentLineWidth)

        cgContext.move(to: parentJoint.position)
        cgContext.addLine(to: childJoint.position)
        cgContext.strokePath()
    }

    /// Draw a circle in the location of the given joint.
    ///
    /// - parameters:
    ///     - circle: A valid joint whose position is used as the circle's center.
    ///     - cgContext: The rendering context.
    private func draw(circle joint: Joint, in cgContext: CGContext) {
        cgContext.setFillColor(jointColor.cgColor)

        let rectangle = CGRect(x: joint.position.x - jointRadius, y: joint.position.y - jointRadius,
                               width: jointRadius * 2, height: jointRadius * 2)
        cgContext.addEllipse(in: rectangle)
        cgContext.drawPath(using: .fill)
    }

    func drawAngle(text: String,
                   at point: CGPoint,
                   jointName: String?,
                   color: UIColor = .red) {
        let textLayer = CATextLayer()
        textLayer.string = text
        textLayer.fontSize = 15
        textLayer.foregroundColor = color.cgColor
        textLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        
        let size = CGSize(width: 50, height: 24)

        var yOffset: CGFloat = 80

        if let name = jointName,
           name == "leftHip" || name == "rightHip" ||
           name == "leftKnee" || name == "rightKnee" {
            yOffset = 120
        }

        textLayer.frame = CGRect(
            x: point.x - size.width / 2,
            y: point.y - size.height / 2 - yOffset,
            width: size.width,
            height: size.height
        )

        layer.addSublayer(textLayer)
    }

}
