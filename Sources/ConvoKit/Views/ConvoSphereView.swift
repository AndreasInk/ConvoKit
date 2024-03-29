//
//  ConvoSphereView.swift
//  ConvoKit
//
//  Created by Andreas Ink on 12/22/23.
//

import SwiftUI

public struct ConvoSphereView: View {
    
    public init(animate: Bool = false, thinking: Bool = false, audioStreamer: ConvoStreamer, shouldCenter: Bool = true, transcription: @escaping (String) -> Void) {
        self.animate = animate
        self.thinking = thinking
        self.audioStreamer = audioStreamer
        self.shouldCenter = shouldCenter
        self.transcription = transcription
    }
    
    @State var animate = false
    @State var thinking = false
    var audioStreamer: ConvoStreamer
    var shouldCenter = true
    var transcription: (String) -> Void
    public var body: some View {
        ZStack(alignment: shouldCenter ? .center : .bottomTrailing) {
            // fetching from cloud
          Circle()
                .foregroundStyle(.purple)
                .frame(width: 75, height: 75)
                .clipShape(Circle())
                .rotationEffect(thinking ? .degrees(225) : .degrees(0))
                .animation(.snappy, value: thinking)
            
                .opacity(animate ? 1 : 0.001)
                .blur(radius: animate ? 2 : 10)
                .scaleEffect(animate ? 1 : 0.95)
                .animation(.smooth.speed(0.25), value: animate)
            
                .scaleEffect(audioStreamer.state.scale)
                .animation(.bouncy, value: audioStreamer.state.scale)
            
                .background {
                    Circle()
                        .foregroundStyle(.purple)
                        .shadow(color: .purple.opacity(0.1), radius: 100)
                        .blur(radius: 50)
                        .task {
                            try? await Task.sleep(for: .seconds(2))
                            animate = true
                        }
                }
                .padding(.trailing)
        }
        .onTapGesture {
            Task {
                let result = try await audioStreamer.toggleRecord(isAsking: true, chatInput: .emptyChat)
                if let transcription = result?.transcription {
                    cleanTranscription(transcription)
                }
            }
        }
        .onChange(of: audioStreamer.state.result?.id) { newValue in
            if let result = audioStreamer.state.result {
                cleanTranscription(result.transcription)
            }
        }
    }
    func cleanTranscription(_ transcriptions: [AudioTranscription]) {
        transcription(transcriptions.map(\.text).joined().trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

