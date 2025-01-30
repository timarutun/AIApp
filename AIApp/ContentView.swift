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
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


