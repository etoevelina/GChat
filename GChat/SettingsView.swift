//
//  Settings.swift
//  GChat
//
//  Created by Эвелина Пенькова on 03.02.2024.
//

import SwiftUI
import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestoreSwift




    struct SettingsView: View {
        @ObservedObject private var vm = MainMessagesViewModel()
        @State var shouldShowLogOutOptions = false
        @State var nickname = ""
        @State var email = ""
        @State var shouldShowDeleteAccount = false
        @State var loginStatusMessage = ""
        @State private var isEditing = false
     
       
        init(vm: MainMessagesViewModel) {
                self.vm = vm
            }
        
        
        
        
        var body: some View {
            
            
            
            NavigationView{
                
                
                
                VStack{
                  
                        HStack(spacing: 16){
                            if isEditing {
                            Spacer()
                            
                            Button{
                                updateProfile()
                            }label: {
                                Text("Save edit data")
                            }
                            .padding()
                            //.disabled(!isEditing)
                            //.hidden(!isEditing)
                            }
                    }
                    Form {
                        
                        Section {
                            HStack{
                                WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipped()
                                    .cornerRadius(150)
                                    .overlay(RoundedRectangle(cornerRadius: 150)
                                        .stroke(Color(.label), lineWidth: 1)
                                    )
                                    .shadow(color: Color(.systemPink), radius: 6)
                                // .ignoresSafeArea()
                                
                                
                                
                                VStack{
                                    Group {
                                        TextField("Nickname", text: $nickname)
                                            .onChange(of: nickname) { _ in
                                                   isEditing = true
                                               }
                                            .multilineTextAlignment(.center)
                                        
                                        
                                        Text( vm.chatUser?.email ?? "")
                                            .frame(width: 140)
                                            
                                        
                                    }.onAppear {
                                        nickname = vm.chatUser?.nickname ?? ""
                                        //email = vm.chatUser?.email ?? ""
                                        isEditing = false
                                    }
                                    
                                    .padding(10)
                                    .background(Color(red: 0.99, green: 0.81, blue: 0.81))
                                    .cornerRadius(15)
                                    
                                }
                                
                            }
                            
                            
                        }
                        
                        Section ("Functions") {
                            
                            
                            Button {
                                
                                shouldShowDeleteAccount.toggle()
                                
                            } label: {
                                HStack{
                                    Image(systemName: "trash")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(red: 1, green: 0.45, blue: 0.45))
                                    
                                    Text("Delete account")
                                        .foregroundColor(Color(.label))
                                }
                            } .padding()
                            
                            
                            Button {
                                shouldShowLogOutOptions.toggle()
                            } label: {
                                HStack{
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(red: 1, green: 0.45, blue: 0.45))
                                    Text("Log Out")
                                        .foregroundColor(Color(.label))
                                }
                            }
                            
                            .padding()
                            .actionSheet(isPresented: $shouldShowLogOutOptions) {
                                .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
                                    .destructive(Text("Log Out"), action: {
                                        print("handle log out")
                                        vm.handleSignOut()
                                    }),
                                    .cancel()
                                ])
                            }
                            .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut, onDismiss: nil) {
                                ContentView(didCompleteLoginProcess: {
                                    self.vm.isUserCurrentlyLoggedOut = false
                                    self.vm.fetchCurrentUser()
                                    self.vm.fetchRecentMessages()
                                })
                            }
                        }
                    }
                }
            }
        }
        
        func updateProfile() {
            guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
                    print("Current user ID is nil")
                    return
                }

                // Обновление данных в Firestore
                FirebaseManager.shared.firestore.collection("users").document(userId).setData([
                    "nickname": nickname
                ], merge: true) { error in
                    if let error = error {
                        print("Error updating Firestore document: \(error)")
                    } else {
                        print("Firestore document successfully updated")
                    }
                }

            
            
            isEditing = false
        }

        func updateFirestoreData() {
            guard let currentUser = Auth.auth().currentUser else {
                return
            }
            
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(currentUser.uid)
            
            // Обновление данных пользователя в Firestore
            userRef.updateData([
                "nickname": nickname,
            ]) { error in
                if let error = error {
                    print("Error updating user data in Firestore: \(error.localizedDescription)")
                } else {
                    print("User data updated successfully in Firestore")
                }
            }
        }

        
    }
    


#Preview {
    SettingsView(vm: MainMessagesViewModel())
}
