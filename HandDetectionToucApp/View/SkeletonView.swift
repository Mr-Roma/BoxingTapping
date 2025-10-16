//
//  SkeletonView.swift
//  HandDetectionToucApp
//
//  Created by Romario Marcal on 16/10/25.
//

import UIKit
import Vision

class SkeletonOverlayView: UIView {
    
    private var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    
    // Styling properties
    var jointColor: UIColor = .green
    var boneColor: UIColor = .yellow
    var jointRadius: CGFloat = 8
    var boneWidth: CGFloat = 3
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    // Update skeleton with new joint positions
    func updateSkeleton(joints: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        self.joints = joints
        setNeedsDisplay()
    }
    
    // Clear skeleton
    func clearSkeleton() {
        joints.removeAll()
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Draw bones (connections between joints)
        drawBones(context: context)
        
        // Draw joints on top
        drawJoints(context: context)
    }
    
    private func drawBones(context: CGContext) {
        context.setStrokeColor(boneColor.cgColor)
        context.setLineWidth(boneWidth)
        context.setLineCap(.round)
        
        // Define bone connections (pairs of joints)
        let boneConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
            // Head
            (.nose, .neck),
            (.leftEye, .nose),
            (.rightEye, .nose),
            (.leftEar, .leftEye),
            (.rightEar, .rightEye),
            
            // Torso
            (.neck, .leftShoulder),
            (.neck, .rightShoulder),
            (.leftShoulder, .leftHip),
            (.rightShoulder, .rightHip),
            (.leftHip, .rightHip),
            (.leftHip, .root),
            (.rightHip, .root),
            
            // Left arm
            (.leftShoulder, .leftElbow),
            (.leftElbow, .leftWrist),
            
            // Right arm
            (.rightShoulder, .rightElbow),
            (.rightElbow, .rightWrist),
            
            // Left leg
            (.leftHip, .leftKnee),
            (.leftKnee, .leftAnkle),
            
            // Right leg
            (.rightHip, .rightKnee),
            (.rightKnee, .rightAnkle)
        ]
        
        // Draw each connection
        for (startJoint, endJoint) in boneConnections {
            guard let startPoint = joints[startJoint],
                  let endPoint = joints[endJoint] else {
                continue
            }
            
            context.move(to: startPoint)
            context.addLine(to: endPoint)
            context.strokePath()
        }
    }
    
    private func drawJoints(context: CGContext) {
        context.setFillColor(jointColor.cgColor)
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(2)
        
        for (_, point) in joints {
            let rect = CGRect(
                x: point.x - jointRadius,
                y: point.y - jointRadius,
                width: jointRadius * 2,
                height: jointRadius * 2
            )
            
            context.fillEllipse(in: rect)
            context.strokeEllipse(in: rect)
        }
    }
}
