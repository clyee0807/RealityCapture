//
//  CaptureOverlayView+Buttons.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/3/28.
//  
//  Abstract:
//  The buttons for the full-screen overlay UI that control the capture

import SwiftUI
import RealityKit
import os

extension CaptureOverlayView {
    static let logger = Logger(subsystem: RealityCaptureApp.subsystem, category: "CaptureOverlayView+Buttons")
    
    @available(iOS 17.0, *)
    @MainActor
    struct NextButton: View {
        // @EnvironmentObject var appModel: AppDataModel
        var session: ObjectCaptureSession
//        @Binding var hasDetectionFailed: Bool
        
        var body: some View {
            Button(
                action: {
                    print("NEXT button clicked!")
                    performAction()
                    //appModel.setPreviewModelState(shown: true)
                },
                label: {
                    Text("NEXT")
                    .modifier(VisualEffectRoundedCorner())
                }
            )
        }
        
        private func performAction() {
            if case .ready = session.state {
                let hasDetectionFailed = !(session.startDetecting())
            } else if case .detecting = session.state {
                session.startCapturing()
            }
        }
    }
    
    @available(iOS 17.0, *)
    struct FilesButton: View {
        @EnvironmentObject var appModel: AppDataModel
        @State private var showDocumentBrowser = false

        var body: some View {
            Button(
                action: {
                    print("FILES button clicked!")
                    showDocumentBrowser = true
                },
                label: {
                    Image(systemName: "folder")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 22)
                        .foregroundColor(.white)
                })
            .padding(.bottom, 20)
            .padding(.horizontal, 10)
//            .sheet(isPresented: $showDocumentBrowser,
//                   onDismiss: { showDocumentBrowser = false },
//                   content: { DocumentBrowser(startingDir: appModel.scanFolderManager.rootScanFolder) })
        }
    
    }
    
    struct VisualEffectRoundedCorner: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(16.0)
                .font(.subheadline)
                .bold()
                .foregroundColor(.white)
                .background(.blue)
                //.environment(\.colorScheme, .dark)
                .cornerRadius(15)
                .multilineTextAlignment(.center)
        }
    }

    
}
