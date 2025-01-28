//
//  ContentView.swift
//  AIApp
//
//  Created by Timur on 1/22/25.
//

import SwiftUI

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
            .navigationTitle("")
        }
    }
}

struct RecordingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Press the button below to start recording your voice note.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding()

            Button(action: {
                // Action for recording
            }) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "mic.fill")
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
}

struct NotesListView: View {
    var body: some View {
        List {
            ForEach(0..<5) { index in
                NavigationLink(destination: NoteDetailView(noteText: "Summary for note #\(index + 1)")) {
                    VStack(alignment: .leading) {
                        Text("Note #\(index + 1)")
                            .font(.headline)
                        Text("Short summary of the note...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle("Notes")
    }
}

struct NoteDetailView: View {
    var noteText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(noteText)
                .font(.body)

            Spacer()
        }
        .padding()
        .navigationTitle("Note Detail")
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


#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
