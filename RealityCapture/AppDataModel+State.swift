//
//  AppDataModel+State.swift
//  RealityCapture
//
//  Created by CGVLAB on 2024/3/27.
//

import Foundation

extension AppDataModel {
    enum ModelState: String, CustomStringConvertible {
        var description: String { rawValue }

        case notSet
        case ready
        case capturing
        case prepareToReconstruct
        case reconstructing
        case viewing
        case completed
        case restart
        case failed
    }
}
