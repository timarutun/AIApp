//
//  NotesListView.swift
//  AIApp
//
//  Created by Timur on 1/29/25.
//

import SwiftUI
import CoreData

struct NotesListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recording.timestamp, ascending: false)],
        animation: .default)
    private var recordings: FetchedResults<Recording>
    
    @State private var showingDeleteAlert = false
    @State private var recordingToDelete: Recording?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(recordings) { recording in
                        NavigationLink(destination: NoteDetailView(recording: recording)) {
                            VStack {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Recording on \(recording.timestamp ?? Date(), formatter: itemFormatter)")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        HStack {
                                            Text(recording.fileURL ?? "No File")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                            Spacer()
                                        }
                                    }
                                    
                                    Spacer()

                                    // Delete Button
                                    Button(action: {
                                        recordingToDelete = recording
                                        showingDeleteAlert = true
                                    }) {
                                        Image(systemName: "trash.fill")
                                            .foregroundColor(.red)
                                            .padding(10)
                                    }
                                }
                                .padding(15)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                            }
                        }
                        .contextMenu {
                            Button(action: {
                                recordingToDelete = recording
                                showingDeleteAlert = true
                            }) {
                                Text("Delete Recording")
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
                .padding(.top, 10)
            }
            .navigationTitle("Notes")
            .background(Color(UIColor.systemGroupedBackground))
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Delete Recording"),
                    message: Text("Are you sure you want to delete this recording? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        if let recordingToDelete = recordingToDelete {
                            deleteRecording(recordingToDelete)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func deleteRecording(_ recording: Recording) {
        viewContext.delete(recording)
        do {
            try viewContext.save()
        } catch {
            print("Error deleting recording: \(error.localizedDescription)")
        }
    }
}


private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()


// Preview with mock data
struct NotesListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        let recording1 = Recording(context: context)
        recording1.id = UUID()
        recording1.timestamp = Date()
        recording1.fileURL = "/mock/path/recording1.m4a"
        
        let recording2 = Recording(context: context)
        recording2.id = UUID()
        recording2.timestamp = Date().addingTimeInterval(-60 * 60) // 1 hour ago
        recording2.fileURL = "/mock/path/recording2.m4a"
        
        do {
            try context.save()
        } catch {
            print("Error saving mock data: \(error.localizedDescription)")
        }
        
        return NotesListView()
            .environment(\.managedObjectContext, context)
    }
}
