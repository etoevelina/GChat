//
//  ChatMessage.swift
//  GChat
//
//  Created by Эвелина Пенькова on 01.02.2024.
//

import Foundation
import FirebaseFirestoreSwift

struct ChatMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let fromId, toId, text: String
    let timestamp: Date
}
