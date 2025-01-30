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

    var body: some View {
        List {
            ForEach(recordings) { recording in
                NavigationLink(destination: NoteDetailView(recording: recording)) {
                    VStack(alignment: .leading) {
                        Text("Recording \(recording.timestamp ?? Date(), formatter: itemFormatter)")
                            .font(.headline)
                        Text(recording.fileURL ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
            .onDelete(perform: deleteRecordings)
        }
        .navigationTitle("Notes")
    }

    private func deleteRecordings(at offsets: IndexSet) {
        for index in offsets {
            let recording = recordings[index]
            viewContext.delete(recording)
        }

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
        
        // Creating mock data for the preview
        let recording1 = Recording(context: context)
        recording1.id = UUID()
        recording1.timestamp = Date()
        recording1.fileURL = "/mock/path/recording1.m4a"
        
        let recording2 = Recording(context: context)
        recording2.id = UUID()
        recording2.timestamp = Date().addingTimeInterval(-60 * 60) // 1 hour ago
        recording2.fileURL = "/mock/path/recording2.m4a"
        
        do {
            try context.save() // Save mock data
        } catch {
            print("Error saving mock data: \(error.localizedDescription)")
        }
        
        return NotesListView()
            .environment(\.managedObjectContext, context)
    }
}
