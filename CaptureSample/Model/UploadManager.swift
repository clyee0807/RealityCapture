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

    // http url information
    private let localHostBaseUrl: URL? = URL(string: "http://192.168.31.115:3001") ?? nil
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
    private var returnedCaptureId: String? = nil
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
    
    func loadCaptureData() async {
        DispatchQueue.main.async {
            self.doneUploadCaptureData = false
        }
        
        await withTaskGroup(of: perCapture.self, body: { loadTaskGroup in
            for captureInfo in self.captureInfos {
                loadTaskGroup.addTask {
                    return self.loadCaptureData(captureId: captureInfo.id)
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
            self.doneUploadCaptureData = true
        }
    }
    
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
            
//            if let res = String(data: data, encoding: .utf8) {
//                logger.log("Response: \(res)")
//            }
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
        let url = URL(string: "\(backendUrl!)/capture")
        
        struct emptyData: Encodable {
        }
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.httpBody = try! JSONEncoder().encode(emptyData())
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                logger.error("Error: \(error.localizedDescription)")
                self.doneCreateCapture = true
                return
            }
            
            guard let data = data else {
                logger.error("No data received")
                self.doneCreateCapture = true
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            self.createCaptureResponse = data
            self.doneCreateCapture = true
        }
        task.resume()
    }
    
    

    func upload() async {
        await loadCaptureData()
        DispatchQueue.main.async {
            self.captureDatas = self.captureDatas.sorted { $0.id! < $1.id! }
            print("after sort")
            for capture in self.captureDatas {
                print("  capture id: \(capture.id!)")
            }
            // upload captureDatas to backend ...
            // TODO
        }
    }
    
    static func assignUploadManagerToFolderState(folderState: CaptureFolderState) {
        //folderState.uploadManeger = UploadManager(captureDir: folderState.captureDir!, captureInfos: folderState.captures)
    }
}

