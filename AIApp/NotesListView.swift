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
        }
        .navigationTitle("Notes")
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

