/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's top-level view.
*/

import SwiftUI
import os

private let logger = Logger(subsystem: "com.lychen.CaptureSample",
                            category: "ContentView")

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
        }
    }
    
}

struct ARViewTopPanel: View {
    @ObservedObject var model: ARViewModel
    let accelerationThreshold = 0.02

    var body: some View {
        VStack {
            HStack {
                VStack(alignment:.leading) {
                    if let acceleration = model.getAcceleration() {
                        let text = String(format: "Acceleration: %.3f G", acceleration)
                        Text(text)
                            .foregroundColor(acceleration > accelerationThreshold ? .red : .primary)
                    } else {
                        Text("No Acceleration Data")
                    }
//                    DebugMessageButton(model: model)
                }
                Spacer()
                VStack(alignment:.leading) {
                    Text("\(model.appState.trackingState)")
                    if case .SessionStarted = model.appState.writerState {
                        Text("\(model.datasetWriter.currentFrameCounter) Frames")
                    }
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
            HStack(spacing: 20) {
                // MARK: positioning (bounding box)
                if model.state == .positioning {
                    Spacer()
                    Button(action: {
                        model.resetWorldOrigin()
                        model.state = .detecting
                    }) {
                        Text("Reset")
                            .padding(.horizontal, 15)
                            .padding(.vertical, 5)
                            .foregroundColor(.black)
                    }
                    .background(Color.blue)
                    .cornerRadius(10)
                    
                    Button(action: {
//                        model.requestNewCaptureFolder()
                        // remove bounding box
//                        model.removeAllChildren()
                        model.state = .capturing1
//                        do {
//                            try model.datasetWriter.initializeProject()
//                                model.state = .capturing1
//                            }
//                            catch {
//                                print("\(error)")
//                            }
                    }) {
                        Text("Start")
                            .padding(.horizontal, 15)
                            .padding(.vertical, 5)
                            .foregroundColor(.black)
                    }
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                // MARK: capturing
                if model.state == .capturing1 {
                    
                    Button(action: {
                        model.datasetWriter.finalizeProject()
                        self.showCaptureGalleryView = true
                        model.session?.pause()
                        logger.info("End Captue")
                        if model.captureFolderState != nil {
                            print("captures:\n \(model.captureFolderState?.captures)")
                            print("captureDir: \(model.captureFolderState?.captureDir)")
                        }
                    }) {
                        Text("End")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .foregroundColor(.black)
                    }
                    .background(Color.blue)
                    .cornerRadius(10)
                    
                    Spacer()
//                    Button(action: {
//                        model.captureFrame()
//                    }) {
//                        Text("Capture")
//                            .padding(.horizontal, 20)
//                            .padding(.vertical, 5)
//                            .foregroundColor(.black)
//                    }
//                    .background(Color.blue)
//                    .cornerRadius(10)
                    CaptureButton(model: model)
                }
            }
            .padding()
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
        Button(action: {
            model.captureFrame()
        }, label: {
            ManualCaptureButtonView()
//            if model.isAutoCaptureActive {
//                AutoCaptureButtonView(model: model)
//            } else {
//                ManualCaptureButtonView()
//            }
        })//.disabled(!model.isCameraAvailable || !model.readyToCapture)
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
//            model.stopMonitoringAcceleration()
//            print(ARWorldTrackingConfiguration.supportedVideoFormats)
            print("Anchor position: \(model.anchorPosition)")
            print("Camera position: \(model.cameraPosition)")
            let projectName = model.datasetWriter.projectName
            let imagePath = getAllCapturedImagePaths(projectName: projectName)
            print("imagePath = \(imagePath)")
            model.datasetWriter.uploadCapturedImages()
//            let size = model.calculateBoundingBoxSize()
//            print("Bounding box size: (\(size.x), \(size.y), \(size.z))")
//            print("originAnchor: \n \(model.originAnchor)")
//            model.callAPI()
//            print("checkpoints:\n \(model.checkpoints)")
        }) {
            Text("Debug")
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        var datasetWriter = DatasetWriter()
//        let model = ARViewModel(datasetWriter: datasetWriter)
//        ContentView(model: model)
//    }
//}
