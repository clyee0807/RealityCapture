//
//  ARViewModel.swift
//  RealityCapture
//
//  Created by lychen on 2024/4/4.
//

import Foundation
import Combine
import ARKit
import RealityKit
import os
import CoreMotion
import SwiftUI

enum AppError : Error {
    case projectAlreadyExists
    case manifestInitializationFailed
}

enum ModelState: String, CustomStringConvertible {
    var description: String { rawValue }

    case notSet
    
    case initialize
    case detecting
    case positioning
    case capturing1
    case capturing2
    case training
    case feedback
    case readyToRecapture
    
    case failed
}

enum CaptureMode: String, CaseIterable {
    case manual
    case auto
}

enum PointStatus: String, CaseIterable {
    case initialized
    case captured
    case pointed
}


//private let logger = Logger(subsystem: "com.lychen.CaptureSample", category: "ARViewModel")
class ARViewModel : NSObject, ARSessionDelegate, ObservableObject {
    let logger = Logger(subsystem: "com.lychen.CaptureSample", category: "ARViewModel")

    @Published var appState = AppState()
    @Published var state: ModelState = .initialize {
        didSet {
            if state != oldValue {
                performStateTransition(from: oldValue, to: state)
            }
        }
    }
    
    var session: ARSession? = nil
    var arView: ARView? = nil
    var cancellables = Set<AnyCancellable>()
    let datasetWriter: DatasetWriter
    
    init(datasetWriter: DatasetWriter) {
        self.datasetWriter = datasetWriter
        super.init()
        self.setupObservers()
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            print("ARWorldTrackingConfiguration: support depth!")
            self.appState.supportsDepth = true
        }
        
        //startMotionDetection()
        
        let count = 20
        for i in 0..<count {
            self.checkpoints[i] = .initialized
        }
    }
    
    @Published var captureMode: CaptureMode = .manual
    

    @Published var anchorPosition: SIMD3<Float>? = nil // anchor position
    @Published var cameraPosition: SIMD3<Float>? = nil // camera position
    
    @Published var originAnchor: AnchorEntity? = nil  // position of boundung box
    
    @Published var captureTrack: CaptureTrack? = nil  // captureTrack class: hemisphere, checkpoints
    @Published var closestPoint: Int? = nil
    @Published var checkpoints: [Int: PointStatus] = [:]  // state of each checkpoint
                                                          // e.g 2: .initialized
    //@Published var capturedPoints: [Int] = []
    
    /// motion detection
//    var motionDetection = MotionDetection()
//    var lastAcceleration: CMAcceleration?
//
//    func startMotionDetection() {
//        motionDetection.startAccelerometerUpdates { [weak self] data, error in
//            guard let strongSelf = self, let accelerationData = data else {
//                print("Error reading accelerometer data: \(error?.localizedDescription ?? "No error info")")
//                return
//            }
//            strongSelf.lastAcceleration = accelerationData.acceleration
//            //let totalAcceleration = sqrt(pow(accelerationData.acceleration.x, 2) + pow(accelerationData.acceleration.y, 2) + pow(accelerationData.acceleration.z, 2))
//            //print("Total acceleration: \(totalAcceleration - 1)") // minus the gravity
//            //print("Accelerometer data: x: \(accelerationData.acceleration.x), y: \(accelerationData.acceleration.y), z: \(accelerationData.acceleration.z)")
//        }
//    }
    
//    func stopMonitoringAcceleration() {
//        print("Stop Monitoring Acceleration.")
//        motionDetection.stopAccelerometerUpdates()
//    }
//
    func getAcceleration() -> Double? {
        //        guard let acceleration = lastAcceleration else {
        //            print("No acceleration data available.")
        //            return nil
        //        }
        //        let totalAcceleration = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
        //        return totalAcceleration - 1 // minus the gravity
        return 0.01
    }
    
    /// timer & auto capture
    @Published var isAutoCapture: Bool = false
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
        guard let curAcceleration = getAcceleration(), curAcceleration < 0.02 else {
            print("Acceleration too high: \(getAcceleration() ?? 0), cannot capture frame.")
            return
        }
        
        session?.captureHighResolutionFrame { [weak self] frame, error in
            guard let self = self, let frame = frame, let closestPointIndex = self.closestPoint else {
                print("Error capturing high-resolution frame: \(error?.localizedDescription ?? "Closest Point Error")")
                return
            }
            let width = CVPixelBufferGetWidth(frame.capturedImage)
            let height = CVPixelBufferGetHeight(frame.capturedImage)
            print("Received frame with dimensions: \(width) x \(height)")
            
            print("Captured frame with closest point index: \(closestPointIndex)")
            self.checkpoints[closestPointIndex] = .captured
//            print("Status after update: \(self.checkpoints[closestPointIndex])")
            
            self.datasetWriter.writeFrameToDisk(frame: frame, viewModel: self)
            
        }
    }
    
    func setupObservers() {
        datasetWriter.$writerState.sink {x in self.appState.writerState = x} .store(in: &cancellables)
        datasetWriter.$currentFrameCounter.sink { x in self.appState.numFrames = x }.store(in: &cancellables)
    }
    
    func createARConfiguration() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.isAutoFocusEnabled = true
        if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics = .sceneDepth // Activate sceneDepth
        }
        
        if let highResFormat = ARWorldTrackingConfiguration.supportedVideoFormats.first(where: { $0.imageResolution.height >= 2160 }) {
            configuration.videoFormat = highResFormat
        }
        
        return configuration
    }
    
    func resetWorldOrigin() {
        session?.pause()
        let config = createARConfiguration()
        session?.run(config, options: [.resetTracking])
    }
    
    func createCaptureTrack() {
        guard let originAnchor = self.originAnchor, let anchorPosition = self.anchorPosition else {
            print("originAnchor or anchorPosition is nil")
            return
        }
        
        let captureTrack = CaptureTrack(anchorPosition: anchorPosition, originAnchor: originAnchor, model: self)
        captureTrack.name = "CaptureTrack"
        originAnchor.addChild(captureTrack)
        self.captureTrack = captureTrack
        print("CaptureTrack created and added to originAnchor")
        print("Children of originAnchor: \(originAnchor.children.map { $0.name })")
    }
    
    // MARK: - ARSession
    // 每幀 ARframe 更新都會呼叫
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let cameraTransform = frame.camera.transform
        self.cameraPosition = SIMD3<Float>(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
        
    
        if self.state == .capturing1 {
            // 每幀都要尋找當下最近的 checkpoint
            if let track = captureTrack {
                self.closestPoint = track.findNearestPoint(cameraPosition: cameraPosition!, anchorPosition: anchorPosition!)
                track.updatePoints(pointIndex: self.closestPoint!)
            }
        }
        
        // 拍完達標要轉到下個 state
//        let capturedCount = self.checkpoints.filter { $1 == .captured }.count
//        if self.state == .capturing1 && capturedCount >= 3 {  // 方便開發，先簡單設定進入下個 state 的邏輯
//            print("Completed capturing!")
//            self.state = .training
//        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        self.appState.trackingState = trackingStateToString(camera.trackingState)
    }
    
    private func performStateTransition(from fromState: ModelState, to toState: ModelState) {
        if fromState == .failed {
            print("Error to failed state.")
        }

        switch toState {
        case .notSet:
            print("Set ModelState to notSet")
        case .initialize:
            print("Set ModelState to initialize")
        
        case .detecting:
            print("Set ModelState to detecting")
            if let originAnchor = originAnchor {
                if let entity = originAnchor.children.first(where: {$0.name == "CaptureTrack"}) {
                    // print("Remove CaptureTrack")
                    entity.removeFromParent()
                }
                
                removeAllChildren(of: originAnchor)
                print("All children of originAnchor have been removed.")
                print("Children of originAnchor: \(originAnchor.children.map { $0.name })")
            } else {
                print("originAnchor is nil, cannot remove children.")
            }
            
        case .positioning:
            print("Set ModelState to positioning")

        case .capturing1:
            print("Set ModelState to capturing")
            
            if let boundingBox = originAnchor?.children.first(where: { $0.name == "BoundingBox" }) {
                print("BoundingBox found, removing all children")
                boundingBox.children.removeAll() // 移除 BoundingBox 底下的所有 children
            } else {
                print("BoundingBox not found")
            }
            
            if (originAnchor?.children.first(where: { $0.name == "CaptureTrack"})) != nil {
                print("captureTrack is existed")
            } else {
                print("Create captureTrack")
                createCaptureTrack()
            }
        case .training:
            print("Set ModelState to training")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in  // transfer to .feedback state after 3 seconds
                self?.state = .feedback
            }
        case .feedback:
            print("Set ModelState to feedback")
            
        case .readyToRecapture:
            print("Set ModelState to readyToRecapture")


        case .failed:
            // Shows error screen.
            print("App failed state error")
        default:
            break
        }
    }
    
    
    func updateAnchorPosition(_ anchorPosition: SIMD3<Float>, originAnchor: AnchorEntity) {
        self.anchorPosition = anchorPosition
        self.originAnchor = originAnchor
        print("update origin anchor in viewModel: \(originAnchor.position)")
    }
    
    func removeAllChildren(of entity: Entity) {
        for child in entity.children {
            print("removing: \(child.name)")
            removeAllChildren(of: child)
            entity.removeChild(child)
        }
    }

    private func calculateBoundingBoxSize() -> SIMD3<Float> {
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
    

    
    // MARK: - New Framework
    @Published var alreadySetup: Bool = false
    @Published var isUploading: Bool = false
    
    /// Reference to the most recently captured image and its metadata (for thumbnail)
    @Published var lastCapture: Capture? = nil
    
    @Published var captureFolderState: CaptureFolderState?
    
    var captureDir: URL? {
        return captureFolderState?.captureDir
    }
    
    
    func requestNewCaptureFolder() {
        print("Requesting new capture folder...")
        
        DispatchQueue.main.async {
            self.lastCapture = nil
        }
        
        sessionQueue.async {
            do {
                let newCaptureFolder = try ARViewModel.createNewCaptureFolder()
                print("Created new capture folder: \"\(String(describing: self.captureDir))\"")
                DispatchQueue.main.async {
                    print("Publishing new capture folder: \"\(String(describing: self.captureDir))\"")
                    self.captureFolderState = newCaptureFolder
                }
            } catch {
                print("Can't create new capture folder!")
            }
        }
    }
    
    private let sessionQueue = DispatchQueue(label: "ARViewModel: sessionQueue")
    
    private static func createNewCaptureFolder() throws -> CaptureFolderState {
        guard let newCaptureDir = CaptureFolderState.initializeProject() else {
            throw SetupError.failed(msg: "Can't create capture directory!")
        }
        return CaptureFolderState(url: newCaptureDir)
    }
    
    private enum SetupError: Error {
        case failed(msg: String)
    }
}



//struct ContentView1: View {
//    @StateObject private var viewModel = ARViewModel(datasetWriter: DatasetWriter())
//
//    var body: some View {
//        Text("Current state: \(viewModel.state.rawValue)")
//            .foregroundColor(.blue)
//            .padding()
//    }
//}
//
//struct ContentView_Previews2: PreviewProvider {
//    static var previews: some View {
//        ContentView1()
//    }
//}
