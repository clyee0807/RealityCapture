//
//  BoundingBox.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/4/16.
//

import Foundation
import ARKit
import RealityKit

class BlackMirrorzBoundingBox: Entity, HasAnchoring {
    private var modelEnties: [ModelEntity] = []

    // MARK: - Initialization
    init(anchorPosition: SIMD3<Float>, points: [SIMD3<Float>], color: UIColor = .cyan) {
        super.init()

        var localMin = SIMD3<Float>(Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude)
        var localMax = SIMD3<Float>(-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude)

        for point in points {
            localMin = min(localMin, point)
            localMax = max(localMax, point)
        }

//        let center = SIMD3<Float>(0.0, 0.0, 0.0)  // for testing
        let center = anchorPosition
        let extent = localMax - localMin

        createWireframe(extent: extent, center: center, color: color)
        createHeightEditor(anchorPosition: anchorPosition)
        createWidthEditor(anchorPosition: anchorPosition)
        createDepthEditor(anchorPosition: anchorPosition)
    }

    required init() {
        fatalError("init Has Not Been Implemented")
    }

    private func createWireframe(extent: SIMD3<Float>, center: SIMD3<Float>, color: UIColor) {
        print("extent: \(extent), center: \(center)")
        // 12 lines, each line is represented by 2 points
        let lines: [(SIMD3<Float>, SIMD3<Float>)] = [
            (SIMD3(center.x - extent.x/2, center.y + extent.y, center.z + extent.z/2),
             SIMD3(center.x + extent.x/2, center.y + extent.y, center.z + extent.z/2)), // top front edge
            (SIMD3(center.x - extent.x/2, center.y,            center.z + extent.z/2),
             SIMD3(center.x + extent.x/2, center.y,            center.z + extent.z/2)), // bottom front edge
            (SIMD3(center.x - extent.x/2, center.y + extent.y, center.z + extent.z/2),
             SIMD3(center.x - extent.x/2, center.y,            center.z + extent.z/2)), // left front edge
            (SIMD3(center.x + extent.x/2, center.y + extent.y, center.z + extent.z/2),
             SIMD3(center.x + extent.x/2, center.y,            center.z + extent.z/2)), // right front edge
            (SIMD3(center.x - extent.x/2, center.y,            center.z - extent.z/2),
             SIMD3(center.x - extent.x/2, center.y,            center.z + extent.z/2)), // bottom left edge
            (SIMD3(center.x + extent.x/2, center.y,            center.z - extent.z/2),
             SIMD3(center.x + extent.x/2, center.y,            center.z + extent.z/2)), // bottom right edge
            (SIMD3(center.x - extent.x/2, center.y,            center.z - extent.z/2),
             SIMD3(center.x + extent.x/2, center.y           , center.z - extent.z/2)), // bottom back edge
            (SIMD3(center.x - extent.x/2, center.y + extent.y, center.z - extent.z/2),
             SIMD3(center.x - extent.x/2, center.y + extent.y, center.z + extent.z/2)), // top left edge
            (SIMD3(center.x + extent.x/2, center.y + extent.y, center.z - extent.z/2),
             SIMD3(center.x + extent.x/2, center.y + extent.y, center.z + extent.z/2)), // top right edge
            (SIMD3(center.x - extent.x/2, center.y + extent.y, center.z - extent.z/2),
             SIMD3(center.x + extent.x/2, center.y + extent.y, center.z - extent.z/2)), // top back edge
            (SIMD3(center.x - extent.x/2, center.y           , center.z - extent.z/2),
             SIMD3(center.x - extent.x/2, center.y + extent.y, center.z - extent.z/2)), // back left edge
            (SIMD3(center.x + extent.x/2, center.y           , center.z - extent.z/2),
             SIMD3(center.x + extent.x/2, center.y + extent.y, center.z - extent.z/2)), // back right edge
        ]
        
//        print("lines.length = \(lines.count)")
//        for line in lines {
//            print("line = \(line)")
//        }
        
        var idx = 1
        lines.forEach { start, end in
            let line = createLine(start: start, end: end, color: color)
            line.name = "wireframe\(idx)"
            idx += 1
            self.addChild(line)
        }
    }
    
    private func createLine(start: SIMD3<Float>, end: SIMD3<Float>, color: UIColor) -> Entity {
        let lengthX = max(abs(end.x - start.x), 0.001)
        let lengthY = max(abs(end.y - start.y), 0.001)
        let lengthZ = max(abs(end.z - start.z), 0.001)
        let lineMesh = MeshResource.generateBox(width: lengthX, height: lengthY, depth: lengthZ)
        let lineMaterial = SimpleMaterial(color: color, isMetallic: false)
        let lineEntity = ModelEntity(mesh: lineMesh, materials: [lineMaterial])
        
        lineEntity.position = (start + end) / 2

        return lineEntity
    }
    
    private func createHeightEditor(anchorPosition: SIMD3<Float>) {
        let boxSize: Float = 0.1
        
        let editorMesh = MeshResource.generateBox(width: 0.03, height: 0.005, depth: 0.03, cornerRadius: 0.01)
        let editorMaterial = SimpleMaterial(color: .blue, isMetallic: false)
        let editorEntity = ModelEntity(mesh: editorMesh, materials: [editorMaterial])
        editorEntity.name = "heightEditor"
        
        editorEntity.collision = CollisionComponent(shapes: [.generateBox(size: SIMD3<Float>(0.03, 0.005, 0.03))])
        editorEntity.position = SIMD3<Float>(anchorPosition.x, anchorPosition.y + boxSize, anchorPosition.z)
        self.addChild(editorEntity)
    }
    
    private func createWidthEditor(anchorPosition: SIMD3<Float>) {
        let boxSize: Float = 0.1
        
        let editorMesh = MeshResource.generateBox(width: 0.005, height: 0.03, depth: 0.03, cornerRadius: 0.01)
        let editorMaterial = SimpleMaterial(color: .blue, isMetallic: false)
        let editorEntity = ModelEntity(mesh: editorMesh, materials: [editorMaterial])
        editorEntity.name = "widthEditor"
        
        editorEntity.collision = CollisionComponent(shapes: [.generateBox(size: SIMD3<Float>(0.005, 0.03, 0.03))])
        editorEntity.position = SIMD3<Float>(anchorPosition.x + boxSize/2, anchorPosition.y + boxSize/2, anchorPosition.z)
        self.addChild(editorEntity)
    }
    
    private func createDepthEditor(anchorPosition: SIMD3<Float>) {
        let boxSize: Float = 0.1
        
        let editorMesh = MeshResource.generateBox(width: 0.03, height: 0.03, depth: 0.005, cornerRadius: 0.01)
        let editorMaterial = SimpleMaterial(color: .blue, isMetallic: false)
        let editorEntity = ModelEntity(mesh: editorMesh, materials: [editorMaterial])
        editorEntity.name = "depthEditor"
        
        editorEntity.collision = CollisionComponent(shapes: [.generateBox(size: SIMD3<Float>(0.03, 0.03, 0.005))])
        editorEntity.position = SIMD3<Float>(anchorPosition.x, anchorPosition.y + boxSize/2, anchorPosition.z + boxSize/2)
        self.addChild(editorEntity)
    }
}



// MARK: - Debug Meshes
class BoundingBoxHeightEditor: Entity, HasAnchoring {
    init(anchorPosition: SIMD3<Float>) {
        super.init()
        
        let boxSize: Float = 0.05
        
        let editorMesh = MeshResource.generateBox(width: 0.03, height: 0.03, depth: 0.03, cornerRadius: 0.01)
        let editorMaterial = SimpleMaterial(color: .blue, isMetallic: false)
        let editorEntity = ModelEntity(mesh: editorMesh, materials: [editorMaterial])
        
        editorEntity.position = SIMD3<Float>(anchorPosition.x, anchorPosition.y + boxSize, anchorPosition.z)
        self.addChild(editorEntity)
    }
    
    required init() {
        fatalError("init Has Not Been Implemented")
    }
}

class AnchorPositionPoint: Entity, HasAnchoring {
    init(anchorPosition: SIMD3<Float>) {
        super.init()
        
        let anchorMesh = MeshResource.generateBox(width: 0.01, height: 0.01, depth: 0.01)
        let anchorMaterial = SimpleMaterial(color: .yellow, isMetallic: false)
        let anchorEntity = ModelEntity(mesh: anchorMesh, materials: [anchorMaterial])
        
        anchorEntity.position = anchorPosition
        self.addChild(anchorEntity)
    }
    
    required init() {
        fatalError("init Has Not Been Implemented")
    }
}
