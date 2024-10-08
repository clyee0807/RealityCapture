//
//  BoundingBox.swift
//  RealityCapture
//
//  Created by lychen on 2024/4/16.
//

import Foundation
import ARKit
import RealityKit

class BlackMirrorzBoundingBox: Entity, HasAnchoring {
    var heightEditor: Entity?
    var widthEditor: Entity?
    var depthEditor: Entity?
    
    private var modelEnties: [ModelEntity] = []

    // MARK: - Initialization
    init(anchorPosition: SIMD3<Float>, points: [SIMD3<Float>], color: UIColor = .white) {
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
        heightEditor = createHeightEditor(anchorPosition: anchorPosition)
        widthEditor = createWidthEditor(anchorPosition: anchorPosition)
        depthEditor = createDepthEditor(anchorPosition: anchorPosition)
    }

    required init() {
        fatalError("init Has Not Been Implemented")
    }

    private func createWireframe(extent: SIMD3<Float>, center: SIMD3<Float>, color: UIColor) {
        print("extent: \(extent), center: \(center)")
        // 12 lines, each line is represented by 2 points: [start, end]
        let lines: [(SIMD3<Float>, SIMD3<Float>)] = [
            (SIMD3(center.x - extent.x/2, center.y + extent.y, center.z + extent.z/2),
             SIMD3(center.x + extent.x/2, center.y + extent.y, center.z + extent.z/2)), // 1. top front edge
            (SIMD3(center.x - extent.x/2, center.y,            center.z + extent.z/2),
             SIMD3(center.x + extent.x/2, center.y,            center.z + extent.z/2)), // 2. bottom front edge
            (SIMD3(center.x - extent.x/2, center.y,            center.z + extent.z/2),
             SIMD3(center.x - extent.x/2, center.y + extent.y, center.z + extent.z/2)), // 3. left front edge
            (SIMD3(center.x + extent.x/2, center.y,            center.z + extent.z/2),
             SIMD3(center.x + extent.x/2, center.y + extent.y, center.z + extent.z/2)), // 4. right front edge
            (SIMD3(center.x - extent.x/2, center.y,            center.z - extent.z/2),
             SIMD3(center.x - extent.x/2, center.y,            center.z + extent.z/2)), // 5. bottom left edge
            (SIMD3(center.x + extent.x/2, center.y,            center.z - extent.z/2),
             SIMD3(center.x + extent.x/2, center.y,            center.z + extent.z/2)), // 6. bottom right edge
            (SIMD3(center.x - extent.x/2, center.y,            center.z - extent.z/2),
             SIMD3(center.x + extent.x/2, center.y           , center.z - extent.z/2)), // 7. bottom back edge
            (SIMD3(center.x - extent.x/2, center.y + extent.y, center.z - extent.z/2),
             SIMD3(center.x - extent.x/2, center.y + extent.y, center.z + extent.z/2)), // 8. top left edge
            (SIMD3(center.x + extent.x/2, center.y + extent.y, center.z - extent.z/2),
             SIMD3(center.x + extent.x/2, center.y + extent.y, center.z + extent.z/2)), // 9. top right edge
            (SIMD3(center.x - extent.x/2, center.y + extent.y, center.z - extent.z/2),
             SIMD3(center.x + extent.x/2, center.y + extent.y, center.z - extent.z/2)), // 10. top back edge
            (SIMD3(center.x - extent.x/2, center.y           , center.z - extent.z/2),
             SIMD3(center.x - extent.x/2, center.y + extent.y, center.z - extent.z/2)), // 11. back left edge
            (SIMD3(center.x + extent.x/2, center.y           , center.z - extent.z/2),
             SIMD3(center.x + extent.x/2, center.y + extent.y, center.z - extent.z/2)), // 12. back right edge
        ]
    
        lines.forEach { start, end in
            let line = createLine(start: start, end: end, color: color)
            self.addChild(line)
        }
    }
    
    private var lineIdx = 1
    private func createLine(start: SIMD3<Float>, end: SIMD3<Float>, color: UIColor) -> Entity {
        let lengthX = max(abs(end.x - start.x), 0.001)
        let lengthY = max(abs(end.y - start.y), 0.001)
        let lengthZ = max(abs(end.z - start.z), 0.001)
        let lineMesh = MeshResource.generateBox(width: lengthX, height: lengthY, depth: lengthZ)
        let lineMaterial = SimpleMaterial(color: color, isMetallic: false)
        let lineEntity = ModelEntity(mesh: lineMesh, materials: [lineMaterial])
        lineEntity.name = "line\(lineIdx)"
        lineEntity.collision = CollisionComponent(shapes: [.generateBox(size: SIMD3<Float>(lengthX, lengthY, lengthZ))])
        
        lineEntity.position = (start + end) / 2

        lineIdx += 1
        return lineEntity
    }
    
    private func createHeightEditor(anchorPosition: SIMD3<Float>) -> Entity {
        let boxSize: Float = 0.1
        
        let editorMesh = MeshResource.generateBox(width: 0.03, height: 0.002, depth: 0.03, cornerRadius: 0.001)
        let editorMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let editorEntity = ModelEntity(mesh: editorMesh, materials: [editorMaterial])
        editorEntity.name = "heightEditor"
        
        editorEntity.collision = CollisionComponent(shapes: [.generateBox(size: SIMD3<Float>(0.03, 0.002, 0.03))])
        editorEntity.position = SIMD3<Float>(anchorPosition.x, anchorPosition.y + boxSize, anchorPosition.z)
        self.addChild(editorEntity)
        
        return editorEntity
    }
    
    private func createDepthEditor(anchorPosition: SIMD3<Float>) -> Entity {
        let boxSize: Float = 0.1
        
        let editorMesh = MeshResource.generateBox(width: 0.002, height: 0.03, depth: 0.03, cornerRadius: 0.001)
        let editorMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let editorEntity = ModelEntity(mesh: editorMesh, materials: [editorMaterial])
        editorEntity.name = "depthEditor"
        
        editorEntity.collision = CollisionComponent(shapes: [.generateBox(size: SIMD3<Float>(0.005, 0.03, 0.03))])
        editorEntity.position = SIMD3<Float>(anchorPosition.x + boxSize/2, anchorPosition.y + boxSize/2, anchorPosition.z)
        self.addChild(editorEntity)
        
        return editorEntity
    }
    
    private func createWidthEditor(anchorPosition: SIMD3<Float>) -> Entity {
        let boxSize: Float = 0.1
        
        let editorMesh = MeshResource.generateBox(width: 0.03, height: 0.03, depth: 0.002, cornerRadius: 0.001)
        let editorMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let editorEntity = ModelEntity(mesh: editorMesh, materials: [editorMaterial])
        editorEntity.name = "widthEditor"
        
        editorEntity.collision = CollisionComponent(shapes: [.generateBox(size: SIMD3<Float>(0.03, 0.03, 0.005))])
        editorEntity.position = SIMD3<Float>(anchorPosition.x, anchorPosition.y + boxSize/2, anchorPosition.z + boxSize/2)
        self.addChild(editorEntity)
        
        return editorEntity
    }
}



// MARK: - Debug Meshes
class BoundingBoxHeightEditor: Entity, HasAnchoring {
    init(anchorPosition: SIMD3<Float>) {
        super.init()
        
        let boxSize: Float = 0.05
        
        let editorMesh = MeshResource.generateBox(width: 0.03, height: 0.03, depth: 0.03, cornerRadius: 0.01)
        let editorMaterial = SimpleMaterial(color: .white, isMetallic: false)
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
