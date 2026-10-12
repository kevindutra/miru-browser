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
  @State private var check: CheckState = .idle
  @State private var confirmingURL: URL?

  enum CheckState: Equatable {
    case idle
    case checking
    case loaded(URL)
    case failed(String)
  }

  var body: some View {
    NavigationStack {
      Form {
        if let bookmark = settings.lockedBookmarkURL {
          lockedSection(bookmark)
        } else {
          pickerSection
        }
        staySignedInSection
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
      .alert(
        "Set Bookmark Permanently?",
        isPresented: Binding(
          get: { confirmingURL != nil },
          set: { if !$0 { confirmingURL = nil } }
        ),
        presenting: confirmingURL
      ) { url in
        Button("Set Bookmark") {
          settings.setBookmark(url)
        }
        Button("Cancel", role: .cancel) {}
      } message: { url in
        Text("\(url.absoluteString) will be your bookmark forever. You can't change it later.")
      }
    }
  }

  private func lockedSection(_ bookmark: URL) -> some View {
    Section {
      Label {
        Text(bookmark.absoluteString)
          .textSelection(.enabled)
      } icon: {
        Image(systemName: "lock.fill")
      }
    } header: {
      Text("Bookmark")
    } footer: {
      Text("Your bookmark is set for good. Tap the globe on the home screen to open it.")
    }
  }

  private var staySignedInSection: some View {
    Section {
      Toggle("Stay Signed In", isOn: $settings.staySignedIn)
    } header: {
      Text("Privacy")
    } footer: {
      Text(
        settings.staySignedIn
          ? "Cookies and site data are kept on this device, so you stay logged in to sites. Turn this off to erase them."
          : "Miru forgets cookies and site data when you close a page. Turn this on to stay logged in to sites."
      )
    }
  }

  private var pickerSection: some View {
    Section {
      TextField("example.com", text: $urlText)
        .textContentType(.URL)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .keyboardType(.URL)
        .submitLabel(.go)
        .onSubmit { Task { await runCheck() } }
        .onAppear {
          if urlText.isEmpty {
            urlText = settings.bookmarkURL.absoluteString
          }
        }
        .onChange(of: urlText) { check = .idle }

      switch check {
      case .idle:
        Button("Check Site") {
          Task { await runCheck() }
        }
        .disabled(urlText.trimmingCharacters(in: .whitespaces).isEmpty)
      case .checking:
        HStack {
          ProgressView()
          Text("Checking…")
            .foregroundStyle(.secondary)
        }
      case .loaded(let url):
        Label("Site loads", systemImage: "checkmark.circle.fill")
          .foregroundStyle(.green)
        Button("Set as Bookmark…") {
          confirmingURL = url
        }
      case .failed(let message):
        Label(message, systemImage: "exclamationmark.triangle.fill")
          .foregroundStyle(.orange)
        Button("Try Again") {
          Task { await runCheck() }
        }
      }
    } header: {
      Text("Bookmark")
    } footer: {
      Text("The globe on the home screen opens Wikipedia until you choose your own site. You can keep Wikipedia or enter any address. Choose carefully: once it's set, you can't change it.")
    }
  }

  private func runCheck() async {
    guard let url = Self.normalizedURL(from: urlText) else {
      check = .failed("That doesn't look like a web address.")
      return
    }
    check = .checking
    let result = await Self.verifyLoads(url)
    // Ignore a stale result if the text changed while checking.
    guard Self.normalizedURL(from: urlText) == url else { return }
    check = result
  }

  /// Prepends https:// when the entered URL has no scheme, and rejects
  /// anything that isn't an http(s) URL with a host.
  static func normalizedURL(from text: String) -> URL? {
    var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    if !trimmed.contains("://") {
      trimmed = "https://" + trimmed
    }
    guard let url = URL(string: trimmed),
          let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
          let host = url.host(), host.contains(".") else {
      return nil
    }
    return url
  }

  /// Fetches the URL and reports whether it answered with a successful response.
  static func verifyLoads(_ url: URL) async -> CheckState {
    var request = URLRequest(url: url, timeoutInterval: 10)
    // Some sites refuse requests that don't look like they come from a browser.
    request.setValue(
      "Mozilla/5.0 (iPhone; CPU iPhone OS 26_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
      forHTTPHeaderField: "User-Agent"
    )
    do {
      let (_, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else {
        return .failed("The site didn't respond.")
      }
      // 401/403/429 usually mean bot protection turned away this check;
      // the site itself still loads fine in the browser.
      let blockedButReachable: Set = [401, 403, 429]
      guard (200..<400).contains(http.statusCode) || blockedButReachable.contains(http.statusCode) else {
        return .failed("The site responded with an error (\(http.statusCode)).")
      }
      return .loaded(url)
    } catch {
      return .failed("Couldn't load the site. Check the address and your connection.")
    }
  }
}

#Preview {
  SettingsView(settings: AppSettings())
}
