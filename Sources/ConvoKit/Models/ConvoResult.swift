//
//  ConvoTranscription.swift
//
//
//  Created by Andreas Ink on 1/3/24.
//

import SwiftUI

public struct ConvoResult {
    
    public init(functionName: String, transcription: [AudioTranscription], chatMessage: [ChatMessage]) {
        self.functionName = functionName
        self.transcription = transcription
        self.chatMessage = chatMessage
    }
    
    public let id = UUID()
    public var functionName: String
    public var transcription: [AudioTranscription]
    public var chatMessage: [ChatMessage]
}
