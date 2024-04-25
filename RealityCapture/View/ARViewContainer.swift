//
//  ARViewContainer.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/4/4.
//

import SwiftUI
import RealityKit
import SceneKit
//import ARKit

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARViewModel
    
    init(_ vm: ARViewModel) {
        viewModel = vm
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let configuration = viewModel.createARConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.worldAlignment = .gravity
        configuration.isAutoFocusEnabled = true
        
        arView.debugOptions = [.showWorldOrigin]

        arView.session.run(configuration)
        arView.session.delegate = viewModel
        
        
        // Add tapping gesture, and add a new anchor and bounding box when tapped
        let tapGesture = UITapGestureRecognizer(target: context.coordinator,
                                             action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator,
                                             action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)
        
        
        viewModel.session = arView.session
        viewModel.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}



class Coordinator: NSObject {
    var parent: ARViewContainer
    var boundingBox: Entity?
    
    var anchor: AnchorEntity?
    var anchorPosition: SIMD3<Float>?
    var selectedEntity: Entity?
    
    var originAnchor: AnchorEntity?
    

    init(_ parent: ARViewContainer) {
        self.parent = parent
        self.selectedEntity = nil
        
        self.originAnchor = self.parent.viewModel.originAnchor
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        guard let arView = parent.viewModel.arView else { return }
        let location = sender.location(in: arView)
        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
        
        if let firstResult = results.first {
            if boundingBox == nil {
                let originAnchor = AnchorEntity(world: firstResult.worldTransform)
 
                let anchor = AnchorEntity()
                let anchorPosition = SIMD3<Float> (
                    firstResult.worldTransform.columns.3.x,
                    firstResult.worldTransform.columns.3.y,
                    firstResult.worldTransform.columns.3.z
                )
                anchor.position = anchorPosition
                originAnchor.position = anchorPosition
                print("originAnchor.position: \(originAnchor.position)")
                print("anchor.position: \(anchor.position)")
                
                // render a box at anchor position for debugging
//                let anchorPoint = AnchorPositionPoint(anchorPosition: anchorPosition)
//                anchor.addChild(anchorPoint)
                
                
                let boxSize: Float = 0.05
                let points = [
                    SIMD3<Float>(-boxSize, -boxSize, -boxSize),
                    SIMD3<Float>( boxSize, -boxSize, -boxSize),
                    SIMD3<Float>(-boxSize,  boxSize, -boxSize),
                    SIMD3<Float>( boxSize,  boxSize, -boxSize),
                    SIMD3<Float>(-boxSize, -boxSize,  boxSize),
                    SIMD3<Float>( boxSize, -boxSize,  boxSize),
                    SIMD3<Float>(-boxSize,  boxSize,  boxSize),
                    SIMD3<Float>( boxSize,  boxSize,  boxSize)
                ]
                boundingBox = BlackMirrorzBoundingBox(anchorPosition: anchorPosition, points: points, color: .blue)
                boundingBox?.name = "BoundingBox"
                
//                let heightEditor = BoundingBoxHeightEditor(anchorPosition: anchorPosition)
//                anchor.addChild(heightEditor)
                
//                anchor.addChild(boundingBox!)
//                arView.scene.addAnchor(anchor)
                originAnchor.addChild(boundingBox!)
                originAnchor.name = "originAnchor"
//                originAnchor.addChild(anchor)
                   
                parent.viewModel.updateAnchorPosition(originAnchor.position, originAnchor: originAnchor)
                arView.scene.addAnchor(originAnchor)
            }
            else {
                print("boundingBox already exists and tap")
                let hitTestResults = arView.hitTest(location, query: .nearest, mask: .all)
                print("hitTestResults: \(hitTestResults)")
//                if let firstHit = hitTestResults.first {
//                    print("firstHit: \(firstHit)")
//                }
                for result in hitTestResults {
                    print("Hit entity: \(result.entity.name)")
                }
                
            }
        }
    
    }

    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
//        guard let arView = parent.viewModel.arView else { return }
//        let location = sender.location(in: arView)
        guard let arView = parent.viewModel.arView, let originAnchor = parent.viewModel.originAnchor else { return }
        
        switch sender.state {
            case .began:
            print("In Pan Gesture Began state, originAnchor.position: \(originAnchor.position)")
                // Perform a hit test to find an existing anchor or place a new one
//                let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
//                if let firstResult = results.first {
//                    print("firstResult: \(firstResult)")
//                }
            case .changed:
                // Rotate the bounding box based on the pan gesture
                let translation = sender.translation(in: sender.view)
                let angle = Float(translation.x) / 100.0
                if let boundingBox = self.boundingBox {
//                    let rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
//                    boundingBox.orientation = rotation * boundingBox.orientation
                    
                    let relativePosition = boundingBox.position - originAnchor.position
                    let positionMatrix = simd_float4(relativePosition.x, relativePosition.y, relativePosition.z, 1.0)
                    
                    let rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
                    let rotationMatrix = simd_float4x4(rotation)

                    let rotatedPosition = simd_mul(rotationMatrix, positionMatrix)

                    boundingBox.position = SIMD3<Float>(rotatedPosition.x, rotatedPosition.y, rotatedPosition.z) + originAnchor.position
                    boundingBox.orientation = rotation * boundingBox.orientation

                }
                sender.setTranslation(.zero, in: sender.view) // reset gesture
                break
            case .ended:
                print("In Pan Gesture Ended state")
                break
            default:
                break
        }
        
    }
    
}

