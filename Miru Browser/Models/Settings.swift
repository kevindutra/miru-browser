//
//  Settings.swift
//  Miru Browser
//
//  Created by Kevin Dutra on 12/5/25.
//

import SwiftUI
import WebKit

@Observable
final class AppSettings {
  private static let bookmarkURLKey = "bookmarkURL"
  private static let staySignedInKey = "staySignedIn"

  static let defaultBookmarkURL = URL(string: "https://en.wikipedia.org")!

  /// The bookmark the person chose. Set exactly once; there is deliberately
  /// no way to change or clear it short of reinstalling the app.
  private(set) var lockedBookmarkURL: URL?

  /// What the home screen globe opens: the chosen bookmark, or Wikipedia
  /// until one is chosen.
  var bookmarkURL: URL { lockedBookmarkURL ?? Self.defaultBookmarkURL }

  /// Keep cookies and site data between pages and launches so logins stick.
  /// Off by default: pages load in a non-persistent store and save nothing.
  /// Turning it off erases everything that was stored while it was on.
  var staySignedIn: Bool {
    didSet {
      guard staySignedIn != oldValue else { return }
      UserDefaults.standard.set(staySignedIn, forKey: Self.staySignedInKey)
      if !staySignedIn {
        Self.clearStoredWebsiteData()
      }
    }
  }

  init() {
    self.lockedBookmarkURL = UserDefaults.standard.url(forKey: Self.bookmarkURLKey)
    self.staySignedIn = UserDefaults.standard.bool(forKey: Self.staySignedInKey)
  }

  /// Locks in the bookmark. Ignored if one is already set.
  func setBookmark(_ url: URL) {
    guard lockedBookmarkURL == nil else { return }
    lockedBookmarkURL = url
    UserDefaults.standard.set(url, forKey: Self.bookmarkURLKey)
  }

  /// Removes all cookies and site data from the persistent web data store.
  static func clearStoredWebsiteData() {
    WKWebsiteDataStore.default().removeData(
      ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
      modifiedSince: .distantPast
    ) {}
  }
}
