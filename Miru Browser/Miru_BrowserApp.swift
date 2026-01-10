//
//  Miru_BrowserApp.swift
//  Miru Browser
//
//  Created by Kevin Dutra on 12/2/25.
//

import SwiftUI

@main
struct Miru_BrowserApp: App {
  @State private var browserState = BrowserState()
  @State private var appSettings = AppSettings()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(browserState)
        .environment(appSettings)
        .onOpenURL { url in
          handleIncomingURL(url)
        }
    }
  }

  private func handleIncomingURL(_ url: URL) {
    switch url.scheme?.lowercased() {
    case "http", "https":
      // Direct web URL - load it directly (default browser mode)
      browserState.loadURL(url)

    case "miru":
      // Handle miru:// URL scheme
      // Format: miru://open?url=https://example.com
      if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
        let queryItems = components.queryItems,
        let urlParam = queryItems.first(where: { $0.name == "url" })?.value,
        let targetURL = URL(string: urlParam)
      {
        browserState.loadURL(targetURL)
      }

    default:
      // Unknown scheme - try to load anyway
      browserState.loadURL(url)
    }
  }
}
