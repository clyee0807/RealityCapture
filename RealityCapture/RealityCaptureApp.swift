//
//  RealityCaptureApp.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/3/27.
//

import SwiftUI

@main
struct RealityCaptureApp: App {
    static let subsystem = "com.lychen.RealityCapture"
    @StateObject var model = CameraViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
    }
}
