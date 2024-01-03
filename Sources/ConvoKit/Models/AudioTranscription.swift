//
//  AudioTranscription.swift
//  
//
//  Created by Andreas Ink on 1/3/24.
//

import SwiftUI

public struct AudioTranscription: Codable {
    public var id = UUID().uuidString
    public var text: String
    public var timestamp: Double
    public var audioData: Data
    
    public init(id: String = UUID().uuidString, text: String, timestamp: Double, audioData: Data) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.audioData = audioData
    }
}
