/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Helper class for listing, deleting, and viewing app document directory "capture" folders.
*/

import Combine
import Foundation

import os

private let logger = Logger(subsystem: "com.lychen.CaptureSample",
                            category: "CaptureFolderState")

/// This helper class loads the contents of an image capture folder. It uses asynchronous calls that run on a
/// background queue and includes static methods for retrieving the top-level capture folder, which contains
/// separate subfolders for each capture. Use a different instance of this class for each capture folder.
class CaptureFolderState: ObservableObject {
    static private let workQueue = DispatchQueue(label: "CaptureFolderState.Work",
                                                 qos: .userInitiated)
    
    enum Error: Swift.Error {
        case invalidCaptureDir
    }
    
    @Published var captureDir: URL? = nil
    @Published var captures: [CaptureInfo] = []
    
    
    // datasetWriter
    static var manifest = Manifest()
    static var projectName = ""
    
    private var subscriptions = Set<AnyCancellable>()
    
    init(url captureDir: URL) {
        self.captureDir = captureDir
        requestLoad()
    }
    
    func requestLoad() {
        requestLoadCaptureInfo()  /// return a Future<[CaptureInfo], Error> 在背景加載圖像
            .receive(on: DispatchQueue.main) /// 確保在 main thread 執行
            .replaceError(with: [])     /// if errors happened, return []
            .assign(to: \.captures, on: self)  /// 將結果 assign to "captures"
            .store(in: &subscriptions)
    }
    
    /// This method requests the removal of a specific capture `id` from the data model. This removes the
    /// specified item from the `captures` array on the main thread. If `deleteData` is `true`, this
    /// method deletes the corresponding files using a background thread.
    func removeCapture(captureInfo: CaptureInfo, deleteData: Bool = true) {
        logger.log("Request removal of captureInfo: \(String(describing: captureInfo))...")
        CaptureFolderState.workQueue.async {
            if deleteData {
                captureInfo.deleteAllFiles()
            }
            DispatchQueue.main.async {
                self.captures.removeAll(where: { $0.id == captureInfo.id })
            }
        }
    }
    
    /// This method populates the `CaptureInfo` array with all the image files contained in `captureDir` using a
    /// background queue.  This method publishes  to `captures` when complete.
    private func requestLoadCaptureInfo() -> Future<[CaptureInfo], Error> {
        // Iterate through all the image files in the directory, then extract
        // the photoIdString and id to create a CaptureInfo.
        // 從資料夾中載入圖像文件並創建相應的 CaptureInfo 對象
        let future = Future<[CaptureInfo], Error> { promise in
            guard self.captureDir != nil else {
                promise(.failure(.invalidCaptureDir))
                return
            }
            CaptureFolderState.workQueue.async {
                var captureInfoResults: [CaptureInfo] = []
                do {
                    let imgUrls = try FileManager.default
                        .contentsOfDirectory(at: self.captureDir!, includingPropertiesForKeys: [],
                                             options: [.skipsHiddenFiles])
                        .filter { $0.isFileURL &&
                            ($0.lastPathComponent.hasSuffix(CaptureInfo.imageSuffix) &&
                            !$0.lastPathComponent.hasSuffix("_depth.png"))
                        }
                    logger.info("imgUrls: \(imgUrls)")
                    for imgUrl in imgUrls {
                        guard let photoIdString = try? CaptureInfo.photoIdString(from: imgUrl) else {
                            print("Can't get photoIdString from url: \"\(imgUrl)\"")
                            continue
                        }
                        guard let captureId = try? CaptureInfo.extractId(from: photoIdString) else {
                            print("Can't get id from from photoIdString: \"\(photoIdString)\"")
                            continue
                        }
                        captureInfoResults.append(CaptureInfo(id: captureId, captureDir: self.captureDir!))
                    }
                    // Sort by the capture id.
                    captureInfoResults.sort(by: { $0.id < $1.id })
                    promise(.success(captureInfoResults))
                } catch {
                    promise(.failure(.invalidCaptureDir))
                    return
                }
            }
        }
        return future
    }
    
    // - MARK: Static methods
    
    /// The method returns a URL to the app's documents folder, where it stores all captures.
    static func capturesFolder() -> URL? {
        guard let documentsFolder =
                try? FileManager.default.url(for: .documentDirectory,
                                             in: .userDomainMask,
                                             appropriateFor: nil, create: false) else {
            return nil
        }
//        return documentsFolder.appendingPathComponent("Captures/", isDirectory: true)
        return documentsFolder
    }
    
    
    static func initializeProject() -> URL? {  // createCaptureDirectory
        guard let capturesFolder = CaptureFolderState.capturesFolder() else {
            print("Can't get user document dir!")
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "YYMMddHHmmss"
        self.projectName = formatter.string(from: Date())
        let newCaptureDir = capturesFolder
            .appendingPathComponent(projectName)
        
        print("Creating capture path: \"\(String(describing: newCaptureDir))\"")
        let capturePath = newCaptureDir.path
        do {
            try FileManager.default.createDirectory(atPath: capturePath,
                                                    withIntermediateDirectories: true)
        } catch {
            print("Failed to create capturepath=\"\(capturePath)\" error=\(String(describing: error))")
        }
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: capturePath, isDirectory: &isDir)
        guard exists && isDir.boolValue else {
            return nil
        }
        
//        manifest = Manifest()
//        
//        // The first frame will set these properly
//        manifest.w = 0
//        manifest.h = 0
//        
//        // These don't matter since every frame will redefine them
//        manifest.flX = 1.0
//        manifest.flY =  1.0
//        manifest.cx =  320
//        manifest.cy =  240
//        
//        manifest.depthIntegerScale = 1.0
        
        return newCaptureDir  /// file:///var/mobile/Containers/Data/Application/DA032602-1BCF-4E3C-AC0D-D8AF31147547/Documents/Captures/Aug%2017,%202024%20at%2010:33:35%E2%80%AFAM/
    }
    
    /// This method returns a `Future` instance that's populated with a list of capture folders sorted by creation date.
    static func requestCaptureFolderListing() -> Future<[URL], Never> {
        let future = Future<[URL], Never> { promise in
            workQueue.async {
                guard let docFolder = CaptureFolderState.capturesFolder() else {
                    promise(.success([]))
                    return
                }
                guard let folderListing =
                        try? FileManager.default
                        .contentsOfDirectory(at: docFolder,
                                             includingPropertiesForKeys: [.creationDateKey],
                                             options: [ .skipsHiddenFiles ]) else {
                    promise(.success([]))
                    return
                }
                // Sort by creation date, newest first.
                let sortedFolderListing = folderListing
                    .sorted { lhs, rhs in
                        creationDate(for: lhs) > creationDate(for: rhs)
                    }
                promise(.success(sortedFolderListing))
            }
        }
        return future
    }
    
    static func getCaptureTaskFromDisk(captureDir: URL) -> Future<String, Never> {
        let future = Future<String, Never> { promise in
            let filePath = captureDir.appendingPathComponent("captureTask.txt")
            guard let captureTask = try? String(contentsOf: filePath, encoding: .utf8) else {
                promise(.success(""))
                return
            }
            promise(.success(captureTask))
        }
        return future
    }
    
    static func getUploadInfoFromFile(captureDir: URL) -> Future<[String: Any], Never>  {
        let future = Future<[String: Any], Never> { promise in
            let filePath = captureDir.appendingPathComponent("uploadInfo.txt")
            let dummyUploadInfo: [String: Any] = [
                "captureID": "",
                "name": "Not Uploaded Yet",
                "task": "None"
            ]
            guard let data = try? Data(contentsOf: filePath) else {
                promise(.success(dummyUploadInfo))
                return
            }
            guard let uploadInfo =
                    try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                promise(.success(dummyUploadInfo))
                return
            }
            promise(.success(uploadInfo))
        }
        return future
    }
    
    private static func creationDate(for url: URL) -> Date {
        let date = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate
        
        if date == nil {
            logger.error("creation data is nil for: \(url.path).")
            return Date.distantPast
        } else {
            return date!
        }
    }
    
    /// This method requests the removal of the capture folder at a specified URL.
    @discardableResult
    static func removeCaptureFolder(folder: URL) -> Future<Bool, Swift.Error> {
        logger.log("Removing folder: \"\(folder.path)\"")
        let future = Future<Bool, Swift.Error> { promise in
            workQueue.async {
                do {
                    try FileManager.default.removeItem(atPath: folder.path)
                    promise(.success(true))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        return future
    }
}
