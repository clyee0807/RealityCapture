//
//  CaptureTrack.swift
//  RealityCapture
//
//  Created by lychen on 2024/7/15.
//

import Foundation
import os
import ARKit
import RealityKit
import SwiftUI
import Combine

private let logger = Logger(subsystem: "com.lychen.CaptureSample", category: "CaptureTrack")

class CaptureTrack: Entity, HasAnchoring {
    
    
    @ObservedObject var model: ARViewModel
    var originAnchor: AnchorEntity
    var anchorPosition: SIMD3<Float>
    
    var points: [ModelEntity] = []
//    var checkpoints: [Int: PointStatus] = [:]

    var count: Int = 30
    var radius: Float = 0.41  // TODO: 要根據 hemisphere 改變

    private var cancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    
    init(anchorPosition: SIMD3<Float>, originAnchor: AnchorEntity, model: ARViewModel) {
        self.model = model
        self.originAnchor = originAnchor
        self.anchorPosition = anchorPosition
        
        super.init()
        
        self.name = "CaptureTrack"
        
        let discMesh = MeshResource.generatePlane(width: 0.2, depth: 0.2, cornerRadius: 0.1)
        let material = SimpleMaterial(color: .red, isMetallic: false)
        let discEntity = ModelEntity(mesh: discMesh, materials: [material])
        discEntity.position = anchorPosition + SIMD3<Float>(0, 0.01, 0)
        
        asyncLoadModelEntity();  // load hemiSphere.usdz
        createCheckPoints(center: anchorPosition, count: count)

    }
    
    required init() {
        fatalError("init Has Not Been Implemented")
    }
    
    public func findNearestPoint(cameraPosition: SIMD3<Float>, anchorPosition: SIMD3<Float>) -> Int {
        let interval = 360.0 / Float(count)
        
        // translate to relative position
        let cameraPos = cameraPosition - anchorPosition
        var cameraAngle = atan2(cameraPos.z, cameraPos.x) * 180 / Float.pi
        if cameraAngle < 0 { cameraAngle += 360 }
        
        let closestPointIndex = Int(round(cameraAngle / interval)) % count // ensure not out of range
//        print("closest point is point\(closestPointIndex)")

        return Int(closestPointIndex)
    }
    
    public func updatePoints(pointIndex: Int) {
        DispatchQueue.main.async {
            for (index, entity) in self.points.enumerated() {
                let status = self.model.checkpoints[index]
                
                let color: UIColor
                if status == .captured {
                    color = .green   // captured point set to green
                } else {
                    let isPointed = (index == pointIndex)
                    color = (isPointed ? .yellow : .red)
                }
                
                let material = SimpleMaterial(color: color.withAlphaComponent(0.7), isMetallic: false)
                (entity as? ModelEntity)?.model?.materials = [material]
                
                if status != .captured {
                    self.model.checkpoints[index] = (index == pointIndex) ? .pointed : .initialized
                }
            }
        }
    }
    
    private func asyncLoadModelEntity() {
        let filename = "hemisphere.usdz"
        
        self.cancellable = ModelEntity.loadModelAsync(named: filename)
            .sink (receiveCompletion: { loadCompletion in
                switch loadCompletion {
                case .failure(let error):
                    print("Error loading \(filename) model: \(error.localizedDescription)")
                case .finished:
                    print("\(filename) model loaded successfully.")
                }
            }, receiveValue: { modelEntity in
                var material = SimpleMaterial()
                material.color = .init(tint: .green.withAlphaComponent(0.3))
                modelEntity.model?.materials = [material]

                modelEntity.position = self.anchorPosition + SIMD3<Float>(0, 0.001, 0)
                modelEntity.scale = SIMD3<Float>(0.04, 0.04, 0.04)  // TODO: 要根據模型大小改變
                modelEntity.name = filename
                self.addChild(modelEntity)
                print("Children of captureTrack: \(self.children.map { $0.name })")
            })
    }
    
    private func asyncLoadCheckPointEntity(filename: String, position: SIMD3<Float>, name: String, direction: SIMD3<Float>) {
        let cancellable = ModelEntity.loadModelAsync(named: filename)
            .sink (receiveCompletion: { loadCompletion in
                switch loadCompletion {
                case .failure(let error):
                    print("Error loading \(filename) model: \(error.localizedDescription)")
                case .finished:
                    print("\(filename) model loaded successfully.")
                }
            }, receiveValue: { modelEntity in
                
                var material = SimpleMaterial()
                material.color = .init(tint: .red.withAlphaComponent(0.7))
                modelEntity.model?.materials = [material]

                modelEntity.position = position
                
                let up = SIMD3<Float>(1, 0, 0)
                let rotation = simd_quatf(from: up, to: normalize(direction))
                modelEntity.orientation = rotation
                
                modelEntity.scale = SIMD3<Float>(0.025, 0.025, 0.025)
                modelEntity.name = name
                self.points.append(modelEntity)
                self.addChild(modelEntity)
                
            })
        cancellable.store(in: &cancellables)
    }
    
    private func createCheckPoints(center: SIMD3<Float>, count: Int) {
        self.count = count
        let height: Float = 0.035  // 這圈拍攝的高度
        
        let fullCircle = Float.pi * 2
        let angleIncrement = fullCircle / Float(count)
        
        for i in 0..<count {
            let angle = angleIncrement * Float(i)
            
            let x = cos(angle) * radius
            let z = sin(angle) * radius
            let entityPosition = SIMD3<Float>(center.x + x, center.y + height, center.z + z)
            
            let direction = center - entityPosition  // 面向 center 的方向
            let name = "Point\(i)"
            asyncLoadCheckPointEntity(filename: "checkpoint.usdz", 
                                      position: entityPosition,
                                      name: name,
                                      direction: direction)
            model.checkpoints[i] = .initialized
        }
        logger.info("Children of captureTrack: \(self.children.map { $0.name })")
    }
}
