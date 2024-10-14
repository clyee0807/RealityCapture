//
//  MotionDetection.swift
//  CaptureSample
//
//  Created by lychen on 2024/10/7.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import CoreMotion

class MotionDetection {
   private var motionManager: CMMotionManager
    
    init() {
        self.motionManager = CMMotionManager()
    }
    
    func startAccelerometerUpdates(_ updateHandler: @escaping (CMAccelerometerData?, Error?) -> Void) {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1  // 0.1 fps
            motionManager.startAccelerometerUpdates(to: OperationQueue.main, withHandler: updateHandler)
        }
    }

    func stopAccelerometerUpdates() {
        motionManager.stopAccelerometerUpdates()
    }
}
