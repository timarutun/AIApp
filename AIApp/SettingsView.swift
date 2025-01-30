//
//  SettingsView.swift
//  AIApp
//
//  Created by Timur on 1/29/25.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.largeTitle)
                .bold()

            Text("This is a placeholder for settings.")
                .font(.subheadline)
                .foregroundStyle(.gray)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}

