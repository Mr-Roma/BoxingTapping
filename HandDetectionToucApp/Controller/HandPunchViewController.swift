// ============================================================
//  HandPunchViewController.swift
//  HandDetectionToucApp
//
//  Created by Romario Marcal on 16/10/25.
// ============================================================

import UIKit
import AVFoundation

class HandPunchViewController: UIViewController {
    
    // Communication back to SwiftUI
    var onScoreUpdate: ((Int) -> Void)?
    
    // Model
    private var gameState = BoxingState()
    
    // Services
    private let cameraService = CameraService()
    private let visionService = VisionService()
    
    // View
    private let targetView = TargetView(frame: .init(origin: .zero, size: .init(width: TargetView.defaultSize, height: TargetView.defaultSize)))
    private let skeletonOverlayView = SkeletonOverlayView()
    private var cameraPreviewLayer: CALayer?
    
    // Game Logic Properties
    private let touchVelocityThreshold: CGFloat = 10.0
    private var hitCooldownTimer: Timer?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
        setupGestureRecognizers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraPreviewLayer?.frame = view.bounds
        skeletonOverlayView.frame = view.bounds
        
        // Position target for the first time
        if gameState.targetCenter == .zero {
            repositionTarget()
        }
    }

    // MARK: - Setup
    
    private func setupCamera() {
        cameraService.delegate = self
        let previewLayer = cameraService.previewLayer
        view.layer.addSublayer(previewLayer)
        self.cameraPreviewLayer = previewLayer
        cameraService.start()
    }
    
    private func setupUI() {
        // Add skeleton overlay
        skeletonOverlayView.frame = view.bounds
        skeletonOverlayView.jointColor = .green
        skeletonOverlayView.boneColor = .yellow
        skeletonOverlayView.jointRadius = 8
        skeletonOverlayView.boneWidth = 3
        view.addSubview(skeletonOverlayView)
        
        // Add target on top
        view.addSubview(targetView)
    }
    
    private func setupGestureRecognizers() {
        // Double tap to toggle skeleton visibility
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
    }
    
    @objc private func handleDoubleTap() {
        gameState.showSkeleton.toggle()
        
        UIView.animate(withDuration: 0.3) {
            self.skeletonOverlayView.alpha = self.gameState.showSkeleton ? 1.0 : 0.0
        }
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - Game Logic
    
    private func processHandPositions(leftFist: CGPoint?, rightFist: CGPoint?) {
        if let leftFist = leftFist {
            if isTouch(currentPoint: leftFist, previousPoint: gameState.previousLeftFistPoint) {
                checkHit(fistPoint: leftFist)
            }
            gameState.previousLeftFistPoint = leftFist
        }
        
        if let rightFist = rightFist {
            if isTouch(currentPoint: rightFist, previousPoint: gameState.previousRightFistPoint) {
                checkHit(fistPoint: rightFist)
            }
            gameState.previousRightFistPoint = rightFist
        }
    }
    
    private func updateBodyPose(_ bodyPose: BodyPoseData?) {
        guard let bodyPose = bodyPose else {
            skeletonOverlayView.clearSkeleton()
            return
        }
        
        gameState.currentBodyJoints = bodyPose.joints
        gameState.bodyPoseConfidence = bodyPose.confidence
        
        if gameState.showSkeleton {
            skeletonOverlayView.updateSkeleton(joints: bodyPose.joints)
        }
    }
    
    private func isTouch(currentPoint: CGPoint, previousPoint: CGPoint?) -> Bool {
        guard let previousPoint = previousPoint else { return false }
        let deltaX = currentPoint.x - previousPoint.x
        let deltaY = currentPoint.y - previousPoint.y
        let velocity = sqrt(deltaX * deltaX + deltaY * deltaY)
        return velocity > touchVelocityThreshold
    }
    
    private func checkHit(fistPoint: CGPoint) {
        guard gameState.canRegisterHit else { return }
        
        let distance = hypot(fistPoint.x - gameState.targetCenter.x, fistPoint.y - gameState.targetCenter.y)
        
        if distance < TargetView.defaultSize / 2 + 30 {
            handleHit()
        }
    }
    
    private func handleHit() {
        // 1. Update Model
        gameState.score += 1
        gameState.canRegisterHit = false
        
        onScoreUpdate?(gameState.score)
        
        // 2. Update View
        hitCooldownTimer?.invalidate()
        let newCenter = calculateNewTargetPosition()
        targetView.animateHitAndRespawn(newCenter: newCenter)
        gameState.targetCenter = newCenter
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // 3. Set Cooldown
        hitCooldownTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.gameState.canRegisterHit = true
        }
    }
    
    private func repositionTarget() {
        let newPosition = calculateNewTargetPosition()
        gameState.targetCenter = newPosition
        targetView.center = newPosition
    }
    
    private func calculateNewTargetPosition() -> CGPoint {
        let safeMargin: CGFloat = 50
        let targetSize = TargetView.defaultSize
        let maxX = view.bounds.width - targetSize - safeMargin
        let maxY = view.bounds.height - targetSize - safeMargin
        
        let randomX = CGFloat.random(in: safeMargin...(maxX > safeMargin ? maxX : safeMargin))
        let randomY = CGFloat.random(in: safeMargin...(maxY > safeMargin ? maxY : safeMargin))
        
        return CGPoint(x: randomX + targetSize / 2, y: randomY + targetSize / 2)
    }
}

// MARK: - CameraServiceDelegate
extension HandPunchViewController: CameraServiceDelegate {
    func cameraService(_ service: CameraService, didOutput sampleBuffer: CMSampleBuffer) {
        visionService.processFrame(sampleBuffer, viewBounds: view.bounds) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.processHandPositions(leftFist: data.leftFistPoint, rightFist: data.rightFistPoint)
                    self?.updateBodyPose(data.bodyPose)
                case .failure(let error):
                    print("Vision processing error: \(error)")
                }
            }
        }
    }
}
