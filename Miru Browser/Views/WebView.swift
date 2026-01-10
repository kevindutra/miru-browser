//
//  WebView.swift
//  Miru Browser
//
//  Created by Kevin Dutra on 12/2/25.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
  @Environment(BrowserState.self) private var browserState
  let adBlocker: AdBlocker

  func makeCoordinator() -> Coordinator {
    Coordinator(browserState: browserState)
  }

  func makeUIView(context: Context) -> WKWebView {
    let configuration = WKWebViewConfiguration()
    configuration.websiteDataStore = .nonPersistent()

    // Prevent video autoplay and fullscreen
    configuration.mediaTypesRequiringUserActionForPlayback = .all
    configuration.allowsInlineMediaPlayback = true

    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.navigationDelegate = context.coordinator
    webView.allowsBackForwardNavigationGestures = true

    // Store reference in browser state for navigation actions
    browserState.webView = webView

    // Respect safe area so sticky headers don't go behind Dynamic Island
    // Theme color fill in ContentView creates the full-screen appearance
    webView.scrollView.contentInsetAdjustmentBehavior = .scrollableAxes

    // Add pull-to-refresh with custom release behavior
    let refreshControl = UIRefreshControl()
    refreshControl.tintColor = .systemBlue
    webView.scrollView.refreshControl = refreshControl
    webView.scrollView.delegate = context.coordinator
    context.coordinator.refreshControl = refreshControl

    // Apply ad blocking rules
    adBlocker.applyRules(to: webView.configuration)

    // Add KVO observers for progress
    context.coordinator.observeWebView(webView)

    // Load initial URL if present (either pending or current)
    if let url = browserState.pendingExternalURL {
      browserState.pendingExternalURL = nil
      webView.load(URLRequest(url: url))
    } else if let url = browserState.currentURL {
      webView.load(URLRequest(url: url))
    }

    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {
    // Only load when there's a pending external URL request (from onOpenURL, etc.)
    if let pendingURL = browserState.pendingExternalURL {
      browserState.pendingExternalURL = nil
      webView.load(URLRequest(url: pendingURL))
    }
  }

  class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {
    var browserState: BrowserState
    weak var refreshControl: UIRefreshControl?
    weak var webView: WKWebView?
    private var progressObservation: NSKeyValueObservation?
    private var titleObservation: NSKeyValueObservation?
    private var urlObservation: NSKeyValueObservation?
    private var isLoadingObservation: NSKeyValueObservation?
    private var canGoBackObservation: NSKeyValueObservation?
    private var canGoForwardObservation: NSKeyValueObservation?

    // Track if user has pulled far enough to trigger refresh
    private var shouldRefreshOnRelease = false
    private var isShowingFullAnimation = false
    private let refreshThreshold: CGFloat = 80

    // Track scroll direction for nav bar auto-hide
    private var lastContentOffset: CGFloat = 0
    private let scrollVelocityThreshold: CGFloat = 10
    private var hasUserStartedScrolling = false

    init(browserState: BrowserState) {
      self.browserState = browserState
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
      // Mark that user has started actively scrolling
      hasUserStartedScrolling = true
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
      // Check if user has pulled down past the threshold
      let pullDistance = -scrollView.contentOffset.y - scrollView.adjustedContentInset.top
      let pastThreshold = pullDistance > refreshThreshold

      // Show full animation once past threshold
      if pastThreshold && !isShowingFullAnimation {
        isShowingFullAnimation = true
        refreshControl?.beginRefreshing()
      } else if !pastThreshold && isShowingFullAnimation && scrollView.isDragging {
        // Reset if user drags back up above threshold
        isShowingFullAnimation = false
        refreshControl?.endRefreshing()
      }

      shouldRefreshOnRelease = pastThreshold

      // Track scroll direction for nav bar auto-hide
      // Only apply hide/show logic after user has started actively scrolling
      guard hasUserStartedScrolling else { return }
      
      let currentOffset = scrollView.contentOffset.y
      let scrollDelta = currentOffset - lastContentOffset

      // Always show nav bar when at or near the top of the page
      let isAtTop = currentOffset <= scrollView.adjustedContentInset.top

      if isAtTop {
        // Always show when at top
        if !browserState.isNavBarVisible {
          DispatchQueue.main.async { [weak self] in
            self?.browserState.isNavBarVisible = true
          }
        }
      } else if abs(scrollDelta) > scrollVelocityThreshold {
        // Only react to significant scroll movements
        let scrollingDown = scrollDelta > 0
        let shouldBeVisible = !scrollingDown

        if browserState.isNavBarVisible != shouldBeVisible {
          DispatchQueue.main.async { [weak self] in
            self?.browserState.isNavBarVisible = shouldBeVisible
          }
        }
      }

      lastContentOffset = currentOffset
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
      // Only trigger refresh on release if pulled far enough
      if shouldRefreshOnRelease {
        // Ensure refresh control is in refreshing state
        if !refreshControl!.isRefreshing {
          refreshControl?.beginRefreshing()
        }
        webView?.reload()

        // End refreshing after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
          self?.refreshControl?.endRefreshing()
          self?.isShowingFullAnimation = false
        }
      } else {
        // User released without pulling far enough
        isShowingFullAnimation = false
      }
      shouldRefreshOnRelease = false
    }

    func observeWebView(_ webView: WKWebView) {
      self.webView = webView
      progressObservation = webView.observe(\.estimatedProgress, options: [.new]) {
        [weak self] webView, _ in
        DispatchQueue.main.async {
          self?.browserState.loadingProgress = webView.estimatedProgress
        }
      }

      titleObservation = webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
        DispatchQueue.main.async {
          self?.browserState.pageTitle = webView.title ?? ""
        }
      }

      urlObservation = webView.observe(\.url, options: [.new]) { [weak self] webView, _ in
        DispatchQueue.main.async {
          self?.browserState.currentURL = webView.url
        }
      }

      isLoadingObservation = webView.observe(\.isLoading, options: [.new]) {
        [weak self] webView, _ in
        DispatchQueue.main.async {
          self?.browserState.isLoading = webView.isLoading
        }
      }

      canGoBackObservation = webView.observe(\.canGoBack, options: [.new]) {
        [weak self] webView, _ in
        DispatchQueue.main.async {
          self?.browserState.canGoBack = webView.canGoBack
        }
      }

      canGoForwardObservation = webView.observe(\.canGoForward, options: [.new]) {
        [weak self] webView, _ in
        DispatchQueue.main.async {
          self?.browserState.canGoForward = webView.canGoForward
        }
      }
    }

    // MARK: - WKNavigationDelegate

    func webView(
      _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
      decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
      // Allow all navigation since this is a view-only browser
      decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      extractThemeColor(from: webView)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
      // Reset theme color when navigating to a new page
      DispatchQueue.main.async { [weak self] in
        self?.browserState.themeColor = nil
        // Show nav bar and reset scroll tracking for new page
        self?.browserState.isNavBarVisible = true
        self?.hasUserStartedScrolling = false
        self?.lastContentOffset = 0
      }
    }

    // MARK: - Theme Color Extraction

    private func extractThemeColor(from webView: WKWebView) {
      let script = """
        (function() {
          var meta = document.querySelector('meta[name="theme-color"]');
          return meta ? meta.content : null;
        })()
        """

      webView.evaluateJavaScript(script) { [weak self] result, error in
        guard let colorString = result as? String else {
          return
        }

        if let color = self?.parseColor(colorString) {
          DispatchQueue.main.async {
            self?.browserState.themeColor = color
          }
        }
      }
    }

    private func parseColor(_ string: String) -> Color? {
      let trimmed = string.trimmingCharacters(in: .whitespaces)

      // Handle hex colors (#RGB, #RRGGBB, #RRGGBBAA)
      if trimmed.hasPrefix("#") {
        return parseHexColor(String(trimmed.dropFirst()))
      }

      // Handle rgb/rgba colors
      if trimmed.lowercased().hasPrefix("rgb") {
        return parseRgbColor(trimmed)
      }

      return nil
    }

    private func parseHexColor(_ hex: String) -> Color? {
      var hexValue = hex

      // Expand shorthand (#RGB -> #RRGGBB)
      if hexValue.count == 3 {
        hexValue = hexValue.map { "\($0)\($0)" }.joined()
      }

      guard hexValue.count >= 6 else { return nil }

      let scanner = Scanner(string: hexValue)
      var rgbValue: UInt64 = 0

      guard scanner.scanHexInt64(&rgbValue) else { return nil }

      let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
      let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
      let b = Double(rgbValue & 0x0000FF) / 255.0

      return Color(red: r, green: g, blue: b)
    }

    private func parseRgbColor(_ string: String) -> Color? {
      // Extract numbers from rgb(r, g, b) or rgba(r, g, b, a)
      let pattern = #"rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)"#

      guard let regex = try? NSRegularExpression(pattern: pattern),
        let match = regex.firstMatch(
          in: string,
          range: NSRange(string.startIndex..., in: string)
        )
      else {
        return nil
      }

      guard let rRange = Range(match.range(at: 1), in: string),
        let gRange = Range(match.range(at: 2), in: string),
        let bRange = Range(match.range(at: 3), in: string),
        let r = Double(string[rRange]),
        let g = Double(string[gRange]),
        let b = Double(string[bRange])
      else {
        return nil
      }

      return Color(red: r / 255.0, green: g / 255.0, blue: b / 255.0)
    }
  }
}
