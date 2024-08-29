//
//  DatasetWriter.swift
//  RealityCapture
//
//  Created by lychen on 2024/4/4.
//

import Foundation
import ARKit
import os

extension UIImage {
    func resizeImageTo(size targetSize: CGSize) -> UIImage? {
        let size = self.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        let ratio = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        self.draw(in: rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}

class DatasetWriter {

    enum SessionState {
        case SessionNotStarted
        case SessionStarted
    }
    
    var manifest = Manifest()
    var projectName = ""
    var projectDir = getDocumentsDirectory()
    var useDepthIfAvailable = true
    
    @Published var currentFrameCounter = 0
    @Published var writerState = SessionState.SessionNotStarted
        
    @Published var captureFolderState: CaptureFolderState?
    
    func projectExists(_ projectDir: URL) -> Bool {
        var isDir: ObjCBool = true
        return FileManager.default.fileExists(atPath: projectDir.absoluteString, isDirectory: &isDir)
    }
    
    func initializeProject() throws {
        print("datasetWriter: initialize project!")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYMMddHHmmss"
        projectName = dateFormatter.string(from: Date())
        projectDir = getDocumentsDirectory()
            .appendingPathComponent(projectName)
        if projectExists(projectDir) {
            throw AppError.projectAlreadyExists
        }
        
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true, attributes: nil)
        
        if projectExists(projectDir) {
            throw AppError.projectAlreadyExists
        }
        
        self.captureFolderState = CaptureFolderState(url: projectDir)
        
        manifest = Manifest()
        
        // The first frame will set these properly
        manifest.w = 0
        manifest.h = 0
        
        // These don't matter since every frame will redefine them
        manifest.flX = 1.0
        manifest.flY =  1.0
        manifest.cx =  320
        manifest.cy =  240
        
        manifest.depthIntegerScale = 1.0
        writerState = .SessionStarted
    }
    
    func clean() {
        guard case .SessionStarted = writerState else { return; }
        writerState = .SessionNotStarted
        DispatchQueue.global().async {
            do {
                try FileManager.default.removeItem(at: self.projectDir)
            }
            catch {
                print("Could not cleanup project files")
            }
        }
    }
    
    func finalizeProject(zip: Bool = false) {
        print("Finalize Project --- ")
        writerState = .SessionNotStarted
        let manifest_path = getDocumentsDirectory()
            .appendingPathComponent(projectName)
            .appendingPathComponent("metadata.json")
        writeManifestToPath(path: manifest_path)
    }
    
    func getCurrentFrameName() -> String {
        let frameName = String(format: "%04d", currentFrameCounter)
        return frameName
    }
    
    func getFrameMetadata(_ frame: ARFrame, withDepth: Bool = false) -> Manifest.Frame {
        let frameName = getCurrentFrameName()
        let filePath = "IMG_\(frameName).png"
        let depthPath = "IMG_\(frameName)_depth.TIF"
        let manifest_frame = Manifest.Frame(
            filePath: filePath,
            depthPath: withDepth ? depthPath : nil,
            transformMatrix: arrayFromTransform(frame.camera.transform),
            timestamp: frame.timestamp,
            flX:  frame.camera.intrinsics[0, 0],
            flY:  frame.camera.intrinsics[1, 1],
            cx:  frame.camera.intrinsics[2, 0],
            cy:  frame.camera.intrinsics[2, 1],
            w: Int(frame.camera.imageResolution.width),
            h: Int(frame.camera.imageResolution.height)
        )
        return manifest_frame
    }
    
    func writeManifestToPath(path: URL) {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .withoutEscapingSlashes
        if let encoded = try? encoder.encode(manifest) {
            do {
                try encoded.write(to: path)
            } catch {
                print(error)
            }
        }
    }
    
    func writeFrameToDisk(frame: ARFrame, viewModel: ARViewModel, useDepthIfAvailable: Bool = true) {
        let frameName =  "IMG_\(getCurrentFrameName()).png"
        let depthFrameName =  "IMG_\(getCurrentFrameName())_depth.TIF"
        let baseDir = projectDir//.appendingPathComponent("images")
        let fileName = baseDir.appendingPathComponent(frameName)
        let depthFileName = baseDir.appendingPathComponent(depthFrameName)
        
        if manifest.w == 0 {
            manifest.w = Int(frame.camera.imageResolution.width)
            manifest.h = Int(frame.camera.imageResolution.height)
            manifest.flX =  frame.camera.intrinsics[0, 0]
            manifest.flY =  frame.camera.intrinsics[1, 1]
            manifest.cx =  frame.camera.intrinsics[2, 0]
            manifest.cy =  frame.camera.intrinsics[2, 1]
        }
        
        
        viewModel.session?.captureHighResolutionFrame { [weak self] frame, error in
            guard let self = self else { return }
            guard let frame = frame, error == nil else {
                print("Error capturing high-resolution frame: \(String(describing: error))")
                return
            }
            
            let useDepth = frame.sceneDepth != nil && useDepthIfAvailable
            
            let frameMetadata = getFrameMetadata(frame, withDepth: useDepth)
            let rgbBuffer = pixelBufferToUIImage(pixelBuffer: frame.capturedImage)
            let depthBuffer = useDepth ? frame.sceneDepth!.depthMap : nil
            
            DispatchQueue.global().async {
                do {
                    // save image into png
                    let rgbData = rgbBuffer.pngData()
                    try rgbData?.write(to: fileName)

                    // save depth into tiff
                    if let depthBuffer = depthBuffer, useDepth {
                        let ciImage = CIImage(cvImageBuffer: depthBuffer)
                        let ciContext = CIContext()
                        if let tiffData = ciContext.tiffRepresentation(of: ciImage, format: .L16, colorSpace: CGColorSpaceCreateDeviceGray(), options: [:]) {
                            try tiffData.write(to: depthFileName)
                        }
                    }
                    
                    // create captureInfo
                    let captureInfo = CaptureInfo(id: UInt32(self.currentFrameCounter-1), captureDir: self.projectDir)
                    DispatchQueue.main.async {
                        self.manifest.frames.append(frameMetadata)
                        self.captureFolderState?.captures.append(captureInfo)
                        print("currentFrameCounter = \(self.currentFrameCounter)\nframeName = \(frameName)")
                    }
                }
                catch {
                    print(error)
                }
            }
            currentFrameCounter += 1
        }
    }
    
    
    // MARK: - API to upload images
    func createFormDataRequest(url: URL, files: [URL], boundary: String) -> URLRequest? {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
    
        let lineBreak = "\r\n"
        var body = Data()
        
        for fileURL in files {
            let filename = fileURL.lastPathComponent
            let data = try? Data(contentsOf: fileURL)
            let mimeType = "image/png"
            
            body.append("--\(boundary)\(lineBreak)")
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\(lineBreak)")
            body.append("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)")
            if let data = data {
                body.append(data)
            }
            body.append(lineBreak)
        }
        
        body.append("--\(boundary)--\(lineBreak)")
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
//        logger.log("request body = \(body)")
//        let base64Body = body.base64EncodedString()
//        print("request body (Base64) = \(base64Body)")
        
        return request
    }
    
    func uploadCapturedImages() {
//        guard let url = URL(string: "http://127.0.0.1:5000/upload_image") else { return }
        guard let url = URL(string: "http://192.168.31.115:5000/upload_image") else { return }
        let boundary = "Boundary-\(UUID().uuidString)"
        let imagePaths = getAllCapturedImagePaths(projectName: projectName)
        
        guard let request = createFormDataRequest(url: url, files: imagePaths, boundary: boundary) else { return }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
        }
        task.resume()
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
