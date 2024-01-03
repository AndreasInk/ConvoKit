//
//  ConvoStreamer+AudioPlayerDelegate.swift
//
//
//  Created by Andreas Ink on 12/30/23.
//

import SwiftUI
import AudioStreaming

extension ConvoStreamer: AudioPlayerDelegate {
    public func audioPlayerDidStartPlaying(player: AudioStreaming.AudioPlayer, with entryId: AudioStreaming.AudioEntryId) {
        self.state.isListening = false
    }
    
    public func audioPlayerDidFinishBuffering(player: AudioStreaming.AudioPlayer, with entryId: AudioStreaming.AudioEntryId) {
        
    }
    
    public func audioPlayerStateChanged(player: AudioStreaming.AudioPlayer, with newState: AudioStreaming.AudioPlayerState, previous: AudioStreaming.AudioPlayerState) {
        if newState == .stopped, state.isRecording == false {
            Task {
                let _ = try await self.toggleRecord(isAsking: true, 
                                            chatInput: .emptyChat)
                self.state.isListening = true
            }
        }
    }
    
    public func audioPlayerDidFinishPlaying(player: AudioStreaming.AudioPlayer, entryId: AudioStreaming.AudioEntryId, stopReason: AudioStreaming.AudioPlayerStopReason, progress: Double, duration: Double) {
        
    }
    
    public func audioPlayerUnexpectedError(player: AudioStreaming.AudioPlayer, error: AudioStreaming.AudioPlayerError) {
        
    }
    
    public func audioPlayerDidCancel(player: AudioStreaming.AudioPlayer, queuedItems: [AudioStreaming.AudioEntryId]) {
        
    }
    
    public func audioPlayerDidReadMetadata(player: AudioStreaming.AudioPlayer, metadata: [String : String]) {
        
    }
    
    
}
