//
//  NightSkyView.swift
//  Miru Browser
//
//  Empty-state background matching mirubrowser.com: a slate gradient, twinkling
//  stars (the real sky over NYC right now), and a slowly drifting blurred nebula.
//

import SwiftUI

struct NightSkyView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var startDate = Date()
  @State private var sky = SkyCache()

  var body: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
      let time = timeline.date.timeIntervalSince(startDate)
      ZStack {
        LinearGradient(
          colors: [Self.slate950, Self.slate900, Self.zinc800],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )

        Canvas { context, size in
          drawStars(in: &context, size: size, date: timeline.date, time: time)
        }

        Canvas { context, size in
          drawNebula(in: &context, size: size, time: time)
        }
        .blur(radius: 56)
      }
    }
    .accessibilityHidden(true)
  }

  // MARK: - Stars

  private func drawStars(in context: inout GraphicsContext, size: CGSize, date: Date, time: Double) {
    for star in sky.stars(at: date, size: size) {
      let seed = Double(star.seed)
      let twinkleSpeed = 0.3 + Self.random(seed, 1) * 1.2
      let twinkle = sin(time * twinkleSpeed + Self.random(seed, 2) * .pi * 2) * 0.3 + 0.7

      // Brighter stars are larger and more opaque (V ranges from -1.5 to 5.5)
      let dimness = min(max((star.magnitude + 1.5) / 7, 0), 1)
      let radius = 2.2 - dimness * 1.7
      let opacity = (0.95 - dimness * 0.8) * twinkle

      let rect = CGRect(x: star.x - radius, y: star.y - radius, width: radius * 2, height: radius * 2)
      context.fill(Path(ellipseIn: rect), with: .color(Self.starColor(star.colorIndex).opacity(opacity)))
    }
  }

  /// Near-white, tinted slightly blue for hot stars and amber for cool ones.
  private static func starColor(_ colorIndex: Double) -> Color {
    let warmth = min(max(colorIndex / 1.6, -0.25), 1)
    if warmth < 0 {
      return Color(red: 1 + warmth * 0.5, green: 1 + warmth * 0.25, blue: 1)
    }
    return Color(red: 1, green: 1 - warmth * 0.12, blue: 1 - warmth * 0.3)
  }

  // MARK: - Nebula

  private static let nebulaColors: [Color] = [
    Color(red: 120 / 255, green: 40 / 255, blue: 180 / 255),  // Purple
    Color(red: 180 / 255, green: 50 / 255, blue: 120 / 255),  // Magenta
    Color(red: 60 / 255, green: 80 / 255, blue: 200 / 255),  // Blue
    Color(red: 200 / 255, green: 80 / 255, blue: 60 / 255),  // Orange/coral
    Color(red: 100 / 255, green: 60 / 255, blue: 160 / 255),  // Deep violet
    Color(red: 160 / 255, green: 40 / 255, blue: 90 / 255),  // Rose
  ]

  private func drawNebula(in context: inout GraphicsContext, size: CGSize, time: Double) {
    let center = CGPoint(x: size.width * 0.65, y: size.height * 0.5)
    let baseRadius = min(size.width, size.height) * 0.4

    for (index, color) in Self.nebulaColors.enumerated() {
      let seed = Double(index) + 1000
      let angle = Double(index) / Double(Self.nebulaColors.count) * .pi * 2
      let radius = baseRadius * (0.5 + Self.random(seed, 1) * 0.3)

      let x = center.x + cos(angle) * baseRadius * 0.3
        + sin(time * (0.15 + Self.random(seed, 2) * 0.1) + Self.random(seed, 3) * .pi * 2)
        * (30 + Self.random(seed, 4) * 40)
      let y = center.y + sin(angle) * baseRadius * 0.3
        + cos(time * (0.12 + Self.random(seed, 5) * 0.1) + Self.random(seed, 6) * .pi * 2)
        * (25 + Self.random(seed, 7) * 35)

      let gradient = Gradient(stops: [
        .init(color: color.opacity(0.45), location: 0),
        .init(color: color.opacity(0.3), location: 0.3),
        .init(color: color.opacity(0.15), location: 0.6),
        .init(color: color.opacity(0), location: 1),
      ])
      let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
      context.fill(
        Path(ellipseIn: rect),
        with: .radialGradient(gradient, center: CGPoint(x: x, y: y), startRadius: 0, endRadius: radius))
    }
  }

  // MARK: - Helpers

  // Tailwind slate-950, slate-900, zinc-800 (the site's hero gradient)
  private static let slate950 = Color(red: 2 / 255, green: 6 / 255, blue: 23 / 255)
  private static let slate900 = Color(red: 15 / 255, green: 23 / 255, blue: 42 / 255)
  private static let zinc800 = Color(red: 39 / 255, green: 39 / 255, blue: 42 / 255)

  /// Stable pseudo-random value in 0..<1, so each star keeps its twinkle across frames.
  private static func random(_ seed: Double, _ salt: Double) -> Double {
    let value = sin(seed * 12.9898 + salt * 78.233) * 43758.5453
    return value - floor(value)
  }
}

/// Re-projects the sky only when the size changes or every few seconds — the real sky
/// turns just 0.25° a minute, so per-frame math would be wasted.
private final class SkyCache {
  private var cached: [ProjectedStar] = []
  private var cachedSize: CGSize = .zero
  private var cachedDate: Date = .distantPast

  func stars(at date: Date, size: CGSize) -> [ProjectedStar] {
    if size != cachedSize || abs(date.timeIntervalSince(cachedDate)) > 5 {
      cached = StarCatalog.project(at: date, width: size.width, height: size.height)
      cachedSize = size
      cachedDate = date
    }
    return cached
  }
}

#Preview {
  NightSkyView()
    .ignoresSafeArea()
}
