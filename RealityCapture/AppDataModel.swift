//
//  AppDataModel.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/3/27.
//

import Combine
//import Foundation
import SwiftUI
import RealityKit
import os

@MainActor
@available(iOS 17.0, *)
class AppDataModel: ObservableObject, Identifiable {
    let logger = Logger(subsystem: RealityCaptureApp.subsystem, category: "AppDataModel")
    
    // implement the singleton design pattern, ensuring that there is only one instance of this model throughout the APP
    static let instance = AppDataModel() // call init()
    
    @Published var objectCaptureSession: ObjectCaptureSession? {
        willSet {
            detachListeners() // detach previous listeners
        }
        didSet {
            guard objectCaptureSession != nil else { return }
            attachListeners() // 註冊一個或多個 listener 來監聽 objectCaptureSession 發生變化
        }
    }
    
    @Published var state: ModelState = .notSet {
        didSet {
            logger.debug("State changed to \(self.state)")
            
            if state != oldValue {
                performStateTransition(from: oldValue, to: state)
            }
        }
    }
    
    /// The folder set when a new capture session starts.
    private(set) var scanFolderManager: CaptureFolderManager!
    
    
    private init(objectCaptureSession: ObjectCaptureSession) {
        self.objectCaptureSession = objectCaptureSession
        state = .ready
    }
    init() {
        state = .ready
    }
    
    // Create a new object capture session
    // Called in ready state
    private func startNewCapture() -> Bool {
        logger.log("startNewCapture() called...")
        if !ObjectCaptureSession.isSupported {
            preconditionFailure("ObjectCaptureSession is not supported on this device!")
        }
        
        guard let folderManager = CaptureFolderManager() else {
            return false;
        }
        scanFolderManager = folderManager
        
        objectCaptureSession = ObjectCaptureSession()
        guard let session = objectCaptureSession else {
            preconditionFailure("startNewCapture() got unexpectedly nil session!")
        }
        
        var configuration = ObjectCaptureSession.Configuration()
        configuration.checkpointDirectory = scanFolderManager.snapshotsFolder
        configuration.isOverCaptureEnabled = true
        logger.log("Enabling overcapture...")
        
        // Starts the initial segment and sets the output locations.
        session.start(imagesDirectory: scanFolderManager.imagesFolder, configuration: configuration)
        
        state = .capturing
        return true
    }
    
    
    
    private func performStateTransition(from fromState: ModelState, to toState: ModelState) {
        if fromState == .failed {
            print("Failed state, reset the session.")
        }
        
        switch toState {
            case .ready:
                print("Into READY ModelState.")
                guard startNewCapture() else {
                    logger.error("Starting new capture failed!")
                    break
                }
            case .capturing:
                print("Into CAPTURING ModelState.")
                break
            default:
                break
        }
    }
    
    
    
    
    private var tasks: [ Task<Void, Never> ] = []
    
    @MainActor
    private func attachListeners() {
        logger.debug("Attaching listeners...")
        guard let model = objectCaptureSession else { // ensure objectCaptureSession is not nil
            fatalError("Logic error")
        }
        
        tasks.append(Task<Void, Never> { [weak self] in
                for await newFeedback in model.feedbackUpdates {
                    self?.logger.debug("Task got async feedback change to: \(String(describing: newFeedback))")
                    // self?.updateFeedbackMessages(for: newFeedback)
                }
                self?.logger.log("^^^ Got nil from stateUpdates iterator!  Ending observation task...")
        })
        tasks.append(Task<Void, Never> { [weak self] in
            for await newState in model.stateUpdates {
                self?.logger.debug("Task got async state change to: \(String(describing: newState))")
//                self?.onStateChanged(newState: newState)
            }
            self?.logger.log("^^^ Got nil from stateUpdates iterator!  Ending observation task...")
        })
    }

    private func detachListeners() {
        logger.debug("Detaching listeners...")
        for task in tasks {
            task.cancel()
        }
        tasks.removeAll()
    }
}
