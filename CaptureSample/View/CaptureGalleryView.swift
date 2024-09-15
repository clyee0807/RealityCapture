/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A custom view that displays the contents of a capture directory.
*/
import Combine
import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// This view displays the contents of a capture directory.
struct CaptureGalleryView: View {
    private let columnSpacing: CGFloat = 3
    
    /// This is the data model the capture session uses.
    @ObservedObject var model: ARViewModel
    
    /// This property holds the folder the user is currently viewing.
    @ObservedObject private var captureFolderState: CaptureFolderState
    
    /// When a thumbnail cell is tapped, this property holds the information about the tapped image.
    @State var zoomedCapture: CaptureInfo? = nil
    
    /// When this is set to `true`, the app displays a toolbar button to dispays the capture folder.
    @State private var showCaptureFolderView: Bool = false
    
    @State private var showUploadView = false
    
    @State private var copied: Bool = false
        
    private enum Progress {
        case waitingToGenerate
        case genetating
        case doneGenerate
    }
    private var progress: Progress = .doneGenerate
    private var hasTask: Bool
    var viewerLink: String = "https://www.google.com.tw/?hl=zh_TW"
        

    
    @StateObject private var uploadManager: UploadManager
    
    /// This property indicates whether the app is currently displaying the capture folder for the live session.
    let usingCurrentCaptureFolder: Bool
    
    /// This array defines the vertical layout for portrait orientation.
    let portraitLayout: [GridItem] = [ GridItem(.flexible()),
                                       GridItem(.flexible()),
                                       GridItem(.flexible()) ]
    
    let screenSize: CGRect = UIScreen.main.bounds
    let isCapturing: Bool
    let hasBeenUploaded: Bool
    
    /// This initializer creates a capture gallery view for the active capture session.
    init(model: ARViewModel) {
        self.model = model
        self.captureFolderState = model.captureFolderState!
        self.hasTask = false
        usingCurrentCaptureFolder = true
        isCapturing = true
        hasBeenUploaded = false
        
        self._uploadManager = StateObject(
            wrappedValue: UploadManager(captureFolderState: model.captureFolderState!, isReupload: false)
        )
    }
    
    /// This initializer creates a capture gallery view for a previously created capture folder.
    init(model: ARViewModel, observing captureFolderState: CaptureFolderState, hasTask: Bool) {
        self.model = model
        self.captureFolderState = captureFolderState
        self.hasTask = hasTask
        usingCurrentCaptureFolder = (model.captureFolderState?.captureDir?.lastPathComponent
                                        == captureFolderState.captureDir?.lastPathComponent)
        isCapturing = false
        hasBeenUploaded = false
        
        let isReupload: Bool = FileManager.default.fileExists(atPath: captureFolderState.captureDir!.appendingPathComponent("captureId.txt").path)
        self._uploadManager = StateObject(
            wrappedValue: UploadManager(captureFolderState: captureFolderState, isReupload: isReupload)
        )
    }
    
    var body: some View {
        ZStack {
            Color(red: 0, green: 0, blue: 0.01, opacity: 1).ignoresSafeArea(.all)
            
            // Create a hidden navigation link for the toolbar item.
            NavigationLink(destination: CaptureFoldersView(model: model, isFromButton: false),
                           isActive: self.$showCaptureFolderView) {
                EmptyView()
            }
            .frame(width: 0, height: 0)
            .disabled(true)
            
            NavigationLink(destination: UploadView(model: model, uploadManager: uploadManager),
                            isActive: self.$showUploadView) {
                EmptyView()
            }
                            .frame(width: 0, height: 0)
                            .disabled(true)
            
            GeometryReader { geometryReader in
                ScrollView() {
                    LazyVGrid(columns: portraitLayout, spacing: columnSpacing) {
                        ForEach(captureFolderState.captures, id: \.id) { captureInfo in
                            GalleryCell(captureInfo: captureInfo,
                                        cellWidth: geometryReader.size.width / 3,
                                        cellHeight: geometryReader.size.width / 3,
                                        zoomedCapture: $zoomedCapture)
                        }
                    }
                }
            }
            .blur(radius: zoomedCapture != nil ? 20 : 0)
            
            VStack {
                Spacer()
                if (hasTask) {
                    if (progress == .waitingToGenerate) {
                        Text("Waiting to generate...")
                            .font(.title2)
                            .padding(20)
                            .frame(width: screenSize.width * 0.9)
                            .background(
                                Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 0.5)
                                    .cornerRadius(10)
                            )
                    } else if (progress == .genetating) {
                        Text("Generating...")
                            .font(.title2)
                            .padding(20)
                            .frame(width: screenSize.width * 0.9)
                            .background(
                                Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 0.5)
                                    .cornerRadius(10)
                            )
                    } else if (progress == .doneGenerate) {
                        let copyButtonForegroundColor = copied ? Color.white : Color.black
                        let copyButtonBackgroundColor = copied ? Color.black : Color.white
                        VStack {
                            HStack {
                                Text("Generation is done!\ncheck with the link below")
                                    .font(.title3)
                                Spacer()
                            }
                            Spacer()
                                .frame(height: 30)
                            HStack {
                                Text("\(viewerLink)")
                                Spacer()
                                Button(action: {
                                    UIPasteboard.general.setValue(viewerLink, forPasteboardType: UTType.plainText.identifier)
                                    self.copied = true
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .padding(2)
                                        .foregroundColor(copyButtonForegroundColor)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(copyButtonBackgroundColor)
                            }
                        }
                        .padding(20)
                        .frame(width: screenSize.width * 0.9)
                        .background(
                            Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 0.5)
                                .cornerRadius(10)
                            )
                    }
                }
                Spacer()
                    .frame(height: 60)
            }

            if zoomedCapture != nil {
                ZStack(alignment: .top) {
                    // Add a transluscent layer over the blur to make the text pop.
                    Color(red: 0.25, green: 0.25, blue: 0.25, opacity: 0.25)
                        .ignoresSafeArea(.all)
                    
                    VStack {
                        FullSizeImageView(captureInfo: zoomedCapture!)
                            .onTapGesture {
                                zoomedCapture = nil
                            }
                    }
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            captureFolderState.removeCapture(captureInfo: zoomedCapture!,
                                                             deleteData: true)
                            zoomedCapture = nil
                        }) {
                            Text("Delete").foregroundColor(Color.red)
                        }.padding()
                    }
                }
            }
        }
        .navigationTitle(Text("\(captureFolderState.captureDir?.lastPathComponent ?? "NONE")"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: HStack {
            Spacer()
            UploadIconButtonView(uploadManager: self.uploadManager, showUploadView: self.$showUploadView)
        })
    }
}

struct NewSessionButtonView: View {
    @ObservedObject var model: ARViewModel
    
    /// This is an environment variable that the capture gallery view uses to store state.
    @Environment(\.presentationMode) private var presentation
    @State private var showAlert = false
    @State private var lastCaptureUrl: URL? = nil
    
    var usingCurrentCaptureFolder: Bool = true
    
    var body: some View {
            // Only show the new session if the user is viewing the current
            // capture directory.
            if usingCurrentCaptureFolder {
                Menu(content: {
                    Button(action: {
                        lastCaptureUrl = model.captureDir
                        model.requestNewCaptureFolder()
                    }) {
                        Label("New Session", systemImage: "camera")
                    }
                }, label: {
                    Image(systemName: "plus.circle")
                })
            }
        }
}

/// This cell displays a single thumbnail image with its metadata annotated on it.
struct GalleryCell: View {
    /// This property stores the location of the image and its metadata.
    let captureInfo: CaptureInfo
    
    /// When the user taps a cell to zoom in, this property contains the tapped cell's `captureInfo`.
    @Binding var zoomedCapture: CaptureInfo?
    
    /// This property keeps track of whether the image's metadata files exist. The app populates this
    /// property asynchronously.
    @State private var existence: CaptureInfo.FileExistence = CaptureInfo.FileExistence()
    
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    
    // This property holds a reference for a subscription to the `existence` future.
    var publisher: AnyPublisher<CaptureInfo.FileExistence, Never>
    
    init(captureInfo: CaptureInfo, cellWidth: CGFloat, cellHeight: CGFloat,
         zoomedCapture: Binding<CaptureInfo?>) {
        self.captureInfo = captureInfo
        self.cellWidth = cellWidth
        self.cellHeight = cellHeight
        self._zoomedCapture = zoomedCapture
        
        // Make a single publisher for the metadata future.
        publisher = captureInfo.checkFilesExist()
            .receive(on: DispatchQueue.main)
            .replaceError(with: CaptureInfo.FileExistence())
            .eraseToAnyPublisher()
        }
    
    var body : some View {
        ZStack {
            AsyncThumbnailView(url: captureInfo.imageUrl)
                .frame(width: cellWidth, height: cellHeight)
                .clipped()
                .onTapGesture {
                    withAnimation {
                        self.zoomedCapture = captureInfo
                    }
                }
                .onReceive(publisher, perform: { loadedExistence in
                    existence = loadedExistence
                })
            MetadataExistenceSummaryView(existence: existence)
                .font(.caption)
                .padding(.all, 2)
        }
    }
}

struct MetadataExistenceSummaryView: View {
    var existence: CaptureInfo.FileExistence
    private let paddingPixels: CGFloat = 2
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                if existence.depth {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.green)
                        .padding(.all, paddingPixels)
                } else if existence.depth {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(Color.yellow)
                        .padding(.all, paddingPixels)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.red)
                        .padding(.all, paddingPixels)
                }
                Spacer()
            }
        }
    }
}

struct MetadataExistenceView: View {
    var existence: CaptureInfo.FileExistence
    var textLabels: Bool = false
    
    var body: some View {
        HStack {
            if existence.depth {
                Image(systemName: "square.3.stack.3d.top.fill")
                    .foregroundColor(Color.green)
            } else {
                Image(systemName: "xmark.circle")
                    .foregroundColor(Color.red)
            }
            if textLabels {
                Text("Depth")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
        }
    }
}

/// This is the view the app shows when the user taps on a `GalleryCell` thumbnail. It asynchronously
/// loads the full-size image and displays it full-screen.
struct FullSizeImageView: View {
    let captureInfo: CaptureInfo
    var publisher: AnyPublisher<CaptureInfo.FileExistence, Never>
    
    @State private var existence = CaptureInfo.FileExistence()
    
    init(captureInfo: CaptureInfo) {
        self.captureInfo = captureInfo
        publisher = captureInfo.checkFilesExist()
            .receive(on: DispatchQueue.main)
            .replaceError(with: CaptureInfo.FileExistence())
            .eraseToAnyPublisher()
    }
    
    var body: some View {
        VStack {
            Text(captureInfo.imageUrl.lastPathComponent)
                .font(.caption)
                .padding()
            GeometryReader { geometryReader in
                AsyncImageView(url: captureInfo.imageUrl)
                    .frame(width: geometryReader.size.width, height: geometryReader.size.height)
                    .aspectRatio(contentMode: .fit)
            }
            MetadataExistenceView(existence: existence, textLabels: true)
                .onReceive(publisher, perform: { loadedExistence in
                    existence = loadedExistence
                })
                .padding(.all)
        }
        .transition(.opacity)
    }
}
