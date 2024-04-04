//
//  ARPreviewView.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/3/31.
//

import RealityKit
import ARKit
import Combine
import UIKit
import Foundation

class ARPreviewView: ARView {
  
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    dynamic required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init() {
        self.init(frame: UIScreen.main.bounds)
    }

    private func commonInit() {
       setupARSession()
       placeOneBlock()
    }
   
    private func setupARSession() {
       let configuration = ARWorldTrackingConfiguration()
       configuration.planeDetection = [.horizontal]
       configuration.environmentTexturing = .automatic
       
       if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
           configuration.frameSemantics.insert(.sceneDepth)
       }
       
       self.session.run(configuration)
    }
    
    func placeOneBlock() {
        let block = MeshResource.generateBox(size: 0.5)
        let material = SimpleMaterial(color: .blue, isMetallic: false)
        let entity = ModelEntity(mesh: block, materials: [material])
        
        let anchor = AnchorEntity(plane: .horizontal)
        anchor.addChild(entity)
        
        scene.addAnchor(anchor)
    }
    
    

}
    
//class ARPreviewView: UIView {
//  
//    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
//        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
//            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
//        }
//        return layer
//    }
//    
//    var session: AVCaptureSession? {
//        get {
//            return videoPreviewLayer.session
//        }
//        set {
//            videoPreviewLayer.session = newValue
//        }
//    }
//    
//    override class var layerClass: AnyClass {
//        return AVCaptureVideoPreviewLayer.self
//    }
// }
