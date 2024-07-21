//
//  InitializeStateView.swift
//  RealityCapture
//
//  Created by lychen on 2024/7/21.
//

import SwiftUI

struct InitializeStateView: View {
    @StateObject var viewModel: ARViewModel

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Spacer()
                Button(action: {
                    viewModel.state = .detecting
                }) {
                    Text("New Capture")
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        .foregroundColor(.white)
                }
                .background(Color.blue)
                .cornerRadius(10)
                
                Button(action: {
                    viewModel.state = .readyToRecapture
                }) {
                    Text("Continue Capture")
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        .foregroundColor(.white)
                }
                .background(Color.blue)
                .cornerRadius(10)
                Spacer()
            }
            Spacer()
        }
    }
}
