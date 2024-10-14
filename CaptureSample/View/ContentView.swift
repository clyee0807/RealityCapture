/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's top-level view.
*/

import SwiftUI
import os

private let logger = Logger(subsystem: "com.lychen.CaptureSample",
                            category: "ContentView")

let accelerationThreshold = 0.02

/// This is the root view for the app.
struct ContentView: View {
    @ObservedObject var model: ARViewModel

    var body: some View {
        ZStack{
            ZStack(alignment: .topLeading) {
                ARViewContainer(model).edgesIgnoringSafeArea(.all)
                ARViewTopPanel(model: model)
            }
            .navigationBarBackButtonHidden(true)  /// navigationLink will automatically add a back button on the top scene
            
            ARViewBottomPanel(model: model)
            
            if model.state == .detecting {
                Text("Tap to add an anchor to track the object")
                    .foregroundColor(.white)
                    .padding()
                    .cornerRadius(10)
                    .padding(.bottom, 100)
                    .transition(.opacity)
            }
            
            if model.state == .capturing1 || model.state == .capturing2 {
                
                if model.closestPoint == -1 {
                    Text("Move the camera to the checkpoint")
                        .foregroundColor(.white)
                        .padding()
                        .transition(.opacity)
                }
                
                else if model.getAcceleration()! > accelerationThreshold {
                    Text("Slower the camera movement")
                        .foregroundColor(.white)
                        .padding()
                        .transition(.opacity)
                }
            }
        }
    }
    
}

struct ARViewTopPanel: View {
    @ObservedObject var model: ARViewModel

    var body: some View {
        VStack {
            HStack {
                VStack(alignment:.leading) {
                    if let acceleration = model.getAcceleration() {
                        let text = String(format: "%.3f G", acceleration)
                        Text(text)
                            .foregroundColor(acceleration > accelerationThreshold ? .red : .primary)
                    } else {
                        Text("No Acceleration Data")
                    }
                    DebugMessageButton(model: model)
                }.padding()
                Spacer()
                VStack(alignment:.leading) {
                    Text("\(model.appState.trackingState)")
//                    if case .SessionStarted = model.appState.writerState {
//                        Text("\(model.datasetWriter.currentFrameCounter) Frames")
//                    }
                    if model.appState.supportsDepth {
                        Text("Depth Supported")
                    }
                }.padding()
            }
        }
    }
}

struct ARViewBottomPanel: View {
    @ObservedObject var model: ARViewModel
    @State private var showUploadView = false
    @State private var showCaptureGalleryView = false

    
    var body: some View {
        VStack {
            if model.captureFolderState != nil {
                NavigationLink(destination: CaptureGalleryView(model: model),
                               isActive: self.$showCaptureGalleryView) {
                    EmptyView()
                }
                               .frame(width: 0, height: 0)
                               .disabled(true)
            }
            
            Spacer()
            HStack(spacing: 0) {
                // MARK: positioning (bounding box)
                if model.state == .positioning {
                    Button(action: {
                        model.resetWorldOrigin()
                        model.state = .detecting
                    }) {
                        Text("Reset")
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .foregroundColor(.white)
                    }
                    .background(Color.clear)
                    .cornerRadius(50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 50)
                            .stroke(Color.white, lineWidth: 1)
                    )
                    
                    Spacer()
                    
                    Button(action: {
                        model.state = .capturing1
                    }) {
                        Text("Start")
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .foregroundColor(.black)
                    }
                    .background(Color.white)
                    .cornerRadius(50)
                }
                
                // MARK: capturing
                if model.state == .capturing1 {
                    
                    Button(action: {
                        model.datasetWriter.finalizeProject()
                        self.showCaptureGalleryView = true
                        model.session?.pause()
                        logger.info("End Captue")
                        if model.captureFolderState != nil {
                            print("captures:\n \(String(describing: model.captureFolderState?.captures))")
                            print("captureDir: \(String(describing: model.captureFolderState?.captureDir))")
                        }
                    }) {
                        Text("End")
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .foregroundColor(.black)
                    }
                    .background(Color.white)
                    .cornerRadius(50)
                    
                    Spacer()
                    CaptureButton(model: model)
                    Spacer()
                    
                    if case .SessionStarted = model.appState.writerState {
                        Text("\(model.datasetWriter.currentFrameCounter) Frames")
                    }
                }
            }
//            .padding()
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
    }
}

struct CaptureButton: View {
    static let outerDiameter: CGFloat = 80
    static let strokeWidth: CGFloat = 4
    static let innerPadding: CGFloat = 10
    static let innerDiameter: CGFloat = CaptureButton.outerDiameter - CaptureButton.strokeWidth - CaptureButton.innerPadding
    static let rootTwoOverTwo: CGFloat = CGFloat(2.0.squareRoot() / 2.0)
    static let squareDiameter: CGFloat = CaptureButton.innerDiameter * CaptureButton.rootTwoOverTwo - CaptureButton.innerPadding
    
    @ObservedObject var model: ARViewModel
    
    init(model: ARViewModel) {
        self.model = model
    }
    
    var body: some View {
        let isDisalbeCapture = 
            (model.getAcceleration()! > accelerationThreshold) ||
            (model.closestPoint == -1)
        
        Button(action: {
            model.captureFrame()
        }, label: {
            ManualCaptureButtonView()
//            if model.isAutoCaptureActive {
//                AutoCaptureButtonView(model: model)
//            } else {
//                ManualCaptureButtonView()
//            }
        })
        .disabled(isDisalbeCapture)
        .opacity(isDisalbeCapture ? 0.5 : 1.0)
    }
}
struct ManualCaptureButtonView: View {
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white, lineWidth: CaptureButton.strokeWidth)
                .frame(width: CaptureButton.outerDiameter,
                       height: CaptureButton.outerDiameter,
                       alignment: .center)
            Circle()
                .foregroundColor(Color.white)
                .frame(width: CaptureButton.innerDiameter,
                       height: CaptureButton.innerDiameter,
                       alignment: .center)
        }
    }
}

struct DebugMessageButton: View {
    @ObservedObject var model: ARViewModel
    
    var body: some View {
        Button(action: {
            model.stopMonitoringAcceleration()
            //print("Anchor position: \(String(describing: model.anchorPosition))")
            //print("Camera position: \(String(describing: model.cameraPosition))")
            print("firstHeight: \(String(describing: model.captureTrack?.firstHeight))")
            print("SecnodHeight: \(String(describing: model.captureTrack?.secondHeight))")
            

            let size = model.calculateBoundingBoxSize()
            print("Bounding box size: (\(size.x), \(size.y), \(size.z))")
//            print("originAnchor: \n \(model.originAnchor)")
//            print("checkpoints:\n \(model.checkpoints)")
        }) {
            Text("D")
                .font(.system(size: 12))
                .foregroundColor(.black)
                .frame(width: 40, height: 40)
                .background(Color.white)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
//        .buttonStyle(.bordered)
//        .buttonBorderShape(.capsule)
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        var datasetWriter = DatasetWriter()
//        let model = ARViewModel(datasetWriter: datasetWriter)
//        ContentView(model: model)
//    }
//}
