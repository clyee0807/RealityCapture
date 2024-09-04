//
//  UploadManager.swift
//  CaptureSample
//
//  Created by lychen on 2024/8/23.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import os
import SwiftUI

private let logger = Logger(subsystem: "com.lychen.CaptureSample",
                            category: "UploadManager")

struct Metadata: Codable {
    struct Frame : Codable {
        let file_path: String
        let depth_path: String?
        let transform_matrix: [[Float]]
        let timestamp: TimeInterval
        let fl_x: Float
        let fl_y: Float
        let cx: Float
        let cy: Float
        let w: Int
        let h: Int
    }
    var w: Int = 0
    var h: Int = 0
    var fl_x: Float = 0
    var fl_y: Float = 0
    var cx: Float = 0
    var cy: Float = 0
    var depthIntegerScale : Float?
    var frames: [Frame] = [Frame]()
}

// extension for "static"
extension CaptureInfo {
    var cameraSettingUrl: URL {
        return CaptureInfo.cameraSettingUrl(in: captureDir)
    }
    
    static func cameraSettingUrl(in captureDir: URL) -> URL {
        return captureDir.appendingPathComponent("cameraSettings.json")
    }
}

// extension for "dynamic"
extension CaptureInfo {
    var metadataUrl: URL {
        return CaptureInfo.metadataUrl(in: captureDir)
    }
    
    static func metadataUrl(in captureDir: URL) -> URL {
        return captureDir.appendingPathComponent("metadata.json")
    }
}

// to throw error conveniently
extension String: LocalizedError {
    public var errorDescription: String? { return self }
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
    @ObservedObject var model: ARViewModel
    
    // http url information
//    private let localHostBaseUrl: URL? = URL(string: "http://192.168.31.115:3001") ?? nil  // home
//    private let localHostBaseUrl: URL? = URL(string: "http://192.168.0.10:3001") ?? nil  // macbook
    private let localHostBaseUrl: URL? = URL(string: "http://172.20.10.6:3001") ?? nil  // windows
    
    private let backendBaseURL: URL? = nil
    private let isTesting: Bool = true
    private var backendUrl: URL? {
        if isTesting {
            return localHostBaseUrl
        } else {
            return backendBaseURL
        }
    }
    
    // return data
    private var captureId: String? = nil
    private var returnedImageIds: [String]? = nil
    
    private var doneCreateCapture: Bool = false
    private var createCaptureResponse: Data? = nil
    
    @Published var doneUploadCaptureData: Bool = false {
        didSet {
            if doneUploadCaptureData {
                logger.info("Set doneUploadCaptureData to true")
            }
        }
    }
    
    // static
    private var cameraSetting: [String: Any]? = nil
    // dynamic
    private var metadata: [String: Any]? = nil
    
    // common
    @Published var captureDatas: [perCapture] = [perCapture]()
    private var captureInfos: [CaptureInfo]
    private var captureDir: URL
    
    @Published var captureName: String = ""
    @Published var captureTask: String = "COLMAP"
    
    init(model: ARViewModel, captureDir: URL, captureInfos: [CaptureInfo]) {
        self.model = model
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
    
    private func loadMetadatafromDisk() -> Metadata? {
        let file_path = CaptureInfo.metadataUrl(in: captureDir)
        print("file_path: \(file_path)")
        
        do {
            let json = try Data(contentsOf: file_path)
            let decoder = JSONDecoder()
            let metadata = try decoder.decode(Metadata.self, from: json)
            return metadata
        } catch {
            logger.error("Error loading metadata.json: \(error)")
            return nil
        }
    }
    
    // MARK: - backend API
    enum UploadState {
        case idle
        case loading
        case doneLoad
        case callingCreateCapture
        case doneCreateCapture
        case callingUpdateCapture
        case doneUpdateCapture
        case callingCreateTask
        case doneCreateTask
        case callingLockCapture
        case doneLockCapture
        case callingUploadImage
        case doneUploadImage
        case failed
    }
    private func performStateTransition(from fromState: UploadState, to toState: UploadState) {
        logger.log("Set UploadState to \(String(describing: toState))")
    }
    
    @Published var uploadState: UploadState = .idle {
        didSet {
            if uploadState != oldValue {
                performStateTransition(from: oldValue, to: uploadState)
            }
        }
    }
    @Published var uploadedImageNum: Int = 0
    
    
    func getAllCaptures() async {
        logger.info("GET: get all captures")
        let url = URL(string: "\(backendUrl!)/capture")
        
        let request = URLRequest(url: url!)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                logger.error("Error: \(error.localizedDescription)")
            }
            
            guard let data = data else {
                logger.error("No response data")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let captures = json["data"] as? [[String: Any]] {
                    
                    if let name = captures[1]["name"] as? String {
                        logger.log("data[1].name: \(name)")
                    } else {
                        logger.error("Could not find 'name' key in the second element of 'data' array.")
                    }
                } else {
                    logger.error("JSON parsing failed or data format is incorrect.")
                }
            } catch {
                logger.error("Failed to parse JSON: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
    func createCapture() async {
        logger.info("POST: create capture")
        DispatchQueue.main.async {
            self.uploadState = .callingCreateCapture
        }
        
        let url = URL(string: "\(backendUrl!)/capture")
        
        struct emptyData: Encodable {}
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.httpBody = try! JSONEncoder().encode(emptyData())
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                logger.error("Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.uploadState = .failed
                }
                return
            }
            
            guard let data = data else {
                logger.error("No data received")
                DispatchQueue.main.async {
                    self.uploadState = .failed
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let dataDict = json["data"] as? [String: Any],
                   let id = dataDict["_id"] as? String {
                    DispatchQueue.main.async {
                        self.captureId = id
                        logger.info("_id: \(self.captureId)")
                        self.uploadState = .doneCreateCapture
                    }
                } else {
                    logger.error("Failed to parse response JSON")
                    DispatchQueue.main.async {
                        self.uploadState = .failed
                    }
                }
            } catch {
                logger.error("JSON parsing error: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
    
    struct CaptureRequest: Codable {
        struct cameraMetadata : Codable {
            let width: Int
            let height: Int
        }
        let name: String
        var cameraMetadata: cameraMetadata?
    }
    func updateCapture(name: String) async {
        logger.info("PUT: update capture")
        DispatchQueue.main.async {
            self.uploadState = .callingUpdateCapture
        }
        
        guard let metadata = loadMetadatafromDisk() else {
            logger.error("Failed to load metadata from metadata.json")
            return
        }
        
        let width = metadata.w
        let height = metadata.h
        print("metadata.w: \(width)")
        print("metadata.h: \(height)")
        
        
        let url = URL(string: "\(backendUrl!)/capture/\(self.captureId!)")
        
        let captureRequest = CaptureRequest(
            name: name,
            cameraMetadata: CaptureRequest.cameraMetadata(width: width, 
                                                          height: height)
        )
        
        
        var request = URLRequest(url: url!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONEncoder().encode(captureRequest)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                logger.error("Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.uploadState = .doneUpdateCapture
                }
                return
            }
            
            guard let data = data else {
                logger.error("No data received")
                DispatchQueue.main.async {
                    self.uploadState = .doneUpdateCapture
                }
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
//            self.updateCaptureResponse = data
            DispatchQueue.main.async {
                self.uploadState = .doneUpdateCapture
            }

//            do {
//                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                   let dataDict = json["data"] as? [String: Any],
//                   let id = dataDict["_id"] as? String {
//
//                } else {
//                    logger.error("Failed to parse response JSON")
//                }
//            } catch {
//                logger.error("JSON parsing error: \(error.localizedDescription)")
//            }
        }
        task.resume()
    }
    
    func loadCaptureData() async {
        DispatchQueue.main.async {
            self.uploadState = .loading
        }
//        if !captureDatas.isEmpty {
//            logger.log("imageData of current folder is not empty.")
//            DispatchQueue.main.async {
//                self.captureDatas.removeAll()
//            }
//        }
        
        await withTaskGroup(of: perCapture.self, body: { loadTaskGroup in
            for captureInfo in self.captureInfos {
                loadTaskGroup.addTask {
                    return await self.loadCaptureData(captureId: captureInfo.id)
                }
            }
            
            print("Sort CaptureData: ")
            for await result in loadTaskGroup {
                DispatchQueue.main.async {
                    self.captureDatas.append(result)
                    self.captureDatas.sort { $0.id! < $1.id! }
                    print("  capture id: \(result.id!)")
                }
            }
        })
        
        DispatchQueue.main.async {
            self.uploadState = .doneLoad
        }
    }
    
    func upload() async {
        await createCapture()
        
        while uploadState != .doneCreateCapture {
            await Task.yield()
        }
        if uploadState == .doneCreateCapture {
            logger.info("update capture, id = \(self.captureId), captureName = \(self.captureName)")
            await updateCapture(name: self.captureName)
        }
        
//        while uploadState != .doneUpdateCapture {
//            await Task.yield()
//        }
//        if uploadState == .doneUpdateCapture {
//            await uploadImages()  // TODO: is reupload?
//        }
//
    }
}

