//
//  UploadManager.swift
//  CaptureSample
//
//  Created by lychen on 2024/8/23.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import os

private let logger = Logger(subsystem: "com.lychen.CaptureSample",
                            category: "UploadManager")

// extension for "static"
extension CaptureInfo {
//    var cameraSettingUrl: URL {
//        return CaptureInfo.cameraSettingUrl(in: captureDir)
//    }
//    
//    static func cameraSettingUrl(in captureDir: URL) -> URL {
//        return captureDir.appendingPathComponent("cameraSettings.json")
//    }
}

// extension for "dynamic"
extension CaptureInfo {
    var cameraSettingUrl: URL {
        return CaptureInfo.cameraSettingUrl(in: captureDir)
    }
    
    static func cameraSettingUrl(in captureDir: URL) -> URL {
        return captureDir.appendingPathComponent("metadata.json")
    }
}


struct perCapture {
    var image: Data? = nil
    var depth: Data? = nil
    var id: UInt32? = nil
}

private enum getDataError: Error {
    case fileNotExist(msg: String)
}

class UploadManager: ObservableObject {
    @Published var doneUploadCaptureDatas: Bool = false {
        didSet {
            if doneUploadCaptureDatas {
                print("doneUploadCaptureDatas to true")
            }
        }
    }
    
    // static
    private var cameraSetting: [String: Any]? = nil
    // dynamic
    
    // common
    @Published var captureDatas: [perCapture] = [perCapture]()
    private var captureInfos: [CaptureInfo]
    private var captureDir: URL
    
    init(captureDir: URL, captureInfos: [CaptureInfo]) {
        self.captureDir = captureDir
        self.captureInfos = captureInfos
    }
    
    
    private func getImageFromDisk(captureId: UInt32) throws -> Data {
        let file_path = CaptureInfo.imageUrl(in: captureDir, id: captureId)
        var imageData: Data
        // load image from file path, convert to class 'Data'
        do {
            imageData = try Data(contentsOf: file_path)
        } catch {
            throw error
        }
        return imageData
    }
    
    private func getDepthFromDisk(captureId: UInt32) throws -> Data {
        let file_path = CaptureInfo.depthUrl(in: captureDir, id: captureId)
        var depthData: Data
        // load image from file path, convert to class 'Data'
        do {
            depthData = try Data(contentsOf: file_path)
        } catch {
            throw error
        }
        return depthData
    }
    
    private func loadCaptureData(captureId: UInt32) -> perCapture {
        var loadedCapture = perCapture()
        do {
            loadedCapture.image = try getImageFromDisk(captureId: captureId)
        } catch {
            print("Error when loading image: \(error)")
        }
        do {
            loadedCapture.depth = try getDepthFromDisk(captureId: captureId)
        } catch {
            print("Error when loading depth: \(error)")
        }
        loadedCapture.id = captureId
        return loadedCapture
    }
    
    private func loadCaptureDatas() async {
        doneUploadCaptureDatas = false
        if !captureDatas.isEmpty {
            logger.log("imageData of current folder is not empty.")
            captureDatas.removeAll()
        }
        print("before sort:")
        await withTaskGroup(of: perCapture.self, body: { loadTaskGroup in
            for captureInfo in self.captureInfos {
                loadTaskGroup.addTask {
                    return self.loadCaptureData(captureId: captureInfo.id)
                }
            }
            for await result in loadTaskGroup {
                captureDatas.append(result)
                print("capture id: \(result.id!)")
            }
        })
        doneUploadCaptureDatas = true
    }
    
    func upload() async {
        await loadCaptureDatas()
        captureDatas = captureDatas.sorted{$0.id! < $1.id!}
        print("after sort")
        for capture in captureDatas {
            print("capture id: \(capture.id!)")
        }
        // upload captureDatas to backend ...
        // TODO
    }
    
    static func assignUploadManagerToFolderState(folderState: CaptureFolderState) {
        //folderState.uploadManeger = UploadManager(captureDir: folderState.captureDir!, captureInfos: folderState.captures)
    }
}

