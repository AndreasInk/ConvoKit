//
//  ConvoStreamer.swift
//
//
//  Created by Andreas Ink on 12/25/23.
//

import Foundation
import AVFoundation
import AudioStreaming
import whisper

public class ConvoStreamer: NSObject, ObservableObject, URLSessionDataDelegate, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    struct State {
        var nonSpeechCount = 0
        var isListening = true
        var wasListening = false
        var scale: CGFloat = 1.0
        var isRecording = false
        var chat: [ChatMessage] = []
        var result: ConvoResult?
    }
    
    @Published var state = State()
    
    public var llmManager: ConvoLLMManager
    private let recorder = Recorder()
    private var player = AudioPlayer()
    private var timer: Timer?
    private var soundAnalyzer: SoundAnalyzer = .init()
    private var whisperContext: WhisperContext?
    
    let baseSpeakURL: String
    let baseThinkURL: String
    let localWhisperURL: URL
    public init(baseThinkURL: String, baseSpeakURL: String, localWhisperURL: URL ) {

        self.baseThinkURL = baseThinkURL
        self.baseSpeakURL = baseSpeakURL
        self.localWhisperURL = localWhisperURL
        self.llmManager = ConvoLLMManager(baseThinkURL: baseThinkURL)
    }
    deinit {
       
        timer?.invalidate()
    }
    
    let tmpURL = URL.documentsDirectory.appendingPathComponent("tmp", conformingTo: .audio)
    
    public func initWhisper() {
        DispatchQueue.global().async {
            do {
                self.whisperContext = try WhisperContext.createContext(path: self.localWhisperURL.path())
            } catch {
                print(error)
            }
        }
    }
    
    func toggleRecord(isAsking: Bool = false, chatInput: ChatInput) async throws -> ConvoResult? {
        
        self.player.delegate = self
        var result = ConvoResult(functionName: "", transcription: [], chatMessage: [])
        
        if await self.recorder.isRecording() {
            await self.recorder.stopRecording()
            Task { @MainActor in
                self.state.isRecording = false
                self.state.nonSpeechCount = 0
            }
            let floats = try AudioUtils.convertAudioFileToPCMArray(fileURL: tmpURL)
            
            await whisperContext?.fullTranscribe(samples: floats)
            let text = await whisperContext?.getTranscription() ?? ""

            print(text)
            try? FileManager.default.removeItem(at: tmpURL)
            
            if isAsking, !baseSpeakURL.isEmpty, !baseThinkURL.isEmpty {
                if text.count > 10 {
                    do {
                        let chatResponse = try await llmManager.submitNewChat(text, chatInput: chatInput)
                        self.state.chat = chatResponse
                        if let lastChat = chatResponse.last {
                            result.chatMessage = [lastChat]
                            self.startStreaming(lastChat.content)
                            
                        }
                    } catch {
                        print(error)
                    }
                } else {
                    return try await toggleRecord(isAsking: isAsking, chatInput: chatInput)
                }
            }
            await self.recorder.stopAudioEngine()
            result.transcription = [AudioTranscription(text: text, timestamp: 0, audioData: Data())]
            self.state.result = result
            return result
            
        } else {
            Task { @MainActor in
                state.nonSpeechCount = 0
            }
            return await startRecording(audioEngine: await recorder.audioEngine)
        }
    }
    
    func startRecording(audioEngine: AVAudioEngine?) async -> ConvoResult? {
        do {
            guard let audioEngine = await recorder.audioEngine else {
                return nil
            }
            try await self.recorder.startRecording(toOutputFile: tmpURL, delegate: self)
            Task { @MainActor in
                self.state.isRecording = true
            }
            Task {
                await self.getInputLoudness()
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) -> CGFloat {
        // Calculate the loudness from the buffer.
        var rms: Float = 0.0
        if let channelData = buffer.floatChannelData {
            for frame in 0..<Int(buffer.frameLength) {
                let sample = channelData.pointee[frame]
                rms += sample * sample
            }
            print(rms)
            rms = sqrt(rms / Float(buffer.frameLength))
            
            // Map the loudness to a scale factor.
            // Adjust the mapping as per your requirements.
            let newScale = CGFloat(1.0 + (rms * 1.65))
            DispatchQueue.main.async {
                self.state.scale = newScale
            }
            return newScale
        }
        return 1
    }
    
    func getOutputLoudness() async {
        player.streamOutputBuffer()
        var stream = player.bufferStream.makeAsyncIterator()
        var nextValue = await stream.next()
        while nextValue != nil {
            if let nextValue {
                let _ = processAudioBuffer(nextValue)
            }
            nextValue = await stream.next()
        }
    }
    
    func getInputLoudness() async {
        
        var stream = await recorder.bufferStream.makeAsyncIterator()
        var nextValue = await stream.next()
        guard let audioEngine = await recorder.audioEngine,
                let model = soundAnalyzer.setupForAnalysis(audioEngine: audioEngine) else {  return }
        do {
            try soundAnalyzer.soundAnalyzer?.add(model, withObserver: self)
            
        } catch {
            print("Failed to start sound analysis: \(error)")
        }
        while nextValue != nil {
            if let nextValue {
                // TODO: Fix speech analyzer
                self.soundAnalyzer.soundAnalyzer?.analyze(nextValue.buffer, atAudioFramePosition: nextValue.time.sampleTime)
                // If we need to analyze loudness too
                // processAudioBuffer(nextValue.buffer)
            }
            nextValue = await stream.next()
        }
        
    }
    
    func requestStream(_ text: String) async throws -> String {
        let request = URL(string: "\(baseSpeakURL)/chat?chat=\("")&descriptionOfScene=\("")&textInImage=\("")&directResponse=\(text)")!
        
        let urlSession = URLSession.shared
        let data = try await urlSession.data(from: request).0
        let audioResponse = try JSONDecoder().decode(AudioResponse.self, from: data)
        return audioResponse.fileID
    }
    
    
    func startStreaming(_ text: String) {
        Task {
            player.volume = 5
            do {
                let streamID = try await requestStream(text)
                
                player.play(url: URL(string: baseSpeakURL + "/audio/" + streamID + ".mp3")!)
                
                Task {
                    await getOutputLoudness()
                }
            } catch {
                print(error)
            }
        }
    }
}


struct AudioResponse: Codable {
    var fileID: String
}

