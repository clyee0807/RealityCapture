//
//  CaptureView.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/3/31.
//

import Foundation
import SwiftUI

struct CaptureView: View {
    static let buttonBackingOpacity: CGFloat = 0.15
    
    @ObservedObject var model: CameraViewModel
    @State private var showInfo: Bool = false
    
    let aspectRatio: CGFloat = 4.0 / 3.0
    let previewCornerRadius: CGFloat = 15.0
    
    var body: some View {
        NavigationView {
            GeometryReader { geometryReader in
                // Place the CameraPreviewView at the bottom of the stack.
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    // Center the preview view vertically. Place a clip frame
                    // around the live preview and round the corners.
                    VStack {
                        Spacer()
                        CapturePreviewView(session: model.session)
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
                    }
                    
                    VStack {
                        // The app shows this view when showInfo is true.
//                        ScanToolbarView(model: model, showInfo: $showInfo).padding(.horizontal)
//                        if showInfo {
//                            InfoPanelView(model: model)
//                                .padding(.horizontal).padding(.top)
//                        }
                        Spacer()
                        CaptureButtonPanelView(model: model, width: geometryReader.size.width)
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
//            HStack {
//                Spacer()
//                CaptureModeButton(model: model,
//                                  frameWidth: width / 3)
//                    .padding(.horizontal)
//            }
        }
    }
}

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
//                AutoCaptureButtonView(model: model)
            } else {
                ManualCaptureButtonView()
            }
        }).disabled(!model.isCameraAvailable || !model.readyToCapture)
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
                            .opacity(Double(CaptureView.buttonBackingOpacity))
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
