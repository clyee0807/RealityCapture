/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's top-level view.
*/

import SwiftUI

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
    
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 20) {
                if model.appState.writerState == .SessionNotStarted {
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
                        do {
                            try model.datasetWriter.initializeProject()
                            model.state = .capturing1
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
                
                if model.appState.writerState == .SessionStarted {
                    Spacer()
                    Button(action: {
                        model.datasetWriter.finalizeProject()
                        model.state = .detecting
                    }) {
                        Text("End")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 5)
                            .foregroundColor(.black)
                    }
                    .background(Color.blue)
                    .cornerRadius(10)
                    Button(action: {
                        model.captureFrame()
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
