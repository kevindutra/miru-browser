//
//  MiruWebView.swift
//  Miru Browser
//

import UIKit
import WebKit

/// WKWebView with the system "Look Up" / "Search Web" items removed from the
/// text-selection menu. Used for both the main page and new-tab panels.
final class MiruWebView: WKWebView {
  override func buildMenu(with builder: UIMenuBuilder) {
    // The lookup menu holds Look Up and Search Web
    builder.remove(menu: .lookup)
    super.buildMenu(with: builder)
  }

  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    // Older edit-menu paths ask the responder chain per action instead
    if Self.lookupActions.contains(action) { return false }
    return super.canPerformAction(action, withSender: sender)
  }

  private static let lookupActions: Set<Selector> = [
    NSSelectorFromString("_define:"),
    NSSelectorFromString("_lookup:"),
    NSSelectorFromString("_searchWeb:"),
  ]
}
