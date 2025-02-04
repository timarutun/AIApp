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
    @State private var transcribedText: String = ""
    @State private var structuredText: String?
    @State private var isLoading = false
    @StateObject private var speechManager = SpeechManager()
    @AppStorage("selectedLanguage") private var selectedLanguage = "en-US"

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Press the button below to start recording your voice note.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding()

            Text("Language: \(selectedLanguage == "en-US" ? "English" : "Русский")")
                .font(.footnote)
                .foregroundColor(.secondary)

            if !transcribedText.isEmpty {
                Text(transcribedText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }

            if isLoading {
                ProgressView("Processing...")
                    .padding()
            } else if let structuredText = structuredText {
                Text(structuredText)
                    .font(.body)
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }

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

            Spacer()
        }
        .padding()
        .navigationTitle("Record")
    }

    private func startRecording() {
        requestMicrophonePermission {
            let audioFilename = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).m4a")
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            do {
                audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
                audioRecorder?.record()
                recordingURL = audioFilename
                isRecording = true
                transcribedText = ""
                structuredText = nil

                speechManager.startRecognition(language: selectedLanguage) { text in
                    DispatchQueue.main.async {
                        transcribedText = text
                    }
                }
            } catch {
                print("Error starting recording: \(error.localizedDescription)")
            }
        }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        speechManager.stopRecognition()

        if let recordingURL = recordingURL {
            saveRecording(url: recordingURL)
        }

        if !transcribedText.isEmpty {
            sendToOllama(text: transcribedText) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success(let structured):
                        structuredText = structured
                    case .failure(let error):
                        print("AI Processing Error: \(error.localizedDescription)")
                    }
                }
            }
            isLoading = true
        }
    }

    private func saveRecording(url: URL) {
        let newRecording = Recording(context: viewContext)
        newRecording.id = UUID()
        newRecording.timestamp = Date()
        newRecording.fileURL = url.path

        do {
            try viewContext.save()
        } catch {
            print("Error saving recording: \(error.localizedDescription)")
        }
    }

    private func requestMicrophonePermission(completion: @escaping () -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    completion()
                } else {
                    print("Microphone access denied")
                }
            }
        }
    }

    private func sendToOllama(text: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "http://localhost:11434/api/generate")!  // Ollama API локально
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "mistral",
            "prompt": text
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                    return
                }

                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let responseText = jsonResponse["response"] as? String {
                        completion(.success(responseText))
                    } else {
                        completion(.failure(NSError(domain: "Invalid Ollama response format", code: -1, userInfo: nil)))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        } catch {
            completion(.failure(error))
        }
    }
}

#Preview {
    RecordingView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
