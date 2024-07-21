//
//  TrainingStateView.swift
//  RealityCapture
//
//  Created by lychen on 2024/7/21.
//

import SwiftUI

struct TrainingStateView: View {
    @StateObject var viewModel: ARViewModel

    var body: some View {
        Text("Training...")
            .foregroundColor(.black)
            .padding()
    }
}

//struct TrainingStateViewPreviews: PreviewProvider {
//    static var previews: some View {
//        var datasetWriter = DatasetWriter()
//        let viewModel = ARViewModel(datasetWriter: datasetWriter)
//        TrainingStateView(viewModel: viewModel)
//    }
//}
