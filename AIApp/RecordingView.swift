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

            Spacer()
        }
        .padding()
        .navigationTitle("Record")
    }

    private func startRecording() {
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
        } catch {
            print("Error starting recording: \(error.localizedDescription)")
        }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false

        if let recordingURL = recordingURL {
            saveRecording(url: recordingURL)
        }
    }

    private func saveRecording(url: URL) {
        let newRecording = Recording(context: viewContext)
        newRecording.id = UUID()
        newRecording.timestamp = Date()
        newRecording.fileURL = url.absoluteString // Convert URL to String

        do {
            try viewContext.save()
        } catch {
            print("Error saving recording: \(error.localizedDescription)")
        }
    }
}

