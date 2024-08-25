//
//  Utils.swift
//  RealityCapture
//
//  Created by lychen on 2024/4/4.
//

import Foundation
import ARKit
import SwiftUI

func trackingStateToString(_ trackingState: ARCamera.TrackingState) -> String {
    switch trackingState {
        case .notAvailable: return "Not Available"
        case .normal: return "Tracking Normal"
        case .limited(.excessiveMotion): return "Excessive Motion"
        case .limited(.initializing): return "Tracking Initializing"
        case .limited(.insufficientFeatures): return  "Insufficient Features"
        default: return "Unknown"
    }
}

func tupleFromTransform(_ t: matrix_float4x4) -> (Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float) {
    let tuple = (t.columns.0.x, t.columns.0.y, t.columns.0.z, t.columns.0.w,
        t.columns.1.x, t.columns.1.y, t.columns.1.z, t.columns.1.w,
        t.columns.2.x, t.columns.2.y, t.columns.2.z, t.columns.2.w,
        t.columns.3.x, t.columns.3.y, t.columns.3.z, t.columns.3.w
    )
    return tuple
}

func arrayFromTransform(_ transform: matrix_float4x4) -> [[Float]] {
    var array: [[Float]] = Array(repeating: Array(repeating:Float(), count: 4), count: 4)
    array[0] = [transform.columns.0.x, transform.columns.1.x, transform.columns.2.x, transform.columns.3.x]
    array[1] = [transform.columns.0.y, transform.columns.1.y, transform.columns.2.y, transform.columns.3.y]
    array[2] = [transform.columns.0.z, transform.columns.1.z, transform.columns.2.z, transform.columns.3.z]
    array[3] = [transform.columns.0.w, transform.columns.1.w, transform.columns.2.w, transform.columns.3.w]
    return array
}

func arrayFromTransform(_ transform: matrix_float3x3) -> [[Float]] {
    var array: [[Float]] = Array(repeating: Array(repeating:Float(), count: 3), count: 3)
    array[0] = [transform.columns.0.x, transform.columns.1.x, transform.columns.2.x]
    array[1] = [transform.columns.0.y, transform.columns.1.y, transform.columns.2.y]
    array[2] = [transform.columns.0.z, transform.columns.1.z, transform.columns.2.z]
    return array
}

func pixelBufferToUIImage(pixelBuffer: CVPixelBuffer) -> UIImage {
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let context = CIContext(options: nil)
    let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
    let uiImage = UIImage(cgImage: cgImage!)
    return uiImage
}

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]   // file:///var/mobile/Containers/Data/Application/5345AC6A-5F6D-414C-BB83-69561FF810B8/Documents/
}

func getAllCapturedImagePaths(projectName: String) -> [URL] {  // ex. projectName = 240729124223
    let projectDir = getDocumentsDirectory().appendingPathComponent(projectName)
    
    let fileManager = FileManager.default
    let imagesDir = projectDir//.appendingPathComponent("images")
    print("getAllCapturedImagePaths(), imagesDir = \(imagesDir)")
    do {
        let fileURLs = try fileManager.contentsOfDirectory(at: imagesDir, includingPropertiesForKeys: nil)
        return fileURLs.filter { $0.pathExtension == "png" }
    } catch {
        print("Error while enumerating files \(imagesDir.path): \(error.localizedDescription)")
        return []
    }
}


class YUVToRGBFilter {
    
    var device: MTLDevice
    var defaultLib: MTLLibrary?
    var shader: MTLFunction?
    var commandQueue: MTLCommandQueue?
    var commandEncoder: MTLComputeCommandEncoder?
    var pipelineState: MTLComputePipelineState?
    var width: UInt32 = 0
    var height: UInt32 = 0
    let threadsPerBlock = MTLSize(width: 16, height: 16, depth: 1)
    
    var capturedImagePipelineState: MTLRenderPipelineState!
    var capturedImageTextureY: CVMetalTexture?
    var capturedImageTextureCbCr: CVMetalTexture?
    var capturedImageTextureCache: CVMetalTextureCache!
    var rgbBuffer: MTLBuffer!
    
    init() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.defaultLib = self.device.makeDefaultLibrary()
        self.shader = self.defaultLib?.makeFunction(name: "yuv2rgb_kernel")
        self.commandQueue = self.device.makeCommandQueue()
        
        // Create captured image texture cache
        var textureCache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(nil, nil, self.device, nil, &textureCache)
        self.capturedImageTextureCache = textureCache
        
        if let shader = self.shader {
            do {
                try self.pipelineState = self.device.makeComputePipelineState(function: shader)
            } catch {
                fatalError("unable to make compute pipeline")
            }
        }
        else {
            fatalError("unable to make compute pipeline")
        }
    }
    
    func getBlockDimensions() -> MTLSize {
        let blockWidth = Int(width) / self.threadsPerBlock.width
        let blockHeight = Int(height) / self.threadsPerBlock.height
        return MTLSizeMake(blockWidth, blockHeight, 1)
    }
    
    
    func createTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> CVMetalTexture? {
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, capturedImageTextureCache, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)
        if status != kCVReturnSuccess {
            texture = nil
        }
        return texture
    }
    
    func updateCapturedImageTextures(frame: ARFrame) {
        // Create two textures (Y and CbCr) from the provided frame's captured image
        let pixelBuffer = frame.capturedImage
        if (CVPixelBufferGetPlaneCount(pixelBuffer) < 2) {
            return
        }
        capturedImageTextureY = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat:.r8Unorm, planeIndex:0)
        capturedImageTextureCbCr = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat:.rg8Unorm, planeIndex:1)
        
        let w = Int(frame.camera.imageResolution.width)
        let h = Int(frame.camera.imageResolution.height)
        if(w != self.width || h != self.height) {
            rgbBuffer = device.makeBuffer(length: w*h*3, options: .storageModeShared)
        }
        width = UInt32(w)
        height = UInt32(h)

    }
    
    func applyFilter(frame:ARFrame) {
        updateCapturedImageTextures(frame: frame)
        guard let buffer = self.commandQueue?.makeCommandBuffer(), let encoder = buffer.makeComputeCommandEncoder() else {
            return;
        }
        encoder.setComputePipelineState(self.pipelineState!)
        encoder.setTextures([CVMetalTextureGetTexture(capturedImageTextureY!), CVMetalTextureGetTexture(capturedImageTextureCbCr!)], range: 0..<2)
        encoder.setBuffer(rgbBuffer, offset: 0, index: 0)
        encoder.dispatchThreadgroups(self.getBlockDimensions(), threadsPerThreadgroup: threadsPerBlock)
        encoder.endEncoding()
        buffer.commit()
        buffer.waitUntilCompleted()
    }
    
}


//
//  SwipeBackExtension.swift
//  CaptureSample
//
//  Created by ryan on 2024/8/14.
//  Copyright © 2024 Apple. All rights reserved.
//

/// this extension enables swiping from left edge to navigate to previous page without navigation bar
/// ref: https://stackoverflow.com/questions/59921239/hide-navigation-bar-without-losing-swipe-back-gesture-in-swiftui

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
