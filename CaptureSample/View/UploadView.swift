//
//  UploadView.swift
//  CaptureSample
//
//  Created by ryan on 2024/8/13.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import SwiftUI
import os

private let logger = Logger(subsystem: "com.lychen.CaptureSample", category: "UploadView")


struct UploadView: View {
    @ObservedObject var model: ARViewModel
    @ObservedObject var uploadManager: UploadManager
    
    @State var isUploading: Bool = false
    //@State var backToInitView: Bool = false
    
    @State var name: String = ""
    
    init(model: ARViewModel, uploadManager: UploadManager){
        self.model = model
        self.uploadManager = uploadManager
    }
    
    var body: some View {
        ZStack{
            Color(red: 0, green: 0, blue: 0.01, opacity: 1.0)
                .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            VStack{
                // there may be a carousel showing images to upload...
                Spacer()
                NameTextField(uploadManager: uploadManager)
                TaskTypeView(uploadManager: uploadManager)
                Spacer()
                UploadButtonView(model: model, uploadManager: uploadManager, isUploading: $isUploading)
            }
            .padding(.horizontal, 20.0)
            
            if(isUploading) {
                isUploadingView(model: model)
            }
        }
        .navigationBarHidden(isUploading)
    }
}

struct NameTextField: View {
    @State var name: String = ""
    @ObservedObject var uploadManager: UploadManager
    init(uploadManager: UploadManager){
        UITextField.appearance().backgroundColor = .lightGray
        self.uploadManager = uploadManager
    }
    
    var body: some View {
        VStack{
            HStack{
                Text("Name")
                    .font(.title2)
                    .foregroundColor(Color.white)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            
            TextField("Enter name", text: $name)
                .frame(height: 40)
                .textFieldStyle(.roundedBorder)
                .foregroundColor(.black)
                .onSubmit {
                    uploadManager.captureName = name
                    logger.info("uploadManager.captureName: \(uploadManager.captureName)")
                }
        }
        Spacer()
            .frame(height: 30)
    }
}

class SelectedIndex: ObservableObject{
    let indexToTask = ["COLMAP", "GS", "Sugar", "None"]
    @ObservedObject var uploadManager: UploadManager
    @Published var index: Int {
        didSet{
            uploadManager.captureTask = indexToTask[index]
            logger.info("uploadManager.captureTask: \(self.uploadManager.captureTask)")
        }
    }
    init(index: Int, uploadManager: UploadManager){
        self.index = index
        self.uploadManager = uploadManager
    }
}

struct TaskTypeView: View {
    @StateObject var selectedIndex: SelectedIndex
    @ObservedObject var uploadManager: UploadManager

    init(uploadManager: UploadManager){
        UISegmentedControl.appearance().selectedSegmentTintColor = .white
        UISegmentedControl.appearance().backgroundColor = .lightGray
        UISegmentedControl.appearance().tintColor = .black
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor : UIColor.black], for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor : UIColor.black], for: .selected)
        let init_index = 0
        self._selectedIndex = StateObject(wrappedValue: SelectedIndex(index: init_index, uploadManager: uploadManager))
        self.uploadManager = uploadManager
    }
    
    var body: some View {
        VStack{
            HStack{
                Text("Task")
                    .font(.title2)
                    .foregroundColor(Color.white)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            Picker(selection: self.$selectedIndex.index, label: /*@START_MENU_TOKEN@*/Text("Picker")/*@END_MENU_TOKEN@*/) {
                Text("COLMAP").tag(0)
                Text("GS").tag(1)
                Text("SuGAR").tag(2)
                Text("None").tag(3)
            }
            .pickerStyle(.segmented)
            .frame(height: 40)
            .foregroundColor(.black)
            Spacer()
                .frame(height: 30)
        }
    }
}

struct UploadButtonView: View {
    @ObservedObject var model: ARViewModel
    @ObservedObject var uploadManager: UploadManager
    @Binding var isUploading: Bool
//    @Binding var name: String
    
    var body: some View {
        Button(action: {
            isUploading = true
            Task {
                await uploadManager.upload()
//                await uploadManager.getAllCaptures()
//                await uploadManager.createCapture()
//                await uploadManager.updateCapture(name: name)
            }
        }, label: {
            Text("Upload")
                .padding(.horizontal, 20.0)
                .padding(.vertical, 10.0)
                .font(.title)
        })
        .buttonStyle(.borderedProminent)
        .tint(.blue)
    }
}


struct UploadIconButtonView: View {

    @ObservedObject var uploadManager: UploadManager
    @Binding var showUploadView: Bool
    
    init(uploadManager: UploadManager, showUploadView: Binding<Bool>){
        self.uploadManager = uploadManager
        self._showUploadView = showUploadView
    }
    
    var body: some View {
        Button(action: {
            print("Press Upload Icon!!")
            Task{
                await uploadManager.loadCaptureData()
            }
            showUploadView = true
        }, label: {
            Image(systemName: "square.and.arrow.up")
        })
    }
}

struct isUploadingView: View {
    @ObservedObject var model: ARViewModel
    @State var backToInitView: Bool = false
    
    init(model: ARViewModel){
        self.model = model
    }
    
    var body: some View {
        ZStack{
            Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 0.8)
                .edgesIgnoringSafeArea(.all)
            if(model.isUploading) {
                Text("Uploading ...")
                    .foregroundColor(.white)
                    .font(.largeTitle)
            }
            else {
                VStack{
                    HStack{
                        Text("Done Uploading")
                            .foregroundColor(.white)
                            .font(.title)
                        Image(systemName: "smiley")
                            .foregroundColor(.white)
                            .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    }
                    Spacer()
                        .frame(height: 60)
                    Button(action: {
                        backToInitView = true
                    }, label: {
                        Text("Back to main page")
                            .padding(.horizontal, 20.0)
                            .padding(.vertical, 10.0)
                            .font(.title)
                    })
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
            NavigationLink(destination: InitView(model: model),
                            isActive: self.$backToInitView) {
                EmptyView()
            }
                            .frame(width: 0, height: 0)
                            .disabled(true)
        }
    }
}

//#if DEBUG
//struct UploadView_Previews: PreviewProvider {
//    static var previews: some View {
//        var datasetWriter = DatasetWriter()
//        let model = ARViewModel(datasetWriter: datasetWriter)
//        UploadView(model: model)
//    }
//}
//#endif // DEBUG
