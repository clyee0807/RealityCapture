/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Custom app subclass.
*/

import SwiftUI

@main
struct CaptureSampleApp: App {
    @StateObject var model = CameraViewModel()
    
    var body: some Scene {
        WindowGroup {
            if #available(iOS 16.0, *) {
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
