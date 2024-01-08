//
//  ConvoChat.swift
//
//
//  Created by Andreas Ink on 1/3/24.
//

import SwiftUI

public struct GPTMessage: Codable {
    let role: String
    let content: String
}

public struct GPTChoice: Codable {
    let message: GPTMessage
    let finishReason: String?
    let index: Int
}

public struct GPTResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [GPTChoice]
}

/// The chat message object used for each chat conversation message.
public struct ChatMessage: Codable, Identifiable {
    
    private enum CodingKeys: String, CodingKey {
        case role, content
    }

    /// ID used for iterating through list of chat messages
    public var id = UUID().uuidString

    /// The person sending the message
    let role: ChatRole

    /// The message itself
    var content: String

    public init(role: ChatRole, content: String) {
        self.role = role
        self.content = content
    }

    public var body: [String: String] {
        return [
            "role": self.role.rawValue,
            "content": self.content
        ]
    }
}
public enum ChatRole: String, Codable {
    case system
    case assistant
    case user
}

public struct ChatInput: Codable, Identifiable {
    public var id = UUID().uuidString
    var directResponse: String
    var messages: [ChatMessage]
    
    static var emptyChat = ChatInput(directResponse: "", messages: [])
}
