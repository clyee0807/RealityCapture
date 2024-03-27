//
//  AppDataModel.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/3/27.
//

import Combine
import Foundation
import SwiftUI
import RealityKit
import os

@MainActor
class AppDataModel: ObservableObject, Identifiable {
    //    let logger = Logger(subsystem: RealityCaptureApp.subsystem, category: "AppDataModel")
    
    // implement the singleton design pattern, ensuring that there is only one instance of this model throughout the APP
    static let instance = AppDataModel()
    
    @Published var objectCaptureSession: ObjectCaptureSession? {
        
    }
}
