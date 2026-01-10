//
//  BrowserState.swift
//  Miru Browser
//
//  Created by Kevin Dutra on 12/2/25.
//

import Foundation
import SwiftUI
import WebKit
import Observation

@Observable
final class BrowserState {
    var currentURL: URL?
    var isLoading: Bool = false
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var pageTitle: String = ""
    var loadingProgress: Double = 0.0
    
    // Theme color extracted from webpage's meta tag
    var themeColor: Color?
    
    // Navigation bar auto-hide state (hidden when scrolling down, shown when scrolling up)
    var isNavBarVisible: Bool = true
    
    // Flag to indicate an external URL request is pending
    var pendingExternalURL: URL?
    
    // Reference to the web view for navigation actions
    weak var webView: WKWebView?
    
    func loadURL(_ url: URL) {
        pendingExternalURL = url
        currentURL = url
        webView?.load(URLRequest(url: url))
    }
    
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
    
    func reload() {
        webView?.reload()
    }
    
    func close() {
        currentURL = nil
        pendingExternalURL = nil
        isLoading = false
        canGoBack = false
        canGoForward = false
        pageTitle = ""
        loadingProgress = 0.0
        themeColor = nil
        webView?.stopLoading()
    }
    
    func updateState(from webView: WKWebView) {
        // Most state is updated via KVO observers, but we sync isLoading here
        // since it's set explicitly in navigation delegate methods
    }
}

