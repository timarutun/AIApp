//
//  ContentView.swift
//  AIApp
//
//  Created by Timur on 1/22/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    var body: some View {
        NavigationView {
            TabView {
                RecordingView()
                    .tabItem {
                        Label("Record", systemImage: "mic")
                    }

                NotesListView()
                    .tabItem {
                        Label("Notes", systemImage: "list.bullet")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        }
    }
}

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
        newRecording.fileURL = url.path // Save file path

        do {
            try viewContext.save()
        } catch {
            print("Error saving recording: \(error.localizedDescription)")
        }
    }
}

struct NotesListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recording.timestamp, ascending: false)],
        animation: .default)
    private var recordings: FetchedResults<Recording>

    var body: some View {
        List {
            ForEach(recordings) { recording in
                if let timestamp = recording.timestamp, let fileURL = recording.fileURL {
                    NavigationLink(destination: NoteDetailView(recording: recording)) {
                        VStack(alignment: .leading) {
                            Text("Recording \(timestamp, formatter: itemFormatter)")
                                .font(.headline)
                            Text(fileURL)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                } else {
                    Text("Invalid Recording")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Notes")
    }
}

struct NoteDetailView: View {
    var recording: Recording
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        VStack(spacing: 20) {
            Text("Recorded on \(recording.timestamp ?? Date(), formatter: itemFormatter)")
                .font(.headline)

            Button(action: playRecording) {
                Text("Play Recording")
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Note Detail")
    }

    private func playRecording() {
        guard let urlString = recording.fileURL else {
            print("Invalid file URL")
            return
        }
        let url = URL(fileURLWithPath: urlString)

        if FileManager.default.fileExists(atPath: url.path) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            } catch {
                print("Error playing recording: \(error.localizedDescription)")
            }
        } else {
            print("File does not exist at path: \(url.path)")
        }
        print("File path: \(url.path)")
    }
}

struct SettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Preferences")) {
                Toggle("Enable Notifications", isOn: .constant(true))
                Toggle("Dark Mode", isOn: .constant(false))
            }

            Section(header: Text("About")) {
                Text("Version 1.0")
            }
        }
        .navigationTitle("Settings")
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
