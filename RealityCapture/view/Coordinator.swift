//
//  Coordinator.swift
//  RealityCapture
//
//  Created by lychen on 2024/7/15.
//

import Foundation
import SwiftUI
import RealityKit
import SceneKit

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
                parent.viewModel.state = .detecting
                
                let originAnchor = AnchorEntity(world: firstResult.worldTransform)
 
                let anchorPosition = SIMD3<Float> (
                    firstResult.worldTransform.columns.3.x,
                    firstResult.worldTransform.columns.3.y,
                    firstResult.worldTransform.columns.3.z
                )
                originAnchor.position = anchorPosition
                print("originAnchor.position: \(originAnchor.position)")
                
                // render a box at anchor position for debugging
//                let anchorPoint = AnchorPositionPoint(anchorPosition: anchorPosition)
//                originAnchor.addChild(anchorPoint)
                
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
                
                
                originAnchor.addChild(boundingBox!)
                originAnchor.name = "originAnchor"
                   
                parent.viewModel.updateAnchorPosition(originAnchor.position, originAnchor: originAnchor)
                arView.scene.addAnchor(originAnchor)
            }
            else {
                print("boundingBox already exists and tap")
                let hitTestResults = arView.hitTest(location, query: .nearest, mask: .all)
                hitEntity = hitTestResults.first?.entity
                if let entity = hitEntity {
                    print("hitEntity: \(entity.name)")
                }
            }
        }
    }
    
    private var initialX: CGFloat = 0.0
    private var initialY: CGFloat = 0.0
    private var hitEntity: Entity? = nil
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        if parent.viewModel.state == .detecting {
            guard let arView = parent.viewModel.arView, let originAnchor = parent.viewModel.originAnchor else { return }
            let location = sender.location(in: arView)
            
            switch sender.state {
            case .began:
                print("In Pan Gesture Began state, originAnchor.position: \(originAnchor.position)")
                let hitTestResults = arView.hitTest(location, query: .nearest, mask: .all)
                hitEntity = hitTestResults.first?.entity
                if let entity = hitEntity {
//                    print("hitEntity: \(entity.name)")
                }
                initialX = location.x
                initialY = location.y
                
            case .changed:
                if hitEntity?.name == "heightEditor" {
                    moveHeightEditor(location: location)
                } else if hitEntity?.name == "widthEditor"{
                    moveWidthEditor(location: location)
                } else if hitEntity?.name == "depthEditor" {
                    moveDepthEditor(location: location)
                } else {
                    // Rotate the bounding box
                    let translation = sender.translation(in: sender.view)
                    let angle = Float(translation.x) / 100.0
                    if let boundingBox = self.boundingBox {
                        let relativePosition = boundingBox.position - originAnchor.position
                        let positionMatrix = simd_float4(relativePosition.x, relativePosition.y, relativePosition.z, 1.0)
                        
                        let rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
                        let rotationMatrix = simd_float4x4(rotation)
                        
                        let rotatedPosition = simd_mul(rotationMatrix, positionMatrix)
                        
                        boundingBox.position = SIMD3<Float>(rotatedPosition.x, rotatedPosition.y, rotatedPosition.z) + originAnchor.position
                        boundingBox.orientation = rotation * boundingBox.orientation
                        
                    }
                    sender.setTranslation(.zero, in: sender.view) // reset gesture
                }
            case .ended:
                print("In Pan Gesture Ended state")
                hitEntity = nil
                break
            default:
                break
            }
        }
    }
    
    // MARK: - Editors
    // heightEditor
    func moveHeightEditor(location: CGPoint) {
        let screenDeltaY = location.y - initialY // 計算螢幕上移動距離
        print("screenDeltaY: \(screenDeltaY)")
        initialY = location.y
        
        let worldDeltaY = Float(screenDeltaY) / 5000 // 轉換成空間移動距離
        
        if let boundingBox = self.boundingBox as? BlackMirrorzBoundingBox {
            var newPosition = boundingBox.heightEditor?.position
            newPosition?.y -= worldDeltaY
            boundingBox.heightEditor?.position = newPosition!
            updateLineEntityByHeightEditor(deltaY: -worldDeltaY)
        }
    }
    
    func updateLineEntityByHeightEditor(deltaY: Float) {
        guard let originAnchor = parent.viewModel.originAnchor else { return }
        
        let movingLines = ["line1", "line8", "line9", "line10"]
        let extendingLines = ["line3", "line4", "line11", "line12"]
        
        movingLines.forEach { lineName in
            if let line = originAnchor.findEntity(named: lineName) as? ModelEntity {
                var newLinePosition = line.position
                newLinePosition.y += deltaY
                line.position = newLinePosition
            }
        }
        
        extendingLines.forEach { lineName in
            if let line = originAnchor.findEntity(named: lineName) as? ModelEntity {
                let oldPosition = line.position
                let oldLength = line.model?.mesh.bounds.extents.y ?? 0
                let oldStart = oldPosition.y - oldLength / 2
                
                let newEnd = oldStart + oldLength + deltaY
                let newLength = newEnd - oldStart
                let newPosition = oldStart + newLength / 2
                
                let newLine = MeshResource.generateBox(size: [line.components[ModelComponent.self]?.mesh.bounds.extents.x ?? 0.001,
                                                              newLength,
                                                              line.components[ModelComponent.self]?.mesh.bounds.extents.z ?? 0.001])
                           
                let newModelComponent = ModelComponent(mesh: newLine, materials: [SimpleMaterial(color: .blue, isMetallic: false)])
                line.components.set(newModelComponent)
                line.position = SIMD3<Float>(oldPosition.x, newPosition, oldPosition.z)
            }
        }
    }
    
    // widthEditor
    func moveWidthEditor(location: CGPoint) {
        let screenDeltaX = location.x - initialX // 計算螢幕上移動距離
        print("screenDeltaX: \(screenDeltaX)")
        initialX = location.x
        
        let worldDeltaZ = Float(screenDeltaX) / 10000 // 轉換成空間移動距離
        
        if let boundingBox = self.boundingBox as? BlackMirrorzBoundingBox {
            var newPosition = boundingBox.widthEditor?.position
            newPosition?.z += worldDeltaZ
            boundingBox.widthEditor?.position = newPosition!
            updateLineEntityByWidthEditor(delta: worldDeltaZ)
        }
    }
    
    func updateLineEntityByWidthEditor(delta: Float) {
        guard let originAnchor = parent.viewModel.originAnchor else { return }
        
        let movingLines = ["line1", "line2", "line3", "line4"]
        let extendingLines = ["line5", "line6", "line8", "line9"]
        
        movingLines.forEach { lineName in
            if let line = originAnchor.findEntity(named: lineName) as? ModelEntity {
                var newLinePosition = line.position
                newLinePosition.z += delta
                line.position = newLinePosition
            }
        }
        
        extendingLines.forEach { lineName in
            if let line = originAnchor.findEntity(named: lineName) as? ModelEntity {
                let oldPosition = line.position
                let oldLength = line.model?.mesh.bounds.extents.z ?? 0
                let oldStart = oldPosition.z - oldLength / 2
                
                let newEnd = oldStart + oldLength + delta
                let newLength = newEnd - oldStart
                let newPosition = oldStart + newLength / 2
                
                let newLine = MeshResource.generateBox(size: [line.components[ModelComponent.self]?.mesh.bounds.extents.x ?? 0.001,
                                                             line.components[ModelComponent.self]?.mesh.bounds.extents.y ?? 0.001,
                                                             newLength])
                                                              
                let newModelComponent = ModelComponent(mesh: newLine, materials: [SimpleMaterial(color: .blue, isMetallic: false)])
                line.components.set(newModelComponent)
                line.position = SIMD3<Float>(oldPosition.x, oldPosition.y, newPosition)
            }
        }
    }
    
    // depthEditor
    func moveDepthEditor(location: CGPoint) {
        let screenDeltaX = location.x - initialX // 計算螢幕上移動距離
        print("screenDeltaX: \(screenDeltaX)")
        initialX = location.x
        
        let worldDeltaX = Float(screenDeltaX) / 7000 // 轉換成空間移動距離
        
        if let boundingBox = self.boundingBox as? BlackMirrorzBoundingBox {
            var newPosition = boundingBox.depthEditor?.position
            newPosition?.x += worldDeltaX
            boundingBox.depthEditor?.position = newPosition!
            updateLineEntityByDepthEditor(delta: worldDeltaX)
        }
    }
    
    func updateLineEntityByDepthEditor(delta: Float) {
        guard let originAnchor = parent.viewModel.originAnchor else { return }
        
        let movingLines = ["line4", "line6", "line9", "line12"]
        let extendingLines = ["line1", "line2", "line7", "line10"]
        
        movingLines.forEach { lineName in
            if let line = originAnchor.findEntity(named: lineName) as? ModelEntity {
                var newLinePosition = line.position
                newLinePosition.x += delta
                line.position = newLinePosition
            }
        }
        
        extendingLines.forEach { lineName in
            if let line = originAnchor.findEntity(named: lineName) as? ModelEntity {
                let oldPosition = line.position
                let oldLength = line.model?.mesh.bounds.extents.x ?? 0
                let oldStart = oldPosition.x - oldLength / 2
                
                let newEnd = oldStart + oldLength + delta
                let newLength = newEnd - oldStart
                let newPosition = oldStart + newLength / 2
                
                let newLine = MeshResource.generateBox(size: [newLength,
                    line.components[ModelComponent.self]?.mesh.bounds.extents.y ?? 0.001,
                    line.components[ModelComponent.self]?.mesh.bounds.extents.z ?? 0.001])
                                                              
                let newModelComponent = ModelComponent(mesh: newLine, materials: [SimpleMaterial(color: .blue, isMetallic: false)])
                line.components.set(newModelComponent)
                line.position = SIMD3<Float>(newPosition, oldPosition.y, oldPosition.z)
            }
        }
    }
}
