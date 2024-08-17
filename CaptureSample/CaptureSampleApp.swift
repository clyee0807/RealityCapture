/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Custom app subclass.
*/

import SwiftUI

@main
struct CaptureSampleApp: App {
    //var datasetWriter = DatasetWriter()
    
    //@StateObject var model = ARViewModel(datasetWriter: datasetWriter)
    
    var body: some Scene {
        WindowGroup {
            let datasetWriter = DatasetWriter()
            let model = ARViewModel(datasetWriter: datasetWriter)
            
            if #available(iOS 17.0, *) {
                NavigationStack{
                    InitView(model: model)
                }                // Force dark mode so the photos pop.
                .environment(\.colorScheme, .dark)
            } else {
                // Fallback on earlier versions
                NavigationView{
                    InitView(model: model)
                }
                // Force dark mode so the photos pop.
                .environment(\.colorScheme, .dark)
            }
        }
    }
}

