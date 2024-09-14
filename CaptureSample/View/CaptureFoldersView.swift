/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SwiftUI view that displays folders of captured images.
*/
import Combine
import Foundation
import SwiftUI

import os

private let logger = Logger(subsystem: "com.lychen.CaptureSample",
                            category: "CaptureFoldersView")

struct CaptureFoldersView: View {
    @ObservedObject var model: ARViewModel
    @State var captureFolders: [URL] = []
    var isFromButton: Bool
    
    private var publisher: AnyPublisher<[URL], Never> {
        CaptureFolderState.requestCaptureFolderListing()
            .receive(on: DispatchQueue.main)
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
    
    var body: some View {
        ZStack {
            Color(red: 0, green: 0, blue: 0.001, opacity: 1).edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            List {
                ForEach(captureFolders, id: \.self) { folder in
                    CaptureFolderItem(model: model, url: folder, isFromButton: isFromButton)
                }
                .onDelete(perform: { indexSet in
                    let foldersToDelete = indexSet.map { captureFolders[$0] }
                    for folderToDelete in foldersToDelete {
                        logger.log("Removing: \(folderToDelete)")
                        CaptureFolderState.removeCaptureFolder(folder: folderToDelete)
                    }
                    captureFolders.remove(atOffsets: indexSet)
                })
            }
            .onReceive(publisher, perform: { folderListing in
                // Filter out the current folder so the app doesn't delete it
                // or recurse down into it.
                self.captureFolders = folderListing
//                    .filter {
//                    $0.lastPathComponent != model.captureDir!.lastPathComponent
//                }
            })
        }
        .navigationTitle("Captures")
        .navigationBarHidden(false)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Add an Edit button to enable deleting items.
            ToolbarItem {
                EditButton()
            }
        }
    }
}

struct CaptureFolderItem: View {
    private let thumbnailWidth: CGFloat = 50
    private let thumbnailHeight: CGFloat = 50
    
    @ObservedObject private var model: ARViewModel
    @StateObject private var ownedCaptureFolderState: CaptureFolderState
    var isFromButton: Bool
    @Environment(\.presentationMode) private var presentation
    @State var hasTask: Bool = false
        @State var captureTask: String = "" {
            didSet {
                if(captureTask == "") {
                    self.hasTask = false
                } else {
                    self.hasTask = true
                }
            }
        }
    
//    private var publisher: AnyPublisher<String, Never> {
//        CaptureFolderState.getCaptureTaskFromFile(captureDir: ownedCaptureFolderState.captureDir!)
//            .receive(on: DispatchQueue.main)
//            .replaceError(with: "")
//            .eraseToAnyPublisher()
//    }
    
    init(model: ARViewModel, url: URL, isFromButton: Bool) {
        self.model = model
        self._ownedCaptureFolderState = StateObject(wrappedValue: CaptureFolderState(url: url))
        self.isFromButton = isFromButton
    }
    
    var body: some View {
        if isFromButton {
            Button(action: {
                print("Selected folder URL: \(ownedCaptureFolderState.captureDir!)")
                self.presentation.wrappedValue.dismiss()
                // for closing the current view. => back to main capture view.
            }) {
                folderContent
            }
        } else {
            NavigationLink(destination: CaptureGalleryView(model: model,
                                                           observing: ownedCaptureFolderState, hasTask: hasTask)) {
                folderContent
            }
        }
    }
    private var folderContent: some View {
            HStack {
                if !ownedCaptureFolderState.captures.isEmpty {
                    AsyncThumbnailView(url: ownedCaptureFolderState.captures[0].imageUrl)
                        .frame(width: thumbnailWidth, height: thumbnailHeight)
                        .cornerRadius(10)
                        .clipped()
                } else {
                    Image(systemName: "xmark.rectangle")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .padding(8)
                        .frame(width: thumbnailWidth, height: thumbnailHeight)
                        .foregroundColor(.secondary)
                }
                VStack(alignment: .leading) {
                    Text(ownedCaptureFolderState.captureDir!.lastPathComponent)
                    HStack {
                        Text("\(ownedCaptureFolderState.captures.count) images")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
//                        Text("\(captureTask)")
//                            .foregroundColor(.green)
//                            .onReceive(publisher, perform: { task in
//                                if(task == "None") {
//                                    self.captureTask = ""
//                                } else {
//                                    self.captureTask = task
//                                }
//                            })
                    }
                }
            }
        }
}
