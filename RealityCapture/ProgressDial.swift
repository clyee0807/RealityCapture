//
//  ProgressDial.swift
//  RealityCapture
//
//  Created by lychen on 2024/5/2.
//

import Foundation
import ARKit
import RealityKit
import SwiftUI

class ProgressDial: Entity, HasAnchoring {
    @ObservedObject var model: ARViewModel

    var points: [ModelEntity] = []
//    var dialPoints: [Int: PointStatus] = [:]

    var count: Int = 20
    var radius: Float = 0.15
    
    
    init(anchorPosition: SIMD3<Float>, model: ARViewModel) {
        self.model = model
        super.init()
        
//        self.dialPoints = model.dialPoints
        
        let discMesh = MeshResource.generatePlane(width: 0.2, depth: 0.2, cornerRadius: 0.1)
        let material = SimpleMaterial(color: .red, isMetallic: false)
        let discEntity = ModelEntity(mesh: discMesh, materials: [material])

        discEntity.position = anchorPosition + SIMD3<Float>(0, 0.01, 0)
        discEntity.name = "capturingDial"
        
        createProgressPoints(center: anchorPosition, count: 20)

    }
    
    required init() {
        fatalError("init Has Not Been Implemented")
    }
    
    private func createProgressPoints(center: SIMD3<Float>, count: Int) {
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
            model.dialPoints[i] = .initialized
            self.addChild(sphereEntity)
        }
    }
    
    public func findNearestPoint(cameraPosition: SIMD3<Float>, anchorPosition: SIMD3<Float>) -> Int {
        
        let interval = 360.0 / Float(count)
        
        // translate to relative position
        let cameraPos = cameraPosition - anchorPosition
        var cameraAngle = atan2(cameraPos.z, cameraPos.x) * 180 / Float.pi
        if cameraAngle < 0 { cameraAngle += 360 }
        
        let closestPointIndex = Int(round(cameraAngle / interval)) % count // ensure not out of range
        // print("cameraAngle: \(cameraAngle), closetPointIndex: \(cloestPointIndex)")
        
        
        // Reset the color of all points to their default based on their captured state
//        for (index, entity) in points.enumerated() {
//            if let modelEntity = entity as? ModelEntity {
//                let isCaptured = (model.dialPoints[index] == .captured)
//                let material = SimpleMaterial(color: isCaptured ? .green : .red, isMetallic: false)
//                modelEntity.model?.materials = [material]
//                //model.dialPoints[index] = isCaptured ? .captured : .initialized
//            }
//        }
//        
//        // Set the closest point as pointed (yellow)
//        if let closestEntity = points[closestPointIndex] as? ModelEntity {
//            let material = SimpleMaterial(color: .yellow, isMetallic: false)
//            closestEntity.model?.materials = [material]
//            model.dialPoints[closestPointIndex] = .pointed
//        }
    
        
        return Int(closestPointIndex)
    }
    
    public func updatePoints(pointIndex: Int) {
        DispatchQueue.main.async {
            for (index, entity) in self.points.enumerated() {
                let isCaptured = self.model.dialPoints[index] == .captured
                let isPointed = index == pointIndex
                let color: UIColor = isCaptured ? .green : (isPointed ? .yellow : .red)
                let material = SimpleMaterial(color: color, isMetallic: false)
                (entity as? ModelEntity)?.model?.materials = [material]
                self.model.dialPoints[index] = isCaptured ? .captured : (isPointed ? .pointed : .initialized)
                
            }
        }
    }
}
