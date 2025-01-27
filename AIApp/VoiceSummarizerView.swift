//
//  ContentView.swift
//  AIApp
//
//  Created by Timur on 1/22/25.
//

import SwiftUI
import AVFoundation

struct VoiceSummarizerView: View {
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioURL: URL?
    @State private var notes: [(audio: URL, summary: String)] = []

    var body: some View {
        VStack {
            Button(action: {
                isRecording ? stopRecording() : startRecording()
            }) {
                Text(isRecording ? "Stop" : "Start recording")
                    .font(.headline)
                    .padding()
                    .background(isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()

            List(notes, id: \.audio) { note in
                VStack(alignment: .leading) {
                    Text(note.summary)
                        .font(.body)
                    Button("Play") {
                        playAudio(note.audio)
                    }
                }
            }
        }
        .navigationTitle("Voice notes")
    }

    func startRecording() {
        let audioFilename = FileManager.default.temporaryDirectory.appendingPathComponent("recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("Recording error: \(error)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        audioURL = audioRecorder?.url
        isRecording = false

        // Mock audio and text
        if let audioURL = audioURL {
            let summary = "Это пример конспекта для аудио \(audioURL.lastPathComponent)."
            notes.append((audio: audioURL, summary: summary))
        }
    }

    func playAudio(_ url: URL) {
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }
}


#Preview {
    VoiceSummarizerView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
