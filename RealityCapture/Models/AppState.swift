//
//  AppState.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/4/4.
//

import Foundation
import Metal
import MetalKit

enum AppMode: Int, Codable {
    case Online
    case Offline
}

struct AppState {
    var appMode: AppMode = .Offline
    var writerState: DatasetWriter.SessionState = .SessionNotStarted
    
    var trackingState = ""
    var projectName = ""
    var numFrames = 0
    var supportsDepth = false
//    var stream = false
    
    var ddsPeers: UInt32 = 0
    var ddsReady = false
}

struct AppSettings: Codable {
    var zipDataset = true  // capture 完要不要壓縮
    var startingAppMode = AppMode.Online // App default mode
}



struct MetalState {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    
    var sharedUniformBuffer: MTLBuffer!
    var imagePlaneVertexBuffer: MTLBuffer!
    
    var capturedImagePipelineState: MTLRenderPipelineState!
    var capturedImageTextureY: CVMetalTexture?
    var capturedImageTextureCbCr: CVMetalTexture?
    var capturedImageTextureCache: CVMetalTextureCache!
}
