//
//  ConvoView.swift
//
//
//  Created by Andreas Ink on 1/1/24.
//

import SwiftUI
import AVFAudio

struct ConvoView: View {
    
    @State var synthesizer = AVSpeechSynthesizer()
    @State var allVoices = AVSpeechSynthesisVoice.speechVoices()
    
    var body: some View {
        Circle()
            .foregroundStyle(.white)
            .scaleEffect()
        
    }
    
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = allVoices.filter({$0.language == "en-US" && $0.quality == .enhanced}).last ?? AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
        synthesizer.write(utterance) { buffer in
            
        }
    }
}

#Preview {
    ConvoView()
}
