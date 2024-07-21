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
                InitializeStateView(viewModel: viewModel)
            } 
            else if viewModel.state == .training {
                TrainingStateView(viewModel: viewModel)
            }
            else if viewModel.state == .feedback {
                FeedbackStateView(viewModel: viewModel)
            }
            else {
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
                                DebugMessageButton(model: viewModel)
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

struct CaptureModeButton: View {
//    static let toggleDiameter = CaptureButton.outerDiameter / 3.0
    static let toggleDiameter = 20.0
    static let backingDiameter = CaptureModeButton.toggleDiameter * 2.0
    
    @ObservedObject var model: ARViewModel
//    var frameWidth: CGFloat
    
    var body: some View {
        VStack(alignment: .center/*@END_MENU_TOKEN@*/, spacing: 2) {
            Button(action: {
                withAnimation {
                    model.switchCaptureMode()
                }
            }, label: {
                ZStack {
                    Circle()
                        .frame(width: CaptureModeButton.backingDiameter,
                               height: CaptureModeButton.backingDiameter)
                        .foregroundColor(Color.white)
                    //                        .opacity(Double(CameraView.buttonBackingOpacity))
                    Circle()
                        .frame(width: CaptureModeButton.toggleDiameter,
                               height: CaptureModeButton.toggleDiameter)
                        .foregroundColor(Color.white)
                    switch model.captureMode {
                    case .auto:
                        Text("A").foregroundColor(Color.black)
                            .frame(width: CaptureModeButton.toggleDiameter,
                                   height: CaptureModeButton.toggleDiameter,
                                   alignment: .center)
                    case .manual:
                        Text("M").foregroundColor(Color.black)
                            .frame(width: CaptureModeButton.toggleDiameter,
                                   height: CaptureModeButton.toggleDiameter,
                                   alignment: .center)
                    }
                }
            })
        
        }
    }
}

struct DebugMessageButton: View {
    @ObservedObject var model: ARViewModel
    
    var body: some View {
        Button(action: {
//            model.stopMonitoringAcceleration()
//            print(ARWorldTrackingConfiguration.supportedVideoFormats)
//            print("Anchor position: \(model.anchorPosition)")
//            print("Camera position: \(model.cameraPosition)")
//            let size = model.calculateBoundingBoxSize()
//            print("Bounding box size: (\(size.x), \(size.y), \(size.z))")
//            print("originAnchor: \n \(viewModel.originAnchor)")
            print("checkpoints:\n \(model.checkpoints)")
        }) {
            Text("Debug")
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
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
