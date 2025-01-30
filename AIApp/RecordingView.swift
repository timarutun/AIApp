//
//  RecordingView.swift
//  AIApp
//
//  Created by Timur on 1/29/25.
//

import SwiftUI
import AVFoundation
import Speech

struct RecordingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    @State private var speechText: String = ""
    @State private var isAuthorized = false
    @StateObject private var speechManager = SpeechManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Press the button below to start recording your voice note.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding()

            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                Circle()
                    .fill(isRecording ? Color.gray : Color.red)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .foregroundColor(.white)
                            .font(.largeTitle)
                    )
            }
            .shadow(radius: 10)

            if !speechText.isEmpty {
                Text("Transcription:")
                    .font(.headline)
                Text(speechText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Save") {
                    saveRecording()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Record")
        .onAppear {
            speechManager.requestSpeechRecognitionPermission { authorized in
                isAuthorized = authorized
            }
        }
    }

    private func startRecording() {
        guard isAuthorized else { return }

        let audioFilename = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            recordingURL = audioFilename
            isRecording = true

            speechManager.startRecognition { recognizedText in
                DispatchQueue.main.async {
                    speechText = recognizedText
                }
            }
        } catch {
            print("Error starting recording: \(error.localizedDescription)")
        }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        speechManager.stopRecognition()
    }

    private func saveRecording() {
        guard let recordingURL = recordingURL else { return }
        
        let newRecording = Recording(context: viewContext)
        newRecording.id = UUID()
        newRecording.timestamp = Date()
        newRecording.fileURL = recordingURL.absoluteString
        newRecording.transcription = speechText

        do {
            try viewContext.save()
            speechText = "" // Clear transcription after saving
        } catch {
            print("Error saving recording: \(error.localizedDescription)")
        }
    }
}

class SpeechManager: ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func requestSpeechRecognitionPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }

    func startRecognition(completion: @escaping (String) -> Void) {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else { return }

        audioEngine = AVAudioEngine()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let audioEngine = audioEngine, let recognitionRequest = recognitionRequest else { return }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    completion(result.bestTranscription.formattedString)
                }
            }
            if error != nil {
                self.stopRecognition()
            }
        }
    }

    func stopRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
    }
}

#Preview {
    RecordingView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
