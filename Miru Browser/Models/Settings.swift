//
//  Settings.swift
//  Miru Browser
//
//  Created by Kevin Dutra on 12/5/25.
//

import SwiftUI

@Observable
final class AppSettings {
  private static let defaultSiteURLKey = "defaultSiteURL"
  private static let showDefaultSiteButtonKey = "showDefaultSiteButton"
  
  var defaultSiteURL: String {
    didSet {
      UserDefaults.standard.set(defaultSiteURL, forKey: Self.defaultSiteURLKey)
    }
  }
  
  var showDefaultSiteButton: Bool {
    didSet {
      UserDefaults.standard.set(showDefaultSiteButton, forKey: Self.showDefaultSiteButtonKey)
    }
  }
  
  init() {
    self.defaultSiteURL = UserDefaults.standard.string(forKey: Self.defaultSiteURLKey) ?? "https://en.wikipedia.org"
    self.showDefaultSiteButton = UserDefaults.standard.object(forKey: Self.showDefaultSiteButtonKey) as? Bool ?? true
  }
}
