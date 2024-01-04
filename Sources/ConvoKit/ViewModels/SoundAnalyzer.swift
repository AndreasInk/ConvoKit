//
//  SoundAnalyzer.swift
//
//
//  Created by Andreas Ink on 12/30/23.
//

import AVFoundation
import SoundAnalysis


extension ConvoStreamer: SNResultsObserving {
    public func request(_ request: SNRequest, didProduce result: SNResult) {
        // Downcast the result to a classification result.
        guard let result = result as? SNClassificationResult else { return }

        // Get the most likely classification.
        guard let classification = result.classifications.filter({$0.identifier == "speech"}).first else {
            return 
        }
        guard self.state.isListening else { return }
        
        if classification.confidence > 0.4 {
            if self.state.wasListening {
                Task {
                    try await toggleRecord(isAsking: true, chatInput: .emptyChat)
                }
                self.state.wasListening = false
            }
        } else {
            if self.state.nonSpeechCount == 25, self.state.wasListening == false {
                Task {
                    let _ = try await toggleRecord(isAsking: true,
                                           chatInput: .emptyChat)
                    Task { @MainActor in
                        self.state.wasListening = true
                    }
                }
                Task { @MainActor in
                    self.state.nonSpeechCount = 0
                }
            }
            Task { @MainActor in
                self.state.nonSpeechCount += 1
            }
        }

        // Print the classification's name (label) and confidence.
        print("Classification: \(classification.identifier), Confidence: \(classification.confidence)")
    }

    public func request(_ request: SNRequest, didFailWithError error: Error) {
        print("The request failed with error: \(error)")
    }

    public func requestDidComplete(_ request: SNRequest) {
        print("The request completed successfully!")
    }
}

public class SoundAnalyzer {
    var soundAnalyzer: SNAudioStreamAnalyzer?
    private let analysisQueue = DispatchQueue(label: "com.example.AnalysisQueue")
    
    func setupForAnalysis(audioEngine: AVAudioEngine) -> SNClassifySoundRequest? {
        let inputNode = audioEngine.inputNode
        
        let busIndex = AVAudioNodeBus(0)
        let bufferSize = AVAudioFrameCount(4096)
        let audioFormat = inputNode.outputFormat(forBus: busIndex)
        
        soundAnalyzer = SNAudioStreamAnalyzer(format: audioFormat)

        // Configure the sound classification request
        guard let request = try? SNClassifySoundRequest(classifierIdentifier: .version1) else {
            print("Unable to load model")
            return nil
        }
        request.windowDuration = CMTimeMakeWithSeconds(1.5, preferredTimescale: 48_000)
        request.overlapFactor = 0.9
        return request
    }
}
