//
//  ARViewContainer.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/4/4.
//

import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARViewModel
    
    init(_ vm: ARViewModel) {
        viewModel = vm
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.debugOptions = [.showWorldOrigin]
        
        let configuration = viewModel.createARConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.worldAlignment = .gravity
        configuration.isAutoFocusEnabled = true

        arView.session.run(configuration)
        arView.session.delegate = viewModel
        
        
        // Add tapping gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        // Add a box
//        let cubeMesh = MeshResource.generateBox(size: 0.1)
//        let cubeMaterial = SimpleMaterial(color: .red, isMetallic: false)
//        let cubeEntity = ModelEntity(mesh: cubeMesh, materials: [cubeMaterial])
//        cubeEntity.position = SIMD3<Float>(0, 0 ,0.2)
//        
//        let worldAnchor = AnchorEntity(plane: .horizontal)
//        worldAnchor.addChild(cubeEntity)
//        arView.scene.anchors.append(worldAnchor)
//        viewModel.updateAnchorPosition(worldAnchor)  // for debug button
        
        viewModel.session = arView.session
        viewModel.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

}


class Coordinator {
    var parent: ARViewContainer

    init(_ parent: ARViewContainer) {
        self.parent = parent
    }

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        if let arView = parent.viewModel.arView {
            let location = sender.location(in: arView)
            placeAnchor(at: location, in: arView)
        }
    }
    
    private func placeAnchor(at location: CGPoint, in arView: ARView) {
        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
        if let firstResult = results.first {
            
            let anchor = AnchorEntity(world: firstResult.worldTransform)
            arView.scene.addAnchor(anchor)
            
           
            let mesh = MeshResource.generateBox(size: 0.1)
            let material = SimpleMaterial(color: .blue, isMetallic: true)
            let modelEntity = ModelEntity(mesh: mesh, materials: [material])
            anchor.addChild(modelEntity)
            
            
            parent.viewModel.updateAnchorPosition(anchor)
        }
    }
}
