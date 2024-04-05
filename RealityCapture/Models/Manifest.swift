//
//  Manifest.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/4/4.
//

import Foundation

/* 
 Codable is a type alias for the Encodable & Decodable protocols
 
 */
struct Manifest : Codable {
    struct Frame : Codable {
        let filePath: String
        let depthPath: String?
        let transformMatrix: [[Float]]
        let timestamp: TimeInterval
        let flX: Float
        let flY: Float
        let cx: Float
        let cy: Float
        let w: Int
        let h: Int
    }
    var w: Int = 0
    var h: Int = 0
    var flX: Float = 0
    var flY: Float = 0
    var cx: Float = 0
    var cy: Float = 0
    var depthIntegerScale : Float?
    var depthSource: String?
    var frames: [Frame] = [Frame]()
}
