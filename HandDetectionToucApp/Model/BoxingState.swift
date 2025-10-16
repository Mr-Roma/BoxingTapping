//
//  BoxingState.swift
//  HandDetectionToucApp
//
//  Created by Romario Marcal on 16/10/25.
//

// GameState.swift
import Foundation
import CoreGraphics // Needed for CGPoint
import Vision
// The Model: Represents the state and data of the game.
struct BoxingState {
    var score: Int = 0
    var targetCenter: CGPoint = .zero
    var canRegisterHit: Bool = true
    
    // Punch tracking
    var previousLeftFistPoint: CGPoint?
    var previousRightFistPoint: CGPoint?
    
    // Body pose tracking
    var currentBodyJoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    var bodyPoseConfidence: Float = 0.0
    var showSkeleton: Bool = true // Toggle for skeleton visualization
    
    // Punch statistics
    var punchStats = PunchStats()
}

