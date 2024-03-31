//
//  CapturePrimaryView.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/3/27.
//

import Foundation
import SwiftUI
import RealityKit

struct CapturePrimaryView: View {
    @EnvironmentObject var appModel: AppDataModel
    var session: ObjectCaptureSession
    
    var body: some View {
        ZStack {
            ObjectCaptureView(session: session)
            CaptureOverlayView(session: session/*, showInfo: $showInfo*/)
        }
    }
}
