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



enum NewAppState: String, CustomStringConvertible {
    var description: String { rawValue }

    case notSet
    
    case initialize  // 初始化頁面
    case detecting   // 定位 AR Configuration
    case positioning // bounding box
    case capturing1  // 動態拍攝
    case capturing2
    case updloading  // 上傳頁面
    case training    // 等待上傳中頁面
    case result      // 顯示重建結果頁面
    case browsing    // capture list
    
    case failed
}
