//
//  SettingsView.swift
//  AIApp
//
//  Created by Timur on 1/29/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedLanguage") private var selectedLanguage = "en-US"
    @AppStorage("isDarkMode") private var isDarkMode = false

    let languages = ["en-US": "English", "ru-RU": "Русский"]

    var body: some View {
        Form {
            Section(header: Text("Language")) {
                NavigationLink(destination: LanguageSelectionView(selectedLanguage: $selectedLanguage)) {
                    HStack {
                        Text("App Language")
                        Spacer()
                        Text(languages[selectedLanguage] ?? selectedLanguage)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Appearance")) {
                Toggle("Dark Mode", isOn: $isDarkMode)
            }
        }
        .navigationTitle("Settings")
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

// Language selection screen
struct LanguageSelectionView: View {
    @Binding var selectedLanguage: String
    let languages = ["en-US": "English", "ru-RU": "Русский"]

    var body: some View {
        List {
            ForEach(languages.keys.sorted(), id: \.self) { key in
                HStack {
                    Text(languages[key] ?? key)
                    Spacer()
                    if key == selectedLanguage {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedLanguage = key
                }
            }
        }
        .navigationTitle("Language")
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
