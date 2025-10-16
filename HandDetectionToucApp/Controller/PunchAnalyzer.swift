//
//  PunchAnalyzer.swift
//  HandDetectionToucApp
//
//  Created by Romario Marcal on 16/10/25.
//

// JAB characteristics:
// - Quick, short punch
// - More perpendicular to shoulders (forward)
// - Less rotation
// - Lead hand (for orthodox stance, left hand)

// STRAIGHT/CROSS characteristics:
// - Longer extension
// - More power, body rotation involved
// - Rear hand (for orthodox stance, right hand)
// - More hip rotation


import CoreGraphics
import Vision

class PunchAnalyzer {
    
    // Analyze punch type based on body pose and hand movement
    static func analyzePunchType(
        fistPoint: CGPoint,
        isLeftHand: Bool,
        bodyJoints: [VNHumanBodyPoseObservation.JointName: CGPoint],
        previousFistPoint: CGPoint?
    ) -> PunchType {
        
        guard let previousPoint = previousFistPoint else { return .unknown }
        
        // Get shoulder positions
        let shoulderJoint: VNHumanBodyPoseObservation.JointName = isLeftHand ? .leftShoulder : .rightShoulder
        let oppositeShoulderJoint: VNHumanBodyPoseObservation.JointName = isLeftHand ? .rightShoulder : .leftShoulder
        
        guard let shoulder = bodyJoints[shoulderJoint],
              let oppositeShoulder = bodyJoints[oppositeShoulderJoint] else {
            return .unknown
        }
        
        // Calculate punch vector
        let punchDeltaX = fistPoint.x - previousPoint.x
        let punchDeltaY = fistPoint.y - previousPoint.y
        
        // Calculate shoulder line angle (horizontal reference)
        let shoulderDeltaX = oppositeShoulder.x - shoulder.x
        let shoulderDeltaY = oppositeShoulder.y - shoulder.y
        
        // Calculate angle of punch relative to shoulder line
        let punchAngle = atan2(punchDeltaY, punchDeltaX)
        let shoulderAngle = atan2(shoulderDeltaY, shoulderDeltaX)
        
        // Get relative angle
        var relativeAngle = punchAngle - shoulderAngle
        
        // Normalize angle to -π to π
        while relativeAngle > .pi { relativeAngle -= 2 * .pi }
        while relativeAngle < -.pi { relativeAngle += 2 * .pi }
        
        // Calculate horizontal component of punch
        let horizontalPunch = abs(punchDeltaX)
        let verticalPunch = abs(punchDeltaY)
        
        // Distance from shoulder to fist
        let distanceFromShoulder = hypot(fistPoint.x - shoulder.x, fistPoint.y - shoulder.y)
        
        // Thresholds
        
        let angleThreshold: CGFloat = .pi / 4 // 45 degrees
        let extensionThreshold: CGFloat = 150 // pixels
        
        // Check if punch is more forward (perpendicular to shoulders)
        let isForwardPunch = abs(relativeAngle) < angleThreshold || abs(relativeAngle - .pi) < angleThreshold
        
        // Jab: Quick, forward, less extension
        if isForwardPunch && horizontalPunch > verticalPunch * 1.5 && distanceFromShoulder < extensionThreshold {
            return .jab
        }
        
        // Straight: Forward, full extension, more power
        if isForwardPunch && horizontalPunch > verticalPunch && distanceFromShoulder >= extensionThreshold {
            return .straight
        }
        
        // For right hand in orthodox stance, more likely to be straight/cross
        if !isLeftHand && horizontalPunch > verticalPunch * 1.2 {
            return .straight
        }
        
        // For left hand in orthodox stance, more likely to be jab
        if isLeftHand && horizontalPunch > verticalPunch {
            return .jab
        }
        
        return .unknown
    }
}
