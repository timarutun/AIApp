//
//  RecordingView.swift
//  AIApp
//
//  Created by Timur on 1/29/25.
//

import SwiftUI
import AVFoundation

struct RecordingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    @State private var speechText: String = ""
    @State private var isAuthorized = false
    @StateObject private var speechManager = SpeechManager()
    @State private var selectedLanguage = "en-US"

    let languages = ["en-US": "🇺🇸", "ru-RU": "🇷🇺"]

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Press the button below to start recording your voice note.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding()

            Button(action: {
                isRecording ? stopRecording() : startRecording()
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(languages.keys.sorted(), id: \.self) { key in
                        Button(action: {
                            selectedLanguage = key
                        }) {
                            Text("\(languages[key] ?? "") \(key)")
                        }
                    }
                } label: {
                    Text(languages[selectedLanguage] ?? "🌍")
                        .font(.title3)
                }
            }
        }
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

            speechManager.startRecognition(language: selectedLanguage) { recognizedText in
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

#Preview {
    RecordingView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
