//
//  ContentView.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/3/27.
//

import SwiftUI
import os

struct ContentView: View {
    
    static var logger = Logger(subsystem: RealityCaptureApp.subsystem, category: "ContentView")
//    @StateObject var appModel: AppDataModel = AppDataModel.instance
    @ObservedObject var model: CameraViewModel

    
//    private var showProgressView: Bool {
//        appModel.state == .completed || appModel.state == .restart || appModel.state == .ready
//    }
    
    var body: some View {
        ZStack {
            // Make the entire background black.
            Color.black.edgesIgnoringSafeArea(.all)
            CaptureView(model: model)
        }
        // Force dark mode so the photos pop.
        .environment(\.colorScheme, .dark)
    }
}

private struct CircularProgressView: View {
    @Environment(\.colorScheme) private var colorScheme // get user's current color scheme

    var body: some View {
        VStack {
            Spacer()
            ZStack {
                Spacer()
                ProgressView(label: { Text("ContentView ProgressView...") })
                    .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .light ? .black : .white))
                Spacer()
            }
            Spacer()
        }
    }
}

