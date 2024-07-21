//
//  ReadyToRecaptureStateView.swift
//  RealityCapture
//
//  Created by lychen on 2024/7/21.
//

import SwiftUI

struct ReadyToRecaptureStateView: View {
    @StateObject var viewModel: ARViewModel

    var body: some View {
        Button(action: {
            viewModel.state = .initialize
        }) {
            Text("Start")
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
                .foregroundColor(.white)
        }
        .background(Color.blue)
        .cornerRadius(10)
    }
}

struct ReadyToRecaptureStateViewPreviews: PreviewProvider {
    static var previews: some View {
        var datasetWriter = DatasetWriter()
        let viewModel = ARViewModel(datasetWriter: datasetWriter)
        ReadyToRecaptureStateView(viewModel: viewModel)
    }
}
