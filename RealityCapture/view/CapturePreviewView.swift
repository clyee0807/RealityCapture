//
//  CaptureOverlayView.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/3/28.
//

import AVFoundation
import SwiftUI
import RealityKit
import os

@available(iOS 17.0, *)
struct CapturePreviewView: UIViewRepresentable {
    
    static var logger = Logger(subsystem: RealityCaptureApp.subsystem, category: "CapturePreviewView")

    let session: AVCaptureSession
    init(session: AVCaptureSession) {
        self.session = session
    }
    
    func makeUIView(context: Context) -> ARPreviewView {
        ARPreviewView()
    }
    
    func updateUIView(_ uiView: ARPreviewView, context: Context) {
        
    }
}
