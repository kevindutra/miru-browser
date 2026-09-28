//
//  ContentView.swift
//  Miru Browser
//
//  Created by Kevin Dutra on 12/2/25.
//

import SwiftUI

struct ContentView: View {
  @Environment(BrowserState.self) private var browserState
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @StateObject private var adBlocker = AdBlocker()
  @State private var deviceOrientation = UIDevice.current.orientation

  private var isLandscape: Bool {
    verticalSizeClass == .compact
  }

  var body: some View {
    ZStack {
      // Background color for entire screen
      Color(UIColor.systemBackground)
        .ignoresSafeArea()

      if browserState.currentURL != nil {
        // Browser view with swipe-to-close
        if isLandscape {
          landscapeBrowserView
        } else {
          portraitBrowserView
        }
      } else {
        // Zen empty state with fade-in transition
        EmptyStateView()
          .transition(.opacity)
      }
    }
    .animation(.easeIn(duration: 0.3), value: browserState.currentURL == nil)
    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification))
    { _ in
      deviceOrientation = UIDevice.current.orientation
    }
    .task {
      // Check for filter updates on launch
      let updateService = FilterUpdateService()
      if await updateService.checkForUpdates() {
        await adBlocker.refreshRules()
      }
    }
  }

  // MARK: - Portrait Layout

  private var portraitBrowserView: some View {
    ZStack(alignment: .bottom) {
      // Theme color fill behind Dynamic Island
      statusBarFill

      // Web content respects safe area for sticky headers
      WebView(adBlocker: adBlocker)
        .ignoresSafeArea(edges: [.horizontal, .bottom])

      // Floating navigation bar with loading indicator
      VStack(spacing: 0) {
        // Loading progress bar above nav
        if browserState.isLoading {
          GlassProgressBar(progress: browserState.loadingProgress)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }

        // Liquid glass navigation panel
        NavigationBar(isVertical: false)
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 8)
      .offset(y: browserState.isNavBarVisible ? 0 : 100)
      .opacity(browserState.isNavBarVisible ? 1 : 0)
      .animation(.spring(response: 0.35, dampingFraction: 0.8), value: browserState.isNavBarVisible)
    }
    .ignoresSafeArea(.keyboard)
    .swipeToClose {
      browserState.close()
    }
  }

  // MARK: - Landscape Layout

  /// Determine if Dynamic Island is on the left based on device orientation
  /// - landscapeLeft: device rotated left (home/USB-C on left) → island on LEFT
  /// - landscapeRight: device rotated right (home/USB-C on right) → island on RIGHT
  private var islandOnLeft: Bool {
    deviceOrientation == .landscapeLeft
  }

  private var landscapeBrowserView: some View {
    GeometryReader { geometry in
      let windowInsets = Self.getWindowSafeAreaInsets()
      let leftInset = windowInsets.left
      let rightInset = windowInsets.right

      ZStack(alignment: .bottom) {
        // Black fill behind Dynamic Island (detected side)
        landscapeDynamicIslandFill(
          islandOnLeft: islandOnLeft, leftInset: leftInset, rightInset: rightInset)

        // Web content - extend to edge on the non-island side, rounded on island side
        WebView(adBlocker: adBlocker)
          .clipShape(
            UnevenRoundedRectangle(
              topLeadingRadius: islandOnLeft ? 20 : 0,
              bottomLeadingRadius: islandOnLeft ? 20 : 0,
              bottomTrailingRadius: islandOnLeft ? 0 : 20,
              topTrailingRadius: islandOnLeft ? 0 : 20
            )
          )
          .ignoresSafeArea(edges: islandOnLeft ? [.trailing, .bottom] : [.leading, .bottom])

        // Floating navigation bar with loading indicator
        VStack(spacing: 0) {
          // Loading progress bar above nav
          if browserState.isLoading {
            GlassProgressBar(progress: browserState.loadingProgress)
              .padding(.horizontal, 24)
              .padding(.bottom, 8)
          }

          // Liquid glass navigation panel (compact for landscape)
          NavigationBar(isVertical: false)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        // Add extra padding on the island side to center nav within safe area
        .padding(islandOnLeft ? .leading : .trailing, dynamicIslandEdgeWidth)
        .offset(y: browserState.isNavBarVisible ? 0 : 100)
        .opacity(browserState.isNavBarVisible ? 1 : 0)
        .animation(
          .spring(response: 0.35, dampingFraction: 0.8), value: browserState.isNavBarVisible)
      }
      // Force re-render when orientation changes
      .id(deviceOrientation.rawValue)
    }
    .ignoresSafeArea(.keyboard)
    .swipeToClose {
      browserState.close()
    }
  }

  /// Get window safe area insets directly from UIKit
  private static func getWindowSafeAreaInsets() -> UIEdgeInsets {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let window = windowScene.windows.first
    else {
      return .zero
    }
    return window.safeAreaInsets
  }

  // MARK: - Status Bar Theme Fill

  /// Fills the top safe area (behind Dynamic Island) with the webpage's theme color
  private var statusBarFill: some View {
    GeometryReader { geometry in
      (browserState.themeColor ?? Color(UIColor.systemBackground))
        .frame(height: geometry.safeAreaInsets.top)
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(edges: .top)
    }
    .animation(.easeInOut(duration: 0.3), value: browserState.themeColor)
  }

  // Dynamic Island width is approximately 126pt, but we only need to cover
  // the curved edge area which is about 59pt from the screen edge
  private let dynamicIslandEdgeWidth: CGFloat = 59

  /// Fills the side safe area (behind Dynamic Island in landscape) with black
  @ViewBuilder
  private func landscapeDynamicIslandFill(
    islandOnLeft: Bool, leftInset: CGFloat, rightInset: CGFloat
  ) -> some View {
    if islandOnLeft {
      // Dynamic Island is on the left side
      HStack(spacing: 0) {
        Color.black
          .frame(width: dynamicIslandEdgeWidth)
          .frame(maxHeight: .infinity)
          .ignoresSafeArea(edges: .leading)
        Spacer()
      }
    } else {
      // Dynamic Island is on the right side
      HStack(spacing: 0) {
        Spacer()
        Color.black
          .frame(width: dynamicIslandEdgeWidth)
          .frame(maxHeight: .infinity)
          .ignoresSafeArea(edges: .trailing)
      }
    }
  }
}

// MARK: - Glass Progress Bar

struct GlassProgressBar: View {
  let progress: Double

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        // Background track
        Capsule()
          .fill(.ultraThinMaterial)
          .frame(height: 6)

        // Progress fill with glow
        Capsule()
          .fill(
            LinearGradient(
              colors: [.blue, .cyan],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .frame(width: max(0, geometry.size.width * progress), height: 6)
          .shadow(color: .cyan.opacity(0.6), radius: 8, x: 0, y: 0)
      }
    }
    .frame(height: 6)
    .glassEffect()
    .clipShape(Capsule())
    .animation(.easeInOut(duration: 0.2), value: progress)
  }
}

// MARK: - Empty State View (Zen Space)

struct EmptyStateView: View {
  @Environment(BrowserState.self) private var browserState
  @Environment(AppSettings.self) private var settings
  @State private var showSettings = false

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Night sky background (matches mirubrowser.com) - constrained to screen bounds
        NightSkyView()
          .frame(width: geometry.size.width, height: geometry.size.height)

        // Centered Logo
        Image("Logo")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 120, height: 120)

        // Bottom toolbar with buttons at corners
        VStack {
          Spacer()
          HStack {
            // Default site button (bottom left)
            if settings.showDefaultSiteButton {
              Button {
                if let url = URL(string: settings.defaultSiteURL) {
                  browserState.loadURL(url)
                }
              } label: {
                Image(systemName: "globe")
                  .font(.system(size: 20, weight: .medium))
                  .foregroundStyle(.white.opacity(0.9))
                  .frame(width: 44, height: 44)
                  .background(.ultraThinMaterial.opacity(0.5))
                  .clipShape(Circle())
              }
              .buttonStyle(.plain)
              .accessibilityLabel("Open default site")
              .accessibilityHint("Opens \(settings.defaultSiteURL)")
            }

            Spacer()

            // Settings gear (bottom right)
            Button {
              showSettings = true
            } label: {
              Image(systemName: "gearshape")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial.opacity(0.5))
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
          }
          .padding(.horizontal, 24)
          .padding(.bottom, 32)
        }
      }
    }
    .ignoresSafeArea()
    // Light status bar over the dark sky
    .preferredColorScheme(.dark)
    .sheet(isPresented: $showSettings) {
      SettingsView(settings: settings)
    }
  }
}

// MARK: - Space Gradient View

struct SpaceGradientView: View {
  var body: some View {
    TimelineView(.animation) { timeline in
      SpaceGradientCanvas(time: timeline.date.timeIntervalSinceReferenceDate)
    }
    .ignoresSafeArea()
  }
}

struct SpaceGradientCanvas: View {
  let time: Double

  private var phase1: Float { Float(sin(time * 0.3) * 0.15) }
  private var phase2: Float { Float(cos(time * 0.25) * 0.12) }
  private var phase3: Float { Float(sin(time * 0.35 + 1) * 0.1) }

  private let colors: [Color] = [
    // Top row - deep black space
    Color(red: 0.0, green: 0.0, blue: 0.02),
    Color(red: 0.02, green: 0.0, blue: 0.05),
    Color(red: 0.0, green: 0.0, blue: 0.03),
    // Upper middle - vibrant nebula
    Color(red: 0.15, green: 0.0, blue: 0.3),
    Color(red: 0.4, green: 0.1, blue: 0.6),
    Color(red: 0.2, green: 0.0, blue: 0.35),
    // Lower middle - bright accent
    Color(red: 0.5, green: 0.15, blue: 0.5),
    Color(red: 0.6, green: 0.2, blue: 0.45),
    Color(red: 0.35, green: 0.1, blue: 0.45),
    // Bottom row - fade to dark
    Color(red: 0.05, green: 0.0, blue: 0.1),
    Color(red: 0.08, green: 0.02, blue: 0.15),
    Color(red: 0.03, green: 0.0, blue: 0.08),
  ]

  var body: some View {
    MeshGradient(
      width: 3,
      height: 4,
      points: [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 0.35), SIMD2<Float>(0.5 + phase1, 0.3 + phase2 * 0.5),
        SIMD2<Float>(1.0, 0.35),
        SIMD2<Float>(0.0, 0.65), SIMD2<Float>(0.5 - phase2, 0.7 + phase3 * 0.5),
        SIMD2<Float>(1.0, 0.65),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0),
      ],
      colors: colors
    )
  }
}

#Preview("Empty State") {
  ContentView()
    .environment(BrowserState())
    .environment(AppSettings())
}

#Preview("With URL") {
  let state = BrowserState()
  state.currentURL = URL(string: "https://example.com")
  return ContentView()
    .environment(state)
    .environment(AppSettings())
}
