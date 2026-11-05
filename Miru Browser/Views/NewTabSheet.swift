//
//  NewTabSheet.swift
//  Miru Browser
//

import SwiftUI
import WebKit

/// A page a site asked to open in a new tab or window (target="_blank",
/// window.open). Shown as a slide-up panel over the page that opened it.
@Observable
final class NewTabPage: NSObject, Identifiable, WKNavigationDelegate, WKUIDelegate {
  let webView: WKWebView
  var title: String = ""
  var url: URL?
  /// Set when the page closes itself (window.close()), e.g. after an OAuth popup
  var onClose: (() -> Void)?

  private var titleObservation: NSKeyValueObservation?
  private var urlObservation: NSKeyValueObservation?

  /// WebKit requires the returned web view to use the configuration it hands
  /// us, which keeps the opener link, data store, and ad-block rules.
  init(configuration: WKWebViewConfiguration) {
    webView = MiruWebView(frame: .zero, configuration: configuration)
    super.init()
    webView.navigationDelegate = self
    webView.uiDelegate = self
    webView.allowsBackForwardNavigationGestures = true

    titleObservation = webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
      DispatchQueue.main.async { self?.title = webView.title ?? "" }
    }
    urlObservation = webView.observe(\.url, options: [.new]) { [weak self] webView, _ in
      guard let url = webView.url else { return }
      DispatchQueue.main.async { self?.url = url }
    }
  }

  func close() {
    webView.stopLoading()
    webView.navigationDelegate = nil
    webView.uiDelegate = nil
  }

  // MARK: - WKNavigationDelegate

  func webView(
    _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    if let target = WebView.safariRedirectTarget(navigationAction.request.url) {
      decisionHandler(.cancel)
      webView.load(URLRequest(url: target))
      return
    }
    decisionHandler(.allow)
  }

  // MARK: - WKUIDelegate

  /// A new tab opened from inside the panel loads in the panel itself
  func webView(
    _ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
    for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures
  ) -> WKWebView? {
    webView.load(navigationAction.request)
    return nil
  }

  func webViewDidClose(_ webView: WKWebView) {
    onClose?()
  }
}

struct NewTabSheet: View {
  let page: NewTabPage
  let onClose: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
          Text(page.title.isEmpty ? "New Tab" : page.title)
            .font(.headline)
            .lineLimit(1)
          if let host = page.url?.host() {
            Text(host)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
        Spacer()
        Button(action: onClose) {
          Image(systemName: "xmark")
            .font(.system(size: 15, weight: .semibold))
            .frame(width: 32, height: 32)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel("Close tab")
      }
      .padding(.horizontal, 16)
      .padding(.top, 16)
      .padding(.bottom, 10)

      NewTabWebView(webView: page.webView)
        .ignoresSafeArea(edges: .bottom)
    }
    .presentationDragIndicator(.visible)
  }
}

/// Hosts a web view WebKit already created for us
private struct NewTabWebView: UIViewRepresentable {
  let webView: WKWebView
  func makeUIView(context: Context) -> WKWebView { webView }
  func updateUIView(_ webView: WKWebView, context: Context) {}
}
