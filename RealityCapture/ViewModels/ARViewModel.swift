//
//  ARViewModel.swift
//  RealityCapture
//
//  Created by lychen on 2024/4/4.
//

import Foundation
import Zip
import Combine
import ARKit
import RealityKit
import os

enum AppError : Error {
    case projectAlreadyExists
    case manifestInitializationFailed
}

enum ModelState: String, CustomStringConvertible {
    var description: String { rawValue }

    case notSet
    case detecting
    case capturing
    case completed
    case restart
    case failed
}

enum CaptureMode: String, CaseIterable {
    case manual
    case auto
}

class ARViewModel : NSObject, ARSessionDelegate, ObservableObject {
    let logger = Logger(subsystem: AppDelegate.subsystem, category: "ARViewModel")
    
    @Published var appState = AppState()
//    @Published var modelState: ModelState = .notSet
    @Published var state: ModelState = .notSet {
        didSet {
            logger.debug("didSet AppDataModel.state to \(self.state)")

            if state != oldValue {
                performStateTransition(from: oldValue, to: state)
            }
        }
    }
    
    @Published var captureMode: CaptureMode = .auto
    

    @Published var anchorPosition: SIMD3<Float>? = nil // anchor position
    @Published var cameraPosition: SIMD3<Float>? = nil // camera position
    
    @Published var originAnchor: AnchorEntity? = nil // position of boundung box
    
    @Published var progressDial: ProgressDial? = nil
    @Published var closestPoint: Int? = nil
    
    @Published var isAutoCapture: Bool = false
    
    ///-------
    var autoCaptureTimer: Timer? = nil
    func switchCaptureMode() {
        switch captureMode {
        case .manual:
            captureMode = .auto
            isAutoCapture = true
            startAutoCapture()
        case .auto:
            captureMode = .manual
            isAutoCapture = false
            stopAutoCapture()
        }
    }
    private func startAutoCapture() {
        autoCaptureTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
           self?.captureFrame()
        }
    }

    private func stopAutoCapture() {
       autoCaptureTimer?.invalidate()
       autoCaptureTimer = nil
    }
    
    func captureFrame() {
       if let frame = session?.currentFrame {
           datasetWriter.writeFrameToDisk(frame: frame, viewModel: self)
       }
   }
    ///-------
    
    
    var session: ARSession? = nil
    var arView: ARView? = nil
    var cancellables = Set<AnyCancellable>()
    let datasetWriter: DatasetWriter
    
    init(datasetWriter: DatasetWriter) {
        self.datasetWriter = datasetWriter
        super.init()
        self.setupObservers()
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            self.appState.supportsDepth = true
        }
    }
    
    func setupObservers() {
        datasetWriter.$writerState.sink {x in self.appState.writerState = x} .store(in: &cancellables)
        datasetWriter.$currentFrameCounter.sink { x in self.appState.numFrames = x }.store(in: &cancellables)
        
        $appState
            .map(\.appMode)
            .prepend(appState.appMode)
            .removeDuplicates()
            .sink { x in
                switch x {
                case .Offline:
                    print("Changed to offline")
                case .Online:
                    print("Changed to online")
                }
            }
            .store(in: &cancellables)
    }
    
    
    func createARConfiguration() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
            // Activate sceneDepth
            configuration.frameSemantics = .sceneDepth
        }
        return configuration
    }
    
    func resetWorldOrigin() {
        session?.pause()
        let config = createARConfiguration()
        session?.run(config, options: [.resetTracking])
    }
    
    // 每幀 ARframe 更新都會呼叫
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let cameraTransform = frame.camera.transform
        self.cameraPosition = SIMD3<Float>(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
        
        if let dial = progressDial {
            self.closestPoint = dial.findNearestPoint(cameraPosition: cameraPosition!, anchorPosition: anchorPosition!)
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        self.appState.trackingState = trackingStateToString(camera.trackingState)
    }
    
    private func performStateTransition(from fromState: ModelState, to toState: ModelState) {
        if fromState == .failed {
            logger.error("Error to failed state.")
        }

        switch toState {
            case .notSet:
                logger.debug("Set ModelState to notSet")
            
            case .detecting:
                logger.debug("Set ModelState to detecting")
                if let entity = originAnchor?.children.first(where: { $0.name == "ProgressDial"}) {
                    entity.removeFromParent()
                } else {
                    logger.error("ProgressDial entity not found")
                }
            
            case .capturing:
                logger.debug("Set ModelState to capturing")
                
                if let entity = originAnchor?.children.first(where: { $0.name == "ProgressDial"}) {
//                    findNearestPoint(camera: cameraPosition)
                } else {
                    logger.info("Create ProgressDial.")
                    createProgressDial()
                }

            case .failed:
                logger.error("App failed state error")
                // Shows error screen.
            default:
                break
        }
    }
    
    private func createProgressDial() {
        guard let originAnchor = self.originAnchor else {
            logger.error("originAnchor is nil")
            return
        }
        
        self.progressDial = ProgressDial(anchorPosition: anchorPosition!)
        self.progressDial?.name = "ProgressDial"
        originAnchor.addChild(self.progressDial!)
    }
    
    
    func updateAnchorPosition(_ anchorPosition: SIMD3<Float>, originAnchor: AnchorEntity) {
        self.anchorPosition = anchorPosition
        self.originAnchor = originAnchor
        print("update origin anchor in viewModel: \(originAnchor.position)")
    }
    
    func calculateBoundingBoxSize() -> SIMD3<Float> {
        guard let lineXEntity = self.originAnchor?.findEntity(named: "line2") as? ModelEntity,
            let lineYEntity = self.originAnchor?.findEntity(named: "line3") as? ModelEntity,
            let lineZEntity = self.originAnchor?.findEntity(named: "line5") as? ModelEntity,
            let meshX = lineXEntity.components[ModelComponent.self]?.mesh,
            let meshY = lineYEntity.components[ModelComponent.self]?.mesh,
            let meshZ = lineZEntity.components[ModelComponent.self]?.mesh else {
            print("One or more entities are missing or do not have a ModelComponent.")
            return SIMD3<Float>(0, 0, 0)
        }

        let lengthX = meshX.bounds.max.x - meshX.bounds.min.x
        let lengthY = meshY.bounds.max.y - meshY.bounds.min.y
        let lengthZ = meshZ.bounds.max.z - meshZ.bounds.min.z

        return SIMD3<Float>(lengthX, lengthY, lengthZ)
  
    }
}
