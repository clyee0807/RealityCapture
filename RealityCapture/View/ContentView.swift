//
//  ContentView.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/4/4.
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
    
    var body: some View {
        ZStack{
            ZStack(alignment: .topTrailing) {
                ARViewContainer(viewModel).edgesIgnoringSafeArea(.all)
                VStack() {
                    HStack() {
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
                    Button(action: {
                        print("Anchor position: \(viewModel.anchorPosition)")
                        print("Camera position: \(viewModel.cameraPosition)")
//                        viewModel.
                    }) {
                        Text("Debug")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .background(.red)
                    
                    if case .Offline = viewModel.appState.appMode {
                        if viewModel.appState.writerState == .SessionNotStarted {
                            Spacer()
                            
                            Button(action: {
                                viewModel.resetWorldOrigin()
                            }) {
                                Text("Reset")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 5)
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            
                            Button(action: {
                                do {
                                    try viewModel.datasetWriter.initializeProject()
                                }
                                catch {
                                    print("\(error)")
                                }
                            }) {
                                Text("Start")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 5)
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                        }
                        
                        if viewModel.appState.writerState == .SessionStarted {
                            Spacer()
                            Button(action: {
                                viewModel.datasetWriter.finalizeProject()
                            }) {
                                Text("End")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 5)
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            Button(action: {
                                if let frame = viewModel.session?.currentFrame {
                                    viewModel.datasetWriter.writeFrameToDisk(frame: frame, viewModel: viewModel)
                                }
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

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: ARViewModel(datasetWriter: DatasetWriter()/*, ddsWriter: DDSWriter()*/))
            .previewInterfaceOrientation(.portrait)
    }
}
#endif
