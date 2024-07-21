//
//  FeedbackStateView.swift
//  RealityCapture
//
//  Created by lychen on 2024/7/21.
//

import SwiftUI

struct FeedbackStateView: View {
    @StateObject var viewModel: ARViewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Button(action: {
                viewModel.state = .initialize
            }) {
                Text("Complete")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .foregroundColor(.white)
            }
            .background(Color.blue)
            .cornerRadius(10)
            
            Button(action: {
                viewModel.state = .readyToRecapture
            }) {
                Text("Recapture")
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .foregroundColor(.white)
            }
            .background(Color.blue)
            .cornerRadius(10)
            Spacer()
        }
    }
}

struct FeedbackStateViewPreviews: PreviewProvider {
    static var previews: some View {
        var datasetWriter = DatasetWriter()
        let viewModel = ARViewModel(datasetWriter: datasetWriter)
        FeedbackStateView(viewModel: viewModel)
    }
}
