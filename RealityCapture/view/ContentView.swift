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
    
    @StateObject var appModel: AppDataModel = AppDataModel.instance
    
    private var showProgressView: Bool {
        appModel.state == .completed || appModel.state == .restart || appModel.state == .ready
    }
    
    var body: some View {
        VStack {
            if appModel.state == .capturing {
                if let session = appModel.objectCaptureSession {
                    CapturePrimaryView(session: session)
                }
            }
            else if showProgressView {  // ready, restart, completed
                CircularProgressView()
            }
            else {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
            }
        }
        .environmentObject(appModel)
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
