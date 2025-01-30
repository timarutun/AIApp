//
//  NoteDetailView.swift
//  AIApp
//
//  Created by Timur on 1/29/25.
//

import SwiftUI
import AVFoundation

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
        guard let urlString = recording.fileURL, let url = URL(string: urlString) else {
            print("Invalid file URL")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing recording: \(error.localizedDescription)")
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()
