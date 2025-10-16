import Vision
import UIKit

// Struct to hold body skeleton joint points
struct BodyPoseData {
    let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let confidence: Float
}

// Enhanced struct to hold both hand and body pose results
struct ProcessedFrameData {
    let leftFistPoint: CGPoint?
    let rightFistPoint: CGPoint?
    let bodyPose: BodyPoseData?
}

class VisionService {
    
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    private let visionQueue = DispatchQueue(label: "visionQueue")
    
    init() {
        handPoseRequest.maximumHandCount = 2
    }
    
    func processFrame(_ sampleBuffer: CMSampleBuffer, viewBounds: CGRect, completion: @escaping (Result<ProcessedFrameData, Error>) -> Void) {
        visionQueue.async {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
            
            do {
                // Perform both hand and body pose detection
                try handler.perform([self.handPoseRequest, self.bodyPoseRequest])
                
                // Process hand pose results
                var newLeftFist: CGPoint?
                var newRightFist: CGPoint?
                
                if let handObservations = self.handPoseRequest.results, !handObservations.isEmpty {
                    for observation in handObservations {
                        if let fistCenter = self.getFistCenter(from: observation, viewBounds: viewBounds) {
                            if observation.chirality == .left {
                                newLeftFist = fistCenter
                            } else {
                                newRightFist = fistCenter
                            }
                        }
                    }
                }
                
                // Process body pose results
                var bodyPose: BodyPoseData?
                if let bodyObservations = self.bodyPoseRequest.results?.first {
                    bodyPose = self.getBodyPose(from: bodyObservations, viewBounds: viewBounds)
                }
                
                let processedData = ProcessedFrameData(
                    leftFistPoint: newLeftFist,
                    rightFistPoint: newRightFist,
                    bodyPose: bodyPose
                )
                completion(.success(processedData))
                
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func getFistCenter(from observation: VNHumanHandPoseObservation, viewBounds: CGRect) -> CGPoint? {
        guard let recognizedPoints = try? observation.recognizedPoints(.all),
              let wrist = recognizedPoints[.wrist], wrist.confidence > 0.3,
              let indexMCP = recognizedPoints[.indexMCP], indexMCP.confidence > 0.3,
              let middleMCP = recognizedPoints[.middleMCP], middleMCP.confidence > 0.3 else {
            return nil
        }
        
        let fistX = (wrist.location.x + indexMCP.location.x + middleMCP.location.x) / 3
        let fistY = (wrist.location.y + indexMCP.location.y + middleMCP.location.y) / 3
        
        return CGPoint(
            x: fistX * viewBounds.width,
            y: (1 - fistY) * viewBounds.height
        )
    }
    
    private func getBodyPose(from observation: VNHumanBodyPoseObservation, viewBounds: CGRect) -> BodyPoseData? {
        guard let recognizedPoints = try? observation.recognizedPoints(.all) else {
            return nil
        }
        
        var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        var totalConfidence: Float = 0
        var validJointsCount = 0
        
        // Extract all available joints
        let jointNames: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .leftEye, .rightEye, .leftEar, .rightEar,
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle,
            .neck, .root
        ]
        
        for jointName in jointNames {
            if let point = recognizedPoints[jointName], point.confidence > 0.3 {
                // Convert from Vision coordinates to UIKit coordinates
                let convertedPoint = CGPoint(
                    x: point.location.x * viewBounds.width,
                    y: (1 - point.location.y) * viewBounds.height
                )
                joints[jointName] = convertedPoint
                totalConfidence += point.confidence
                validJointsCount += 1
            }
        }
        
        guard validJointsCount > 0 else { return nil }
        
        let avgConfidence = totalConfidence / Float(validJointsCount)
        return BodyPoseData(joints: joints, confidence: avgConfidence)
    }
}

