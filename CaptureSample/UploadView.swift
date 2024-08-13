//
//  UploadView.swift
//  CaptureSample
//
//  Created by ryan on 2024/8/13.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import SwiftUI

struct UploadView: View {
    @ObservedObject var model: CameraViewModel
    @State var isUploading: Bool = false
    //@State var backToInitView: Bool = false
    var body: some View {
        ZStack{
            Color(red: 0, green: 0, blue: 0.01, opacity: 1.0)
                .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            VStack{
                // there may be a carousel showing images to upload...
                Spacer()
                NameTextField()
                ModelTypeView()
                Spacer()
                UploadButtonView(model: model, isUploading: $isUploading)
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
    init(){
        UITextField.appearance().backgroundColor = .lightGray
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
            
            TextField("\(name)", text: $name)
                .frame(height: 40)
                .textFieldStyle(.roundedBorder)
                .foregroundColor(.black)
                .onSubmit {}
        }
        Spacer()
            .frame(height: 30)
    }
}

class SelectedIndex: ObservableObject{
    @Published var index: Int {
        didSet{
            if index == 0{
            }
            else if index == 1{
            }
            else if index == 2{
            }
            else if index == 3{
            }
        }
    }
    init(index: Int){
        self.index = index
    }
}

struct ModelTypeView: View {
    @StateObject var selectedIndex: SelectedIndex
    
    init(){
        UISegmentedControl.appearance().selectedSegmentTintColor = .white
        UISegmentedControl.appearance().backgroundColor = .lightGray
        UISegmentedControl.appearance().tintColor = .black
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor : UIColor.black], for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor : UIColor.black], for: .selected)
        let init_index = 0
        self._selectedIndex = StateObject(wrappedValue: SelectedIndex(index: init_index))
    }
    
    var body: some View {
        VStack{
            HStack{
                Text("Mode")
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
    @ObservedObject var model: CameraViewModel
    @Binding var isUploading: Bool
    var body: some View {
        Button(action: {
            model.startStimulateUpload()
            isUploading = true
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

struct isUploadingView: View {
    @ObservedObject var model: CameraViewModel
    @State var backToInitView: Bool = false
    
    init(model: CameraViewModel){
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

#if DEBUG
struct UploadView_Previews: PreviewProvider {
    @StateObject private static var model = CameraViewModel()
    static var previews: some View {
        UploadView(model: model)
    }
}
#endif // DEBUG
