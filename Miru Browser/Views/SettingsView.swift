//
//  SettingsView.swift
//  Miru Browser
//
//  Created by Kevin Dutra on 12/5/25.
//

import SwiftUI

struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable var settings: AppSettings

  @State private var urlText: String = ""

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Toggle("Show Default Site Button", isOn: $settings.showDefaultSiteButton)
        } header: {
          Text("Home Button")
        } footer: {
          Text("Display a button on the home screen to quickly visit your default site.")
        }

        if settings.showDefaultSiteButton {
          Section {
            TextField("URL", text: $urlText)
              .textContentType(.URL)
              .autocapitalization(.none)
              .autocorrectionDisabled()
              .keyboardType(.URL)
              .onAppear {
                urlText = settings.defaultSiteURL
              }
              .onChange(of: urlText) { _, newValue in
                settings.defaultSiteURL = Self.normalizedURL(from: newValue)
              }
          } header: {
            Text("Default Site URL")
          } footer: {
            Text("Enter the URL you want to visit when tapping the home button.")
          }
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }

  /// Prepends https:// when the entered URL has no scheme, so the
  /// home button never silently fails on input like "example.com".
  static func normalizedURL(from text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !trimmed.contains("://") else { return trimmed }
    return "https://" + trimmed
  }
}

#Preview {
  SettingsView(settings: AppSettings())
}
