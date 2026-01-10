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
                settings.defaultSiteURL = newValue
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
}

#Preview {
  SettingsView(settings: AppSettings())
}

