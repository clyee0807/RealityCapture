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

class CaptureTrack: Entity, HasAnchoring {
    
    @ObservedObject var model: ARViewModel
    var originAnchor: AnchorEntity
    var anchorPosition: SIMD3<Float>
    
    var points: [ModelEntity] = []
//    var checkpoints: [Int: PointStatus] = [:]

    var count: Int = 20
    var radius: Float = 0.15

    private var cancellable: AnyCancellable?
    
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
        createCheckPoints(center: anchorPosition, count: 20)

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
                
                let material = SimpleMaterial(color: color, isMetallic: false)
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
//                    self.logger.error("Error loading \(filename) model: \(error.localizedDescription)")
                    print("Error loading \(filename) model: \(error.localizedDescription)")
                case .finished:
//                    self.logger.info("\(filename) model loaded successfully.")
                    print("\(filename) model loaded successfully.")
                }
            }, receiveValue: { modelEntity in
                var material = SimpleMaterial()
                material.color = .init(tint: .green.withAlphaComponent(0.3))
//                material.tintColor = UIColor.init(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.3)
//                material.baseColor = MaterialColorParameter.color(UIColor.green)
//                material.isDoubleSided = true
                modelEntity.model?.materials = [material]

                modelEntity.position = self.anchorPosition + SIMD3<Float>(0, 0.001, 0)
                modelEntity.scale = SIMD3<Float>(0.02, 0.02, 0.02)
                modelEntity.name = filename
                self.addChild(modelEntity)
                print("Children of captureTrack: \(self.children.map { $0.name })")
            })
    }
    
    
    private func createCheckPoints(center: SIMD3<Float>, count: Int) {
        self.count = count
        
        let fullCircle = Float.pi * 2
        let angleIncrement = fullCircle / Float(count)

        for i in 0..<count {
            let angle = angleIncrement * Float(i)
            
            let x = cos(angle) * radius
            let z = sin(angle) * radius
            let entityPosition = SIMD3<Float>(center.x + x, center.y, center.z + z)
            
            let mesh = MeshResource.generateSphere(radius: 0.002)
            let material = SimpleMaterial(color: .red, isMetallic: false)
            let sphereEntity = ModelEntity(mesh: mesh, materials: [material])
            
            sphereEntity.position = entityPosition
            sphereEntity.collision = CollisionComponent(shapes: [.generateSphere(radius: 0.02)])
            sphereEntity.name = "Point\(i)"
            
            points.append(sphereEntity)
            model.checkpoints[i] = .initialized
            self.addChild(sphereEntity)
        }
    }
}
