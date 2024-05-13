//
//  ProgressDial.swift
//  RealityCapture
//
//  Created by lychen on 2024/5/2.
//

import Foundation
import ARKit
import RealityKit


class ProgressDial: Entity, HasAnchoring {
    var count: Int = 20
    var radius: Float = 0.15
    
    var points: [ModelEntity] = []
    
    init(anchorPosition: SIMD3<Float>) {
        super.init()
        
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
            self.addChild(sphereEntity)
        }
    }
    
    public func findNearestPoint(cameraPosition: SIMD3<Float>, anchorPosition: SIMD3<Float>) -> Int {
        
        let interval = 360.0 / Float(count)
        
        // translate to relative position
        let cameraPos = cameraPosition - anchorPosition
        var cameraAngle = atan2(cameraPos.z, cameraPos.x) * 180 / Float.pi
        if cameraAngle < 0 { cameraAngle += 360 }
        
        let cloestPointIndex = round(cameraAngle / interval)
        
        // 把最近的point改成黃色
        if let closestEntity = self.findEntity(named: "Point\(Int(cloestPointIndex))") as? ModelEntity {
            let material = SimpleMaterial(color: .yellow, isMetallic: false)
            closestEntity.model?.materials = [material]
        }
    
//        print("cameraAngle: \(cameraAngle), closetPointIndex: \(cloestPointIndex)")
        
        return Int(cloestPointIndex)
    }
}
