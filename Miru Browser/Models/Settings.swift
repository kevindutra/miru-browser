//
//  Settings.swift
//  Miru Browser
//
//  Created by Kevin Dutra on 12/5/25.
//

import SwiftUI

@Observable
final class AppSettings {
  private static let bookmarkURLKey = "bookmarkURL"

  static let defaultBookmarkURL = URL(string: "https://en.wikipedia.org")!

  /// The bookmark the person chose. Set exactly once; there is deliberately
  /// no way to change or clear it short of reinstalling the app.
  private(set) var lockedBookmarkURL: URL?

  /// What the home screen globe opens: the chosen bookmark, or Wikipedia
  /// until one is chosen.
  var bookmarkURL: URL { lockedBookmarkURL ?? Self.defaultBookmarkURL }

  init() {
    self.lockedBookmarkURL = UserDefaults.standard.url(forKey: Self.bookmarkURLKey)
  }

  /// Locks in the bookmark. Ignored if one is already set.
  func setBookmark(_ url: URL) {
    guard lockedBookmarkURL == nil else { return }
    lockedBookmarkURL = url
    UserDefaults.standard.set(url, forKey: Self.bookmarkURLKey)
  }
}
