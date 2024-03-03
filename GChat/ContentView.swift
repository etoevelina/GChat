//
//  ContentView.swift
//  GChat
//
//  Created by Эвелина Пенькова on 01.02.2024.
//

import SwiftUI
import Firebase
import RiveRuntime
import FirebaseAuth



struct RoundedCornerShape: Shape { // 1
    let radius: CGFloat
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path { // 2
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct ContentView: View {
    
    
    
    
    let didCompleteLoginProcess: () -> ()
    
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var nickname = ""
    @State private var shouldShowImagePicker = false
    
   @StateObject var riveModel = RiveViewModel(fileName: "animation")
    
    
    
//@StateObject var hhh = RiveViewModel(fileName: "confettee", stateMachineName: "Machine1")
    
    var body: some View {
        
     
        
            NavigationView {
                ZStack{
                    
    
                    riveModel.view()
                        .ignoresSafeArea()
                        .blur(radius: 90)
                    
                    
                ScrollView {
                    
                    VStack(spacing: 16) {
                        Picker(selection: $isLoginMode, label: Text("Picker here")) {
                            Text("Login")
                            .tag(true)
                            Text("Create Account")
                                .tag(false)
                        }.pickerStyle(SegmentedPickerStyle())
                            .opacity(0)
                        
                        if isLoginMode {
                            Image("iconpng")
                                .resizable()
                                .frame(width: 210, height: 170)
                        }
                        
                        if !isLoginMode {
                            Button {
                                shouldShowImagePicker.toggle()
                            } label: {
                                
                                VStack {
                                    if let image = self.image {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 150, height: 150)
                                            .cornerRadius(150)
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 80))
                                            .padding()
                                            .foregroundColor(Color(.label))
                                    }
                                }
                                .overlay(RoundedRectangle(cornerRadius: 150)
                                    .stroke(Color.black, lineWidth: 2)
                                )
                                
                            }
                            
                            TextField("Nickname", text: $nickname)
                                .padding(20)
                                .background(Color.white)
                                .cornerRadius(15)
                                
                        }
                        
                        
                        
                        Group {
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            SecureField("Password", text: $password)
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(15)
                        
                      
                        
                        
                        Button {
                            handleAction()
                            
                        } label: {
                            HStack {
                                Spacer()
                                Text(isLoginMode ? "Log In" : "Create Account")
                                    
                                    .foregroundColor(.white)
                                    .padding(.vertical, 20)
                                    .font(.system(size: 20, weight: .semibold))
                                Spacer()
                            }.background(Color(red: 0.99, green: 0.37, blue: 0.37)).opacity(0.84)
                                .clipShape( // 1
                                    RoundedCornerShape( // 2
                                        radius: 20,
                                        corners: [.bottomLeft, .bottomRight, .topRight]
                                    )
                                )
                            //    .cornerRadius(20, corners: [.topRight])
                            
                        }
                        
                        Text("OR")
                        
                        Button {
                                  isLoginMode.toggle()
                        } label: {
                            Text(isLoginMode ? "Create Account" : "Cancel")
                                      .foregroundColor(Color(.darkGray))
                                      .padding(.vertical, 20)
                                      .font(.system(size: 20, weight: .semibold))
                                      .padding(.horizontal)
                              }
                              .background(Color(.init(white: 0, alpha: 0.05)).cornerRadius(20).padding(.top, 10))
                        
                        
                        Text(self.loginStatusMessage)
                            .foregroundColor(.red)
                    }
                    .padding()
                    
                    
                    
                    
                    
                    
                    
                }
                .background(Color(.init(white: 0, alpha: 0.05))
                    .ignoresSafeArea())
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
            ImagePicker(image: $image)
                .ignoresSafeArea()
        }
    
    }
    
    @State var image: UIImage?
    
    private func handleAction() {
        if isLoginMode {
//            print("Should log into Firebase with existing credentials")
            loginUser()
            
        } else {
            createNewAccount()
            
//            print("Register a new account inside of Firebase Auth and then store image in Storage somehow....")
        }
    }
    
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, err in
            if let err = err {
                print("Failed to login user:", err)
                self.loginStatusMessage = "Failed to login user: \(err)"
                return
            }
            
            print("Successfully logged in as user: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "Successfully logged in as user: \(result?.user.uid ?? "")"
            
            self.didCompleteLoginProcess()
        }
    }
    
    @State var loginStatusMessage = ""
    
    private func createNewAccount() {
        if self.image == nil {
            self.loginStatusMessage = "You must select an avatar image"
            return
        }
        
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, err in
            if let err = err {
                print("Failed to create user:", err)
                self.loginStatusMessage = "Failed to create user: \(err)"
                return
            }
            
            
            
            print("Successfully created user: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "Successfully created user: \(result?.user.uid ?? "")"
            
            self.persistImageToStorage()
            
            
        }
        
        
    }
    
    
    
    
    private func persistImageToStorage() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                self.loginStatusMessage = "Failed to push image to Storage: \(err)"
                return
            }
            
            ref.downloadURL { url, err in
                if let err = err {
                    self.loginStatusMessage = "Failed to retrieve downloadURL: \(err)"
                    return
                }
                
                self.loginStatusMessage = "Successfully stored image with url: \(url?.absoluteString ?? "")"
                print(url?.absoluteString ?? "")
                
                guard let url = url else { return }
                
                
                self.storeUserInformation(imageProfileUrl: url)
            }
        }
    }
    
    private func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let userData = [FirebaseConstants.email: self.email, 
                        FirebaseConstants.uid: uid,
                        FirebaseConstants.nickname: self.nickname,
                        FirebaseConstants.profileImageUrl: imageProfileUrl.absoluteString]
        FirebaseManager.shared.firestore.collection(FirebaseConstants.users)
            .document(uid).setData(userData) { err in
                if let err = err {
                    print(err)
                    self.loginStatusMessage = "\(err)"
                    return
                }
                
                print("Success")
                
                self.didCompleteLoginProcess()
            }
    }
}

struct ContentView_Previews1: PreviewProvider {
    static var previews: some View {
        ContentView(didCompleteLoginProcess: {
            
        })
    }
}

