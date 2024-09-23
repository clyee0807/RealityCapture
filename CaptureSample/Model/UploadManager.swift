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
//    @ObservedObject var model: ARViewModel
    
    // http url information
    private let localHostBaseUrl: URL? = URL(string: "http://172.20.10.6:3001") ?? nil
    
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
    private var isReupload: Bool
    
    @Published var captureName: String = ""
    @Published var captureTask: String = "None"
    @Published var shouldCreateTask: Bool = false {
        didSet {
            if shouldCreateTask {
                captureTask = "GS"
            } else {
                captureTask = "None"
            }
        }
    }
    
    init(captureFolderState: CaptureFolderState, isReupload: Bool) {
        self.captureDir = captureFolderState.captureDir!
        self.captureInfos = captureFolderState.captures
        self.isReupload = isReupload
    }
    
    // MARK: store information
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
    
    private func loadMetadatafromDisk() -> Metadata? {  // getCameraSettingFromDisk()
        let file_path = CaptureInfo.metadataUrl(in: captureDir)
        logger.info("load Metadata from \(file_path)")
        
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
    
    func loadCaptureIdfromDisk() {  // getBackendCaptureId()
        if(isReupload) {
            let filePath = self.captureDir.appendingPathComponent("captureId.txt")
            do {
                let backendCaptureId = try String(contentsOf: filePath, encoding: .utf8)
                print("load id from captureId.txt: \(backendCaptureId)")
                self.captureId = backendCaptureId
            } catch {
                logger.error("Cannot find captureId.txt")
            }
        }
        //if(createCaptureResponse == nil) {
        //    logger.error("createCaptureResponse is nil")
        //}
    }
    
    func saveCaptureIdToFile() {
        if(isReupload) { return }
        guard let captureId = self.captureId else {
            logger.error("saveCaptureIdToFile: captureId not found")
            return
        }
        let filePath = self.captureDir.appendingPathComponent("captureId.txt")
        do {
            try captureId.write(to: filePath, atomically: true, encoding: .utf8)
        } catch {
            logger.error("saveCaptureIdToFile: Cannot write captureId to file")
        }
    }
    
    func saveCaptureTaskToFile() {
        let filePath = self.captureDir.appendingPathComponent("captureTask.txt")
        
        do {
            try captureTask.write(to: filePath, atomically: true, encoding:
                    .utf8)
        } catch {
            logger.error("saveCaptureTaskToFile: Cannot write captureTask to file")
        }
    }
    
    func saveUploadInfoToFile() {
        let filePath = self.captureDir.appendingPathComponent("uploadInfo.txt")
        
        do {
            let uploadInfoJSON: [String: Any] = [
                "captureID": self.captureId!,
                "name": self.captureName,
                "task": self.captureTask,
            ]
            let data = try JSONSerialization.data(withJSONObject: uploadInfoJSON, options: .prettyPrinted)
            try data.write(to: filePath)
        } catch {
            print("saveUploadInfoToFile: Cannot save uploadInfo to file")
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
        
        if isReupload { /// 從 previous capture 上傳
            logger.log("createCapture: captureId is already exist")
            let filePath = self.captureDir.appendingPathComponent("captureId.txt")
            do {
                let backendCaptureId = try String(contentsOf: filePath, encoding: .utf8)
                print("Extract from captureId.txt: \(backendCaptureId)")
                self.captureId = backendCaptureId
            } catch {
                logger.error("Cannot find captureId.txt")
            }
//            DispatchQueue.main.async {
//                self.uploadState = .doneCreateCapture
//            }
//            return
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
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Update capture response: \(responseString)")
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
    
    func createUploadImageRequest(url: URL, captureDatasIndex: Int, boundary: String) -> URLRequest? {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let lineBreak =  "\r\n"
        var body = Data()
        
        // append rgb image
        let image_data = UIImage(data: captureDatas[captureDatasIndex].image!)!.pngData()
        let mimeType = "image/png"
        let image_name = CaptureInfo.photoIdString(for: captureDatas[captureDatasIndex].id!)
        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"picture\"; filename=\"\(image_name).png\"\(lineBreak)")
        body.append("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)")
        if let data = image_data {
            body.append(data)
        }
        body.append(lineBreak)
        
        // append depth image
        let depth_data = UIImage(data: captureDatas[captureDatasIndex].depth!)!.pngData()
        let depth_name = "\(CaptureInfo.photoIdString(for: captureDatas[captureDatasIndex].id!))_depth"
        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"picture\"; filename=\"\(depth_name).png\"\(lineBreak)")
        body.append("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)")
        if let data = depth_data {
            body.append(data)
        }
        body.append(lineBreak)

        // append index
        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"index\"")
        body.append("\(lineBreak)\(lineBreak)\(captureDatasIndex)\(lineBreak)")
            
        body.append("--\(boundary)--\(lineBreak)")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
            
        return request
    }
    func uploadOneImage(url: URL, index: Int) { // callUploadImageAPI
        let request = createUploadImageRequest(url: url, captureDatasIndex: index, boundary: "Boundary-\(UUID().uuidString)")
        guard let request = request else {
            logger.error("uploadOneImage: invalid request with index \(index)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                logger.error("Error: \(error.localizedDescription) with index \(index)")
                return
            }
            
            guard let data = data else {
                logger.error("No data received with index \(index)")
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                logger.log("Upload one image response: \(responseString)")
            }
            
            DispatchQueue.main.async {
                self.uploadedImageNum += 1
                print("\(self.uploadedImageNum) images has been uploaded and got resoponse")
            }
        }
        task.resume()
    }
    func uploadImages() async {
        logger.info("POST: upload images")
        DispatchQueue.main.async {
            self.uploadState = .callingUploadImage
        }
        guard let url = URL(string: "\(backendUrl!)/image/\(self.captureId!)") else { return }
        
        for (index, _) in captureDatas.enumerated() {
            print("index: \(index)")
            uploadOneImage(url: url, index: index)
            while(uploadedImageNum <= index) {
                await Task.yield()
            } /// this code makes sure backend get images in right index sequence, but lose efficiency severely...
        }
        while uploadedImageNum != captureDatas.count {
            await Task.yield()
        }
        
        DispatchQueue.main.async {
            self.uploadState = .doneUploadImage
        }
    }
    
    // lock & unlock capture
    func lockCapture() {
        logger.info("PUT: lock capture")
        DispatchQueue.main.async {
            self.uploadState = .callingLockCapture
        }
        
        guard let url = URL(string: "\(backendUrl!)/capture/lock/\(self.captureId!)") else { return }
        struct emptyData: Encodable {}
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
            
            if let responseString = String(data: data, encoding: .utf8) {
                logger.log("lock capture response: \(responseString)")
            }
            DispatchQueue.main.async {
                self.uploadState = .doneLockCapture
            }
        }
        task.resume()
    }
    
    func unlockCapture() {
        logger.info("PUT: unlock capture")
        DispatchQueue.main.async {
            self.uploadState = .callingLockCapture
        }
        guard let url = URL(string: "\(backendUrl!)/capture/unlock/\(self.captureId!)") else { return }
        struct emptyData: Encodable {}
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONEncoder().encode(emptyData())
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                logger.error("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                logger.error("No data received")
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                logger.log("unlock capture response: \(responseString)")
            }
        }
        task.resume()
    }
    
    // Create task
    struct CreateTaskTypeRequest: Encodable {
        init(type: String) {
            self.type = type
        }
        let type: String
    }
    func createTask() async{
        logger.info("POST: create Task \(self.captureTask)")
        DispatchQueue.main.async {
            self.uploadState = .callingCreateTask
        }
        
        guard let url = URL(string: "\(backendUrl!)/task/\(self.captureId!)") else { return }
        let taskRequest = CreateTaskTypeRequest(
            type: captureTask
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONEncoder().encode(taskRequest)

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
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Create task response: \(responseString)")
            }
            DispatchQueue.main.async {
                self.uploadState = .doneCreateTask
            }
        }
        task.resume()
    }
    
    func loadCaptureData() async {
        DispatchQueue.main.async {
            self.uploadState = .loading
        }
        
        if !captureDatas.isEmpty {
            logger.log("imageData of current folder is not empty.")
            DispatchQueue.main.async {
                self.captureDatas.removeAll()
            }
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
        
       
        // metadata = try loadMetadatafromDisk()
        guard let metadata = loadMetadatafromDisk() else {
            logger.error("Failed to load metadata from metadata.json")
            DispatchQueue.main.async {
                self.uploadState = .failed
            }
            return
        }
        
        DispatchQueue.main.async {
            self.uploadState = .doneLoad
        }
    }
    
    
    // trigger by upload button
    func upload() async {
        await createCapture()
        
        while uploadState != .doneCreateCapture {
            await Task.yield()
        }
//        saveCaptureIdToFile()
        
        // update capture
        if uploadState == .doneCreateCapture {
            logger.info("update capture, id = \(self.captureId), captureName = \(self.captureName)")
            await updateCapture(name: self.captureName)
        }
        while uploadState != .doneUpdateCapture {
            await Task.yield()
        }
        
        // upload image
        if uploadState == .doneUpdateCapture {
            if (!isReupload) {
                await uploadImages()
            }
        }
        while uploadState != .doneUploadImage {
            await Task.yield()
        }
        
        
        if (shouldCreateTask) {
            // lock capture
            lockCapture()
            while uploadState != .doneLockCapture {
                await Task.yield()
            }
            
            // create task
            if uploadState == .doneLockCapture {
                await createTask()
//                saveCaptureTaskToFile()
            }
        } else {
            DispatchQueue.main.async {
                self.uploadState = .doneCreateTask  /// trigger 'allDonePhase' on isUploadingView
            }
        }
        saveUploadInfoToFile()
        
        
        
    }
}

