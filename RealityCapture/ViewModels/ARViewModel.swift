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
    var session: ARSession? = nil
    var arView: ARView? = nil
    var cancellables = Set<AnyCancellable>()
    let datasetWriter: DatasetWriter
    
    init(datasetWriter: DatasetWriter) {
        self.datasetWriter = datasetWriter
        super.init()
        self.setupObservers()
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
//                    self.appState.stream = false
                    print("Changed to offline")
                case .Online:
                    print("Changed to online")
                }
            }
            .store(in: &cancellables)
        
//        frameSubject.throttle(for: 0.5, scheduler: RunLoop.main, latest: true).sink {
//            f in
//            if self.appState.stream && self.appState.appMode == .Online {
//                self.ddsWriter.writeFrameToTopic(frame: f)
//            }
//        }.store(in: &cancellables)
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
    
    
    func session(
        _ session: ARSession,
        didUpdate frame: ARFrame
    ) {
//        frameSubject.send(frame)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        self.appState.trackingState = trackingStateToString(camera.trackingState)
    }
}
