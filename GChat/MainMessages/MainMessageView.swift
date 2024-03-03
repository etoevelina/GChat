//
//  MainMessageView.swift
//  GChat
//
//  Created by Эвелина Пенькова on 01.02.2024.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestoreSwift
//import PromiseKit

class MainMessagesViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    @Published var isUserCurrentlyLoggedOut = false
  
    
    init() {
        
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        
        fetchCurrentUser()
        
        fetchRecentMessages()
    }
    
    @Published var recentMessages = [RecentMessage]()
    
    private var firestoreListener: ListenerRegistration?
    
    func fetchRecentMessages() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        firestoreListener?.remove()
        self.recentMessages.removeAll()
        
        firestoreListener = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.recentMessages)
            .document(uid)
            .collection(FirebaseConstants.messages)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for recent messages: \(error)"
                    print(error)
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    let docId = change.document.documentID
                    
                    if let index = self.recentMessages.firstIndex(where: { rm in
                        return rm.id == docId
                    }) {
                        self.recentMessages.remove(at: index)
                    }
                    
                    do {
                        if let rm = try? change.document.data(as: RecentMessage.self) {
                            self.recentMessages.insert(rm, at: 0)
                        }
                    } catch {
                        print(error)
                    }
                })
            }
    }
    
    func fetchCurrentUser() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            self.errorMessage = "Could not find firebase uid"
            return
        }
        
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                self.errorMessage = "Failed to fetch current user: \(error)"
                print("Failed to fetch current user:", error)
                return
            }
            
            self.chatUser = try? snapshot?.data(as: ChatUser.self)
            FirebaseManager.shared.currentUser = self.chatUser
            
        }
    }
    
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
    
}

struct MainMessagesView: View {
    
    @State var shouldShowLogOutOptions = false
    
    @State var shouldNavigateToChatLogView = false
    
    @ObservedObject private var vm = MainMessagesViewModel()
    
    private var chatLogViewModel = ChatLogViewModel(chatUser: nil)
    
    var body: some View {
        
        NavigationView {
            
            VStack {
                
                customNavBar
                
                messagesView
                
                
                
                
                NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                    ChatLogView(vm: chatLogViewModel)
                }
            }
            
            .navigationBarHidden(true)
        }
        
    }
    
    private var customNavBar: some View {
        HStack() {
            HStack{
                WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipped()
                    .cornerRadius(50)
                    .overlay(RoundedRectangle(cornerRadius: 44)
                        .stroke(Color(.label), lineWidth: 1)
                    )
                    .shadow(radius: 5)
                
                
                VStack(alignment: .leading, spacing: 4) {
                    // let email = vm.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? ""
                    Text(vm.chatUser?.nickname ?? "" )
                        .font(.system(size: 24, weight: .bold))
                    
                    
                    HStack {
                        Circle()
                            .foregroundColor(.green)
                            .frame(width: 14, height: 14)
                        Text("online")
                            .font(.system(size: 12))
                            .foregroundColor(Color(.lightGray))
                    }
                    
                }
            }
            
            Spacer()
            
            Button {
                shouldShowNewMessageScreen.toggle()
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "plus")
                        .font(.system(size: 26))
                    // Spacer()
                }
                .foregroundColor(.blue)
                .padding(.vertical)
                
                .cornerRadius(32)
                .padding(.horizontal)
                .shadow(radius: 15)
            }
            .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
                CreateNewMessageView(didSelectNewUser: { user in
                    print(user.email)
                    self.shouldNavigateToChatLogView.toggle()
                    self.chatUser = user
                    self.chatLogViewModel.chatUser = user
                    self.chatLogViewModel.fetchMessages()
                })
            }
            
        }
        .padding()
        
        
        
        
    }
    
    private var messagesView: some View {
        
        // NavigationView {
        //         ScrollView {
        List { ForEach(vm.recentMessages) { recentMessage in
            VStack {
                Button {
                    let uid = FirebaseManager.shared.auth.currentUser?.uid == recentMessage.fromId ? recentMessage.toId : recentMessage.fromId
                    
                    self.chatUser = .init(id: uid, uid: uid, email: recentMessage.email, nickname: recentMessage.nickname, profileImageUrl: recentMessage.profileImageUrl)
                    
                    self.chatLogViewModel.chatUser = self.chatUser
                    self.chatLogViewModel.fetchMessages()
                    self.shouldNavigateToChatLogView.toggle()
                } label: {
                    HStack(spacing: 16) {
                        WebImage(url: URL(string: recentMessage.profileImageUrl))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipped()
                            .cornerRadius(64)
                            .overlay(RoundedRectangle(cornerRadius: 64)
                                .stroke(Color.black, lineWidth: 1))
                            .shadow(radius: 5)
                        
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recentMessage.nickname)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(.label))
                                .multilineTextAlignment(.leading)
                            Text(recentMessage.text)
                                .font(.system(size: 14))
                                .foregroundColor(Color(.darkGray))
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        
                        Text(recentMessage.timeAgo)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.label))
                    }
                }
                
                
                
                // Divider()
                .padding(.vertical, 8)
            }//.padding(.horizontal)
            
        }.swipeActions{
            Button {
                deleteMassages()
            } label: {
                Text("Delete")
            }
            .tint(.red)
        }
            
            
            
        }.listStyle(PlainListStyle())
        //     }
        //   }
    }
    

    func deleteMassages() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }

        let dispatchGroup = DispatchGroup()

        // Удаляем все сообщения, отправленные текущим пользователем к выбранному пользователю
        let sentMessagesRef = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(toId)

        dispatchGroup.enter()
        sentMessagesRef.getDocuments { snapshot, error in
            defer { dispatchGroup.leave() }
            if let error = error {
                print("Error fetching sent messages: \(error)")
                return
            }

            guard let documents = snapshot?.documents else { return }

            for document in documents {
                dispatchGroup.enter()
                document.reference.delete { error in
                    if let error = error {
                        print("Error deleting sent message: \(error)")
                    }
                    dispatchGroup.leave()
                }
            }
        }

       
        let receivedMessagesRef = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.messages)
            .document(toId)
            .collection(fromId)

        dispatchGroup.enter()
        receivedMessagesRef.getDocuments { snapshot, error in
            defer { dispatchGroup.leave() }
            if let error = error {
                print("Error fetching received messages: \(error)")
                return
            }

            guard let documents = snapshot?.documents else { return }

            for document in documents {
                dispatchGroup.enter()
                document.reference.delete { error in
                    if let error = error {
                        print("Error deleting received message: \(error)")
                    }
                    dispatchGroup.leave()
                }
            }
        }

        // Удаляем информацию о последнем сообщении в коллекции recentMessages
        let lastMessageRefFrom = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.recentMessages)
            .document(fromId)
            .collection(FirebaseConstants.messages)
            .document(toId)

        let lastMessageRefTo = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.recentMessages)
            .document(toId)
            .collection(FirebaseConstants.messages)
            .document(fromId)

        dispatchGroup.enter()
        let batch = FirebaseManager.shared.firestore.batch()
        batch.deleteDocument(lastMessageRefFrom)
        batch.deleteDocument(lastMessageRefTo)
        batch.commit { error in
            if let error = error {
                print("Error deleting last message records: \(error)")
            }
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            // Обновляем ваш пользовательский интерфейс здесь, например, обновляем массив recentMessages
             vm.fetchRecentMessages()
        }
    }

    @State var shouldShowNewMessageScreen = false
    
  //  private var newMessageButton: some View {
      
   // }
    
    @State var chatUser: ChatUser?
}

struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
            
    }
}

