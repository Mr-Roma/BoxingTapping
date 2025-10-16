//
//  PunchType.swift
//  HandDetectionToucApp
//
//  Created by Romario Marcal on 16/10/25.
//


import Foundation
import CoreGraphics
import Vision

// Enum to represent punch types
enum PunchType: String {
    case jab = "Jab"
    case straight = "Straight"
    case unknown = "Punch"
}

// Struct to track punch statistics
struct PunchStats {
    var totalPunches: Int = 0
    var jabs: Int = 0
    var straights: Int = 0
    var lastPunchType: PunchType = .unknown
}