//
//  CaptureOverlayView.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/3/28.
//

import Foundation
import SwiftUI
import RealityKit

@available(iOS 17.0, *)
struct CaptureOverlayView: View {
    @EnvironmentObject var appModel: AppDataModel // can access AppDataModel and use it's attributes
    var session: ObjectCaptureSession
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                NextButton(session: session)
            }.padding(12)
        }
    }
}
