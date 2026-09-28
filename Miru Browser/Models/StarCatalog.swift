//
//  StarCatalog.swift
//  Miru Browser
//
//  Real star positions for the empty-state night sky, as seen from New York City.
//

import Foundation

struct CatalogStar {
  let sinDec: Double
  let cosDec: Double
  let ra: Double  // radians, J2000
  let magnitude: Double
  let colorIndex: Double  // B-V
}

/// A star projected onto the screen for a given moment.
struct ProjectedStar {
  let x: Double
  let y: Double
  let magnitude: Double
  let colorIndex: Double
  let seed: Int
}

enum StarCatalog {
  /// Bright stars (V ≤ 5.5) from the Yale Bright Star Catalog, loaded from `stars.csv`.
  static let stars: [CatalogStar] = {
    guard let url = Bundle.main.url(forResource: "stars", withExtension: "csv"),
      let text = try? String(contentsOf: url, encoding: .utf8)
    else { return [] }

    return text.split(separator: "\n").compactMap { line in
      guard !line.hasPrefix("#") else { return nil }
      let fields = line.split(separator: ",").compactMap { Double($0) }
      guard fields.count == 4 else { return nil }
      let dec = fields[1] * .pi / 180
      return CatalogStar(
        sinDec: sin(dec), cosDec: cos(dec), ra: fields[0] * .pi / 180,
        magnitude: fields[2], colorIndex: fields[3])
    }
  }()

  // New York City
  static let latitude = 40.7128 * Double.pi / 180
  static let longitude = -74.0060

  /// Projects the stars above the NYC horizon at `date` onto a screen of `width` × `height`,
  /// looking straight up with north at the top (so east is on the left).
  static func project(at date: Date, width: Double, height: Double) -> [ProjectedStar] {
    let julianDay = date.timeIntervalSince1970 / 86400 + 2440587.5
    let gmst = 280.46061837 + 360.98564736629 * (julianDay - 2451545.0)
    let localSiderealTime = (gmst + longitude).truncatingRemainder(dividingBy: 360) * .pi / 180

    let sinLat = sin(latitude)
    let cosLat = cos(latitude)

    // Stereographic projection centred on the zenith; half the screen height spans 65°
    let scale = (height / 2) / (2 * tan(65 * Double.pi / 360))
    let centerX = width / 2
    let centerY = height / 2

    var projected: [ProjectedStar] = []
    for (index, star) in stars.enumerated() {
      let hourAngle = localSiderealTime - star.ra
      let cosH = cos(hourAngle)
      let sinAlt = star.sinDec * sinLat + star.cosDec * cosLat * cosH
      guard sinAlt > 0 else { continue }

      let azimuth = atan2(
        -sin(hourAngle) * star.cosDec,
        star.sinDec * cosLat - star.cosDec * sinLat * cosH)
      let zenithDistance = acos(min(sinAlt, 1))
      let radius = 2 * tan(zenithDistance / 2) * scale

      let x = centerX - radius * sin(azimuth)
      let y = centerY - radius * cos(azimuth)
      guard x > -4, x < width + 4, y > -4, y < height + 4 else { continue }

      projected.append(
        ProjectedStar(
          x: x, y: y, magnitude: star.magnitude, colorIndex: star.colorIndex, seed: index))
    }
    return projected
  }
}
