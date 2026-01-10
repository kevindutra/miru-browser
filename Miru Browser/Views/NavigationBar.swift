//
//  NavigationBar.swift
//  Miru Browser
//
//  Created by Kevin Dutra on 12/2/25.
//

import SwiftUI

struct NavigationBar: View {
  @Environment(BrowserState.self) private var browserState
  @Environment(AppSettings.self) private var settings
  @State private var showShareSheet = false
  @State private var showSettings = false

  var isVertical: Bool = false

  var body: some View {
    glassPanel
      .sheet(isPresented: $showShareSheet) {
        if let url = browserState.currentURL {
          ShareSheet(items: shareItems(url: url))
            .presentationDetents([.medium, .large])
        }
      }
      .sheet(isPresented: $showSettings) {
        SettingsView(settings: settings)
      }
  }

  // MARK: - Floating Navigation Islands

  private var glassPanel: some View {
    ZStack {
      // Center: Compact back/forward pill
      navigationPill

      // Right: Floating menu button
      HStack {
        Spacer()
        floatingMenuButton
      }
    }
  }

  // MARK: - Navigation Pill

  private var navigationPill: some View {
    HStack(spacing: 8) {
      // Back button
      GlassNavButton(
        icon: "arrow.left",
        isDisabled: !browserState.canGoBack,
        accessibilityLabel: "Go back",
        accessibilityHint: "Navigate to the previous page"
      ) {
        browserState.goBack()
      }

      // Forward button
      GlassNavButton(
        icon: "arrow.right",
        isDisabled: !browserState.canGoForward,
        accessibilityLabel: "Go forward",
        accessibilityHint: "Navigate to the next page"
      ) {
        browserState.goForward()
      }
    }
    .padding(.horizontal, 12)
    .background {
      Capsule()
        .fill(Color.white.opacity(0.85))
        .glassEffect()
    }
    .contentShape(Capsule())
  }

  // MARK: - Floating Menu Button

  private var floatingMenuButton: some View {
    Menu {
      Button {
        showShareSheet = true
      } label: {
        Label("Share", systemImage: "square.and.arrow.up")
      }

      Button {
        showSettings = true
      } label: {
        Label("Settings", systemImage: "gearshape")
      }

      Button(role: .destructive) {
        browserState.close()
      } label: {
        Label("Close Site", systemImage: "xmark")
      }
    } label: {
      Image(systemName: "ellipsis")
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(
          browserState.currentURL == nil ? Color.gray.opacity(0.35) : Color.black.opacity(0.8)
        )
        .frame(width: 44, height: 44)
        .background {
          Circle()
            .fill(Color.white.opacity(0.85))
            .glassEffect()
        }
        .contentShape(Circle())
    }
    .disabled(browserState.currentURL == nil)
    .accessibilityLabel("More options")
    .accessibilityHint("Open menu with share, settings, and close options")
  }

  private func shareItems(url: URL) -> [Any] {
    var items: [Any] = [url]
    if !browserState.pageTitle.isEmpty {
      items.insert(browserState.pageTitle, at: 0)
    }
    return items
  }
}

// MARK: - Glass Navigation Button

struct GlassNavButton: View {
  let icon: String
  let isDisabled: Bool
  let accessibilityLabel: String
  let accessibilityHint: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: icon)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(isDisabled ? Color.gray.opacity(0.35) : Color.black.opacity(0.8))
        .frame(width: 44, height: 44)
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .disabled(isDisabled)
    .accessibilityLabel(accessibilityLabel)
    .accessibilityHint(accessibilityHint)
  }
}

#Preview {
  ZStack {
    // Sample background to show glass effect
    LinearGradient(
      colors: [.blue, .purple],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
    .ignoresSafeArea()

    VStack {
      Spacer()
      NavigationBar()
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
  }
  .environment(BrowserState())
  .environment(AppSettings())
}
