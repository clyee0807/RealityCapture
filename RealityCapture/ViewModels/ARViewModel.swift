//
//  ARViewModel.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/4/4.
//

import Foundation
import Zip
import Combine
import ARKit
import RealityKit

enum AppError : Error {
    case projectAlreadyExists
    case manifestInitializationFailed
}

class ARViewModel : NSObject, ARSessionDelegate, ObservableObject {
    @Published var appState = AppState()
    @Published var anchorPosition: SIMD3<Float>? = nil // anchor position
    @Published var cameraPosition: SIMD3<Float>? = nil // camera position
    
    @Published var originAnchor: AnchorEntity? = nil // position of boundung box
    
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
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        frameSubject.send(frame)
        let cameraTransform = frame.camera.transform
        self.cameraPosition = SIMD3<Float>(cameraTransform.columns.3.x,
                                        cameraTransform.columns.3.y,
                                        cameraTransform.columns.3.z)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        self.appState.trackingState = trackingStateToString(camera.trackingState)
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
