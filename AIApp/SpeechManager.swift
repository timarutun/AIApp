//
//  SpeechManager.swift
//  AIApp
//
//  Created by Timur on 1/29/25.
//

import Foundation
import Speech

class SpeechManager: ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    func startRecognition(language: String = "en-US", onResult: @escaping (String) -> Void) {
        guard let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: language)), speechRecognizer.isAvailable else {
            print("Speech recognition is not available for language: \(language)")
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            let inputNode = audioEngine.inputNode
            let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            recognitionRequest.shouldReportPartialResults = true

            self.recognitionRequest = recognitionRequest
            self.recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                if let result = result {
                    let bestString = result.bestTranscription.formattedString
                    onResult(bestString)
                }
                if error != nil {
                    self.stopRecognition()
                }
            }

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                recognitionRequest.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print("Error starting speech recognition: \(error.localizedDescription)")
        }
    }

    func stopRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
    }
}
