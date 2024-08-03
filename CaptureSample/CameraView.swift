/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that displays the camera image and capture button.
*/
import Foundation
import SwiftUI

/// This is the app's primary view. It contains a preview area, a capture button, and a thumbnail view
/// showing the most recenty captured image.
struct CameraView: View {
    static let buttonBackingOpacity: CGFloat = 0.15
    
    @ObservedObject var model: CameraViewModel
    @State private var showInfo: Bool = false
    
    
    let aspectRatio: CGFloat = 4.0 / 3.0
    let previewCornerRadius: CGFloat = 15.0
    
//    var body: some View {
//        NavigationView {
//            GeometryReader { geometryReader in
//                // Place the CameraPreviewView at the bottom of the stack.
//                ZStack {
//                    Color.black.edgesIgnoringSafeArea(.all)
//                    
//                    // Center the preview view vertically. Place a clip frame
//                    // around the live preview and round the corners.
//                    VStack {
//                        // add info at here.
//                        Spacer()
//                        CameraPreviewView(session: model.session)
//                            .frame(width: geometryReader.size.width,
//                                   height: geometryReader.size.width * aspectRatio,
//                                   alignment: .center)
//                            .clipShape(RoundedRectangle(cornerRadius: previewCornerRadius))
//                            .onAppear { model.startSession() }
//                            .onDisappear { model.pauseSession() }
//                            .overlay(
//                                Image("ObjectReticle")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .padding(.all))
//                        
//                        Spacer()
//                    }
//                    VStack {
//                        // The app shows this view when showInfo is true.
//                        ScanToolbarView(model: model, showInfo: $showInfo).padding(.horizontal)
//                        if showInfo {
//                            InfoPanelView(model: model)
//                                .padding(.horizontal).padding(.top)
//                        }
//                        Spacer()
//                        CaptureButtonPanelView(model: model, width: geometryReader.size.width)
//                    }
//                }
//            }
//            .navigationTitle(Text("Scan"))
//            .navigationBarTitle("Scan")
//            .navigationBarHidden(true)
//            .navigationBarTitleDisplayMode(.inline)
//        }
//    }
    var body: some View {
            NavigationView {
                GeometryReader { geometryReader in
                    ZStack {
                        Color.black.edgesIgnoringSafeArea(.all)
                        
                        VStack {
                            Spacer(minLength: 50)
                            CameraPreviewView(session: model.session)
                                .frame(width: geometryReader.size.width,
                                       height: geometryReader.size.width * aspectRatio,
                                       alignment: .center)
                                .clipShape(RoundedRectangle(cornerRadius: previewCornerRadius))
                                .onAppear { model.startSession() }
                                .onDisappear { model.pauseSession() }
                                .overlay(
                                    Image("ObjectReticle")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(.all))
                            Spacer()
                            ParametersbarView(model: model)
                                .padding(.vertical, 1)
                            
//                            Spacer()
                            CaptureButtonPanelView(model: model, width: geometryReader.size.width)
                                .padding(.bottom)
                        }
                        
                        VStack {
                            // The app shows this view when showInfo is true.
                            ScanToolbarView(model: model, showInfo: $showInfo)
                                .padding(.horizontal)
                            
                            if showInfo {
                                InfoPanelView(model: model)
                                    .padding(.horizontal)
                                    .padding(.top)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .navigationTitle(Text("Scan"))
                .navigationBarTitle("Scan")
                .navigationBarHidden(true)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
}

/// This view displays the image thumbnail, capture button, and capture mode button.
struct CaptureButtonPanelView: View {
    @ObservedObject var model: CameraViewModel
    
    /// This property stores the full width of the bar. The view uses this to place items.
    var width: CGFloat
    
    var body: some View {
        // Add the bottom panel, which contains the thumbnail and capture button.
        ZStack(alignment: .center) {
            HStack {
                ThumbnailView(model: model)
                    .frame(width: width / 3)
                    .padding(.horizontal)
                Spacer()
            }
            HStack {
                Spacer()
                CaptureButton(model: model)
                Spacer()
            }
            HStack {
                Spacer()
                CaptureModeButton(model: model,
                                  frameWidth: width / 3)
                    .padding(.horizontal)
            }
        }
    }
}

struct SliderView: View {
    @ObservedObject var model: CameraViewModel
//    @Binding var sliderValue: Double
    @State private var sliderValue = 0.0
    @Binding var sliderType: Int
    
    var body: some View {
            VStack {
                Text("Adjust Parameter")
                    .font(.caption)
                    .foregroundColor(.black)
                    .padding()
                
                Text("\(Double(sliderValue))")
                    .font(.caption)
                    .foregroundColor(.black)
                if sliderType == 0
                {
                    Slider(value: $sliderValue, in: 3000...8000, step: 50)
                        .padding()
                        .onChange(of: sliderValue) { newValue in
                                if sliderType == 0 {
                                    print("newValue: \(newValue)")
                                    model.setWhiteBalanceGains(temperature: Float(newValue))
                                }
                            }
                        .onAppear {
                                sliderValue = model.getWhiteBalanceGains()
                            }
                }
                else if sliderType == 1
                {
                    Slider(value: $sliderValue, in: 0.0...5.0, step: 0.05)
                        .padding()
                        .onChange(of: sliderValue) { newValue in
                                if sliderType == 1 {
                                    print("newValue: \(newValue)")
                                    model.setIntervalSecs(sec: newValue)
                                }
                            }
                }
                else if sliderType == 2
                {
                    Slider(value: $sliderValue, in: 0.0...5.0, step: 0.05)
                        .padding()
                        .onChange(of: sliderValue) { newValue in
                                if sliderType == 2 {
                                    print("newValue: \(newValue)")
                                    model.setIntervalSecs(sec: newValue)
                                }
                            }
                        .onAppear {
                                    sliderValue = model.getIntervalSecs()
                                }
                }
                Text("Value: \(Int(sliderValue))")
                    .font(.caption)
                    .foregroundColor(.black)
                    .padding()
            }
            .padding()
            .background(Color.white)
        }
}

struct ParametersbarView: View{
    @ObservedObject var model: CameraViewModel
    @State private var showSlider = false
    @State private var showSliderType = 0
    var body: some View {
        ZStack {
//            RoundedRectangle(cornerRadius: 10)
//                            .fill(Color.gray.opacity(0.2))
//                            .frame(height: 60)
//                            .padding(.horizontal, 20)
            HStack {
                Spacer()
                Button(action: {
                    print("Pressed Info!")
                    withAnimation {
                        showSlider.toggle()
                        showSliderType = 0
                        if model.parametersLocked != true
                        {
                            model.toggleCameraParametersLock()
                        }
                    }
                }, label: {
                    Image(systemName: "plus.slash.minus").foregroundColor(Color.blue)
                        .font(.largeTitle)
                        .padding()
                        .overlay(
//                            RoundedRectangle(cornerRadius: 10)
//                                .stroke(Color.gray, lineWidth: 2)
                            RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 60, height: 60)
                                            .padding(.horizontal, 20)
                            
                        )
                })
                Spacer()
                Button(action: {
                    print("Pressed Info!")
                    withAnimation {
                        showSlider.toggle()
                        showSliderType = 1
                        if model.parametersLocked != true
                        {
                            model.toggleCameraParametersLock()
                        }
                    }
                }, label: {
                    Image(systemName: "sun.max.fill").foregroundColor(Color.blue)
                        .font(.largeTitle)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 60, height: 60)
                                            .padding(.horizontal, 20)
                        )
                })
                Spacer()
                Button(action: {
                    print("Pressed toggle!")
                    withAnimation {
                        showSlider.toggle()
                        showSliderType = 2
                    }
                }, label: {
                    Image(systemName: "timer").foregroundColor(Color.blue)
                        .font(.largeTitle)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 60, height: 60)
                                            .padding(.horizontal, 20)
                        )
                })
                Spacer()
                Button(action: {
                    print("Pressed toggle!")
                    withAnimation {
                        model.toggleCameraParametersLock()
                    }
                }, label: {
                    Image(systemName: model.parametersLocked ? "lock.fill" : "lock.open.fill").foregroundColor(Color.blue)
                        .font(.largeTitle)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 60, height: 60)
                                            .padding(.horizontal, 20)
                        )
                })
            }
            .padding(.horizontal, 5)
        }
        ZStack{
            if showSlider {
                SliderView(model: model, sliderType: $showSliderType)
                        .frame(width: 300, height: 100)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                        .padding(.top, 10)
                }
        }
    }
}

/// This is a custom "toolbar" view the app displays at the top of the screen. It includes the current capture
/// status and buttons for help and detailed information. The user can tap the entire top panel to
/// open or close the information panel.
struct ScanToolbarView: View {
    @ObservedObject var model: CameraViewModel
    @Binding var showInfo: Bool
    @State private var showCaptureFolderView = false
    @State private var isFromButton = false
    
    var body: some View {
        ZStack {
            HStack {
                SystemStatusIcon(model: model)
                Button(action: {
                    print("Pressed Info!")
                    withAnimation {
                        showInfo.toggle()
                    }
                }, label: {
                    Image(systemName: "info.circle").foregroundColor(Color.blue)
                })
//                Button(action: {
//                    print("Pressed toggle!")
//                    withAnimation {
//                        model.toggleCameraParametersLock()
//                    }
//                }, label: {
//                    Image(systemName: model.parametersLocked ? "lock.fill" : "lock.open.fill").foregroundColor(Color.blue)
//                })
                Text(model.info)
                Spacer()
                
                Button(action: {
                    print("Pressed file!")
                    withAnimation {
                        self.showCaptureFolderView = true
                        self.isFromButton = true
                    }
                }, label: {
                    Image(systemName: "folder.fill").foregroundColor(Color.blue)
                })
                
                NavigationLink(destination: CaptureFoldersView(model: model, isFromButton: isFromButton),
                                       isActive: self.$showCaptureFolderView) {
                            EmptyView()
                        }
                        .frame(width: 0, height: 0)
                        .disabled(true)

                NavigationLink(destination: HelpPageView()) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(Color.blue)
                }
            }
            
            if showInfo {
                Text("Current Capture Info")
                    .font(.caption)
                    .onTapGesture {
                        print("showInfo toggle!")
                        withAnimation {
                            showInfo.toggle()
                        }
                    }
            }
        }
    }
}

/// This capture button view is modeled after the Camera app button. The view changes shape when the
/// user starts shooting in automatic mode.
struct CaptureButton: View {
    static let outerDiameter: CGFloat = 80
    static let strokeWidth: CGFloat = 4
    static let innerPadding: CGFloat = 10
    static let innerDiameter: CGFloat = CaptureButton.outerDiameter -
        CaptureButton.strokeWidth - CaptureButton.innerPadding
    static let rootTwoOverTwo: CGFloat = CGFloat(2.0.squareRoot() / 2.0)
    static let squareDiameter: CGFloat = CaptureButton.innerDiameter * CaptureButton.rootTwoOverTwo -
        CaptureButton.innerPadding
    
    @ObservedObject var model: CameraViewModel
    
    init(model: CameraViewModel) {
        self.model = model
    }
    
    var body: some View {
        Button(action: {
            model.captureButtonPressed()
        }, label: {
            if model.isAutoCaptureActive {
                AutoCaptureButtonView(model: model)
            } else {
                ManualCaptureButtonView()
            }
        }).disabled(!model.isCameraAvailable || !model.readyToCapture)
    }
}

/// This is a helper view for the `CaptureButton`. It implements the shape for automatic capture mode.
struct AutoCaptureButtonView: View {
    @ObservedObject var model: CameraViewModel
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.red)
                .frame(width: CaptureButton.squareDiameter,
                       height: CaptureButton.squareDiameter,
                       alignment: .center)
                .cornerRadius(5)
            TimerView(model: model, diameter: CaptureButton.outerDiameter)
        }
    }
}

/// This is a helper view for the `CaptureButton`. It implements the shape for manual capture mode.
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

struct CaptureModeButton: View {
    static let toggleDiameter = CaptureButton.outerDiameter / 3.0
    static let backingDiameter = CaptureModeButton.toggleDiameter * 2.0
    
    @ObservedObject var model: CameraViewModel
    var frameWidth: CGFloat
    
    var body: some View {
        VStack(alignment: .center/*@END_MENU_TOKEN@*/, spacing: 2) {
            Button(action: {
                withAnimation {
                    model.advanceToNextCaptureMode()
                }
            }, label: {
                ZStack {
                    Circle()
                        .frame(width: CaptureModeButton.backingDiameter,
                               height: CaptureModeButton.backingDiameter)
                        .foregroundColor(Color.white)
                        .opacity(Double(CameraView.buttonBackingOpacity))
                    Circle()
                        .frame(width: CaptureModeButton.toggleDiameter,
                               height: CaptureModeButton.toggleDiameter)
                        .foregroundColor(Color.white)
                    switch model.captureMode {
                    case .automatic:
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
            if case .automatic = model.captureMode {
                Text("Auto Capture")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        // This frame centers the view and keeps it from reflowing when the view has a caption.
        // The view uses .top so the button won't move and the text will animate in and out.
        .frame(width: frameWidth, height: CaptureModeButton.backingDiameter, alignment: .top)
    }
}

/// This view shows a thumbnail of the last photo captured, similar to the  iPhone's Camera app. If there isn't
/// a previous photo, this view shows a placeholder.
struct ThumbnailView: View {
    private let thumbnailFrameWidth: CGFloat = 60.0
    private let thumbnailFrameHeight: CGFloat = 60.0
    private let thumbnailFrameCornerRadius: CGFloat = 10.0
    private let thumbnailStrokeWidth: CGFloat = 2
    
    @ObservedObject var model: CameraViewModel
    
    init(model: CameraViewModel) {
        self.model = model
    }
    
    var body: some View {
        NavigationLink(destination: CaptureGalleryView(model: model)) {
            if let capture = model.lastCapture {
                if let preview = capture.previewUiImage {
                    ThumbnailImageView(uiImage: preview,
                                       width: thumbnailFrameWidth,
                                       height: thumbnailFrameHeight,
                                       cornerRadius: thumbnailFrameCornerRadius,
                                       strokeWidth: thumbnailStrokeWidth)
                } else {
                    // Use full-size if no preview.
                    ThumbnailImageView(uiImage: capture.uiImage,
                                       width: thumbnailFrameWidth,
                                       height: thumbnailFrameHeight,
                                       cornerRadius: thumbnailFrameCornerRadius,
                                       strokeWidth: thumbnailStrokeWidth)
                }
            } else {  // When no image, use icon from the app bundle.
                Image(systemName: "photo.on.rectangle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(16)
                    .frame(width: thumbnailFrameWidth, height: thumbnailFrameHeight)
                    .foregroundColor(.primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: thumbnailFrameCornerRadius)
                            .fill(Color.white)
                            .opacity(Double(CameraView.buttonBackingOpacity))
                            .frame(width: thumbnailFrameWidth,
                                   height: thumbnailFrameWidth,
                                   alignment: .center)
                    )
            }
        }
    }
}

struct ThumbnailImageView: View {
    var uiImage: UIImage
    var thumbnailFrameWidth: CGFloat
    var thumbnailFrameHeight: CGFloat
    var thumbnailFrameCornerRadius: CGFloat
    var thumbnailStrokeWidth: CGFloat
    
    init(uiImage: UIImage, width: CGFloat, height: CGFloat, cornerRadius: CGFloat,
         strokeWidth: CGFloat) {
        self.uiImage = uiImage
        self.thumbnailFrameWidth = width
        self.thumbnailFrameHeight = height
        self.thumbnailFrameCornerRadius = cornerRadius
        self.thumbnailStrokeWidth = strokeWidth
    }
    var body: some View {
        Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: thumbnailFrameWidth, height: thumbnailFrameHeight)
            .cornerRadius(thumbnailFrameCornerRadius)
            .clipped()
            .overlay(RoundedRectangle(cornerRadius: thumbnailFrameCornerRadius)
                        .stroke(Color.primary, lineWidth: thumbnailStrokeWidth))
            .shadow(radius: 10)
    }
}
