////
////  ContentView.swift
////  RealityCapture
////
////  Created by CGVLAB on 2024/3/27.
////

import SwiftUI
import ARKit
import RealityKit

struct ContentView: View {
    @StateObject private var viewModel: ARViewModel
    
    let accelerationThreshold = 0.02
    
    init(viewModel vm: ARViewModel) {
        print("Initialize ContentView, modelstate = \(vm.state)!!")
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            if viewModel.state == .initialize {
                VStack {
                    Spacer()
                    VStack(spacing: 20) {
                        Spacer()
                        Button(action: {
                            viewModel.state = .detecting
                        }) {
                            Text("New Capture")
                                .padding(.horizontal, 15)
                                .padding(.vertical, 10)
                                .foregroundColor(.white)
                        }
                        .background(Color.blue)
                        .cornerRadius(10)
                        
                        Button(action: {
                            viewModel.state = .readyToRecapture
                        }) {
                            Text("Continue Capture")
                                .padding(.horizontal, 15)
                                .padding(.vertical, 10)
                                .foregroundColor(.white)
                        }
                        .background(Color.blue)
                        .cornerRadius(10)
                        Spacer()
                    }
                    Spacer()
                }
            } else {
                ZStack(alignment: .topTrailing) {
                    ARViewContainer(viewModel).edgesIgnoringSafeArea(.all)
                    VStack {
                        HStack {
                            VStack(alignment:.leading) {
                                if let acceleration = viewModel.getAcceleration() {
                                    let text = String(format: "Acceleration: %.3f G", acceleration)
                                    Text(text)
                                        .foregroundColor(acceleration > accelerationThreshold ? .red : .primary)
                                } else {
                                    Text("No Acceleration Data")
                                }
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
                        if viewModel.appState.writerState == .SessionNotStarted {
                            Spacer()
                            Button(action: {
                                viewModel.resetWorldOrigin()
                                viewModel.state = .detecting
                            }) {
                                Text("Reset")
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 5)
                                    .foregroundColor(.black)
                            }
                            .background(Color.blue)
                            .cornerRadius(10)
                            
                            Button(action: {
                                do {
                                    try viewModel.datasetWriter.initializeProject()
                                    viewModel.state = .capturing1
                                }
                                catch {
                                    print("\(error)")
                                }
                            }) {
                                Text("Start")
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 5)
                                    .foregroundColor(.black)
                            }
                            .background(Color.blue)
                            .cornerRadius(10)
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
                                    .foregroundColor(.black)
                            }
                            .background(Color.blue)
                            .cornerRadius(10)
                            Button(action: {
                                viewModel.captureFrame()
                            }) {
                                Text("Capture")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 5)
                                    .foregroundColor(.black)
                            }
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    @StateObject private var viewModel: ARViewModel

    static var previews: some View {
        ContentView(viewModel: ARViewModel(datasetWriter: DatasetWriter()))
            .previewInterfaceOrientation(.portrait)
    }
}


//struct SimpleContentView: View {
//    var body: some View {
//        Text("Hello, World!")
//            .foregroundColor(.blue)
//            .padding()
//    }
//}
//
//struct SimpleContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        SimpleContentView()
//    }
//}
