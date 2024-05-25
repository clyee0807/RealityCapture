//
//  ContentView.swift
//  RealityCapture
//
//  Created by lychen on 2024/4/4.
//

import SwiftUI
import ARKit
import RealityKit


struct ContentView : View {
    @StateObject private var viewModel: ARViewModel
    @State private var showSheet: Bool = false
    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    let accelerationThreshold = 0.02
    
    var body: some View {
        ZStack{
            ZStack(alignment: .topTrailing) {
                ARViewContainer(viewModel).edgesIgnoringSafeArea(.all)
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
                            
                            DebugMessageButton(model: viewModel)
                        }
                        
                        Spacer()
                        
                        VStack(alignment:.leading) {
                            Text("\(viewModel.appState.trackingState)")
                            if case .Offline = viewModel.appState.appMode {
                                if case .SessionStarted = viewModel.appState.writerState {
                                    Text("\(viewModel.datasetWriter.currentFrameCounter) Frames")
                                }
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
                    CaptureModeButton(model: viewModel/*, frameWidth: width / 3*/)
                    
                    if case .Offline = viewModel.appState.appMode {
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
//                                if let frame = viewModel.session?.currentFrame {
//                                    viewModel.datasetWriter.writeFrameToDisk(frame: frame, viewModel: viewModel)
//                                }
                                viewModel.captureFrame()
                            }) {
                                Text("Save Frame")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 5)
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                        }
                    }
                }
                .padding()
            }
            .preferredColorScheme(.dark)
        }
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
            // This is the caption that appears when the user is in .－auto mode.
//            if case .auto = model.captureMode {
//                Text("Auto Capture")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                    .transition(.opacity)
//            }
        }
        // This frame centers the view and keeps it from reflowing when the view has a caption.
        // The view uses .top so the button won't move and the text will animate in and out.
//        .frame(width: frameWidth, height: CaptureModeButton.backingDiameter, alignment: .top)
    }
}

struct DebugMessageButton: View {
    @ObservedObject var model: ARViewModel
    
    var body: some View {
        Button(action: {
            model.stopMonitoringAcceleration()
//            print(ARWorldTrackingConfiguration.supportedVideoFormats)
//            print("Anchor position: \(model.anchorPosition)")
//            print("Camera position: \(model.cameraPosition)")
//            let size = model.calculateBoundingBoxSize()
//            print("Bounding box size: (\(size.x), \(size.y), \(size.z))")
//            print("originAnchor: \n \(viewModel.originAnchor)")
            print("cloestPoint: \(model.closestPoint)")
            print("dialPoints: \(model.dialPoints)")
        }) {
            Text("Debug")
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .background(.red)
        
    }
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: ARViewModel(datasetWriter: DatasetWriter()/*, ddsWriter: DDSWriter()*/))
            .previewInterfaceOrientation(.portrait)
    }
}
#endif
