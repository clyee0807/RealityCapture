//
//  ContentView.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/3/27.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: ARViewModel
    
    let accelerationThreshold = 0.02
    
    init(viewModel vm: ARViewModel) {
        print("Initialize ContentView!!")
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack{
            ZStack(alignment: .topTrailing) {
                // ARViewContainer(viewModel).edgesIgnoringSafeArea(.all)
                VStack() {
                    HStack() {
                        VStack(alignment:.leading) {
                            if let acceleration = viewModel.getAcceleration() {
                                let text = String(format: "Acceleration: %.3f G", acceleration)
                                Text(text)
                                    .foregroundColor(acceleration > accelerationThreshold ? .red : .primary)
                            } else {
                                Text("No Acceleration Data")
                            }
                            
//                            DebugMessageButton(model: viewModel)
                        }
                        
                        Spacer()
                        
                        VStack(alignment:.leading) {
                            Text("\(viewModel.appState.trackingState)")
                            if case .SessionStarted = viewModel.appState.writerState {
                                Text("\(viewModel.datasetWriter.currentFrameCounter) Frames")
                            }
                            if viewModel.appState.supportsDepth {
                                Text("Depth Supported")
                            }
                        }.padding()
                    }
                }
            }
            VStack {
                Spacer()
                HStack(spacing: 20) {
                    // CaptureModeButton(model: viewModel)
                    if viewModel.appState.writerState == .SessionNotStarted {
                        Spacer()
                        
                        Button(action: {
                            viewModel.resetWorldOrigin()
                        }) {
                            Text("Reset")
                                .padding(.horizontal, 15)
                                .padding(.vertical, 5)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        
                        Button(action: {
                            do {
                                try viewModel.datasetWriter.initializeProject()
                                viewModel.state = .capturing
                            }
                            catch {
                                print("\(error)")
                            }
                        }) {
                            Text("Start")
                                .padding(.horizontal, 15)
                                .padding(.vertical, 5)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                    }
                    
                    if viewModel.appState.writerState == .SessionStarted {
                        Spacer()
                        Button(action: {
                            viewModel.datasetWriter.finalizeProject()
                            viewModel.state = .detecting
                        }) {
                            Text("End")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 5)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        Button(action: {
                            viewModel.captureFrame()
                        }) {
                            Text("Capture")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 5)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                    }
                    
                }
                .padding()
            }
            .preferredColorScheme(.dark)
        }
    }
}
