import Foundation
import AVFoundation

actor Recorder {
    private var recorder: AVAudioRecorder?
    var audioEngine: AVAudioEngine? = AVAudioEngine()
    var bufferStream: AsyncStream<BufferWithTime>!
    
    
    func isRecording() -> Bool {
        if let recorder {
            return recorder.isRecording
        } else {
            return false
        }
    }
    enum RecorderError: Error {
        case couldNotStartRecording
    }
    
    func startRecording(toOutputFile url: URL, delegate: AVAudioRecorderDelegate?) throws {
        let recordSettings: [String : Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
#if !os(macOS)
        AVAudioApplication.requestRecordPermission { _ in
            
        }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
#endif
        let recorder = try AVAudioRecorder(url: url, settings: recordSettings)
        recorder.delegate = delegate
        if recorder.record() == false {
            print("Could not start recording")
            throw RecorderError.couldNotStartRecording
        }
        self.recorder = recorder
        
        streamMicInput()
        
    }
    
    func stopAudioEngine() {
        
    }
    
    func stopRecording() {
        bufferStream = nil
        audioEngine?.stop()
        
        let busIndex = AVAudioNodeBus(0)
        audioEngine?.inputNode.removeTap(onBus: busIndex)
        recorder?.stop()
        recorder = nil
    }
    
    private func streamMicInput() {
        guard let audioEngine = audioEngine else { return }
        let inputNode = audioEngine.inputNode
        
        guard bufferStream == nil else {
            return
        }
        let busIndex = AVAudioNodeBus(0)
        let bufferSize = AVAudioFrameCount(4096)
        let audioFormat = audioEngine.inputNode.outputFormat(forBus: busIndex)
        bufferStream = AsyncStream<BufferWithTime> { continuation in
            inputNode.installTap(onBus: busIndex, bufferSize: bufferSize, format: audioFormat) { (buffer, time) in
                // Yield the buffer to the stream.
                continuation.yield(BufferWithTime(buffer: buffer, time: time))
            }
            
            // Handle cancellation.
            continuation.onTermination = { @Sendable _ in
                inputNode.removeTap(onBus: 0)
            }
        }
        
        // Start the audio engine.
        do {
            try audioEngine.start()
        } catch {
            print("Could not start audio engine: \(error)")
        }
    }
}

struct BufferWithTime {
    var buffer: AVAudioPCMBuffer
    var time: AVAudioTime
}
