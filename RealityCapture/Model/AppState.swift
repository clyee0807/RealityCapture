//
//  AppState.swift
//  RealityCapture
//
//  Created by lychen on 2024/4/4.
//

import Foundation
import Metal
import MetalKit

struct AppState {
    var writerState: DatasetWriter.SessionState = .SessionNotStarted
    
    var trackingState = ""
    var projectName = ""
    var numFrames = 0
    var supportsDepth = false
    
    var ddsPeers: UInt32 = 0
    var ddsReady = false
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
