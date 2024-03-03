//
//  ChatUser.swift
//  GChat
//
//  Created by Эвелина Пенькова on 01.02.2024.
//

import FirebaseFirestoreSwift

struct ChatUser: Codable, Identifiable {
    @DocumentID var id: String?
    var uid, email, nickname, profileImageUrl: String
}
