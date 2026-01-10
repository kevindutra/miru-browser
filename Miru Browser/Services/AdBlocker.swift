//
//  AdBlocker.swift
//  Miru Browser
//
//  Created by Kevin Dutra on 12/2/25.
//

import Combine
import Foundation
import WebKit

/// Manages ad blocking using WebKit content rules
@MainActor
final class AdBlocker: ObservableObject {
    
    private var contentRuleList: WKContentRuleList?
    private let ruleListIdentifier = "MiruAdBlockRules"
    
    @Published var isLoaded: Bool = false
    @Published var rulesCount: Int = 0
    
    init() {
        Task {
            await loadRules()
        }
    }
    
    /// Load and compile ad blocking rules
    func loadRules() async {
        // First check if we have cached rules
        if let cachedRules = await getCachedRules() {
            self.contentRuleList = cachedRules
            self.isLoaded = true
            return
        }
        
        // Load and parse EasyList
        guard let easyListContent = loadBundledEasyList() else {
            print("Failed to load EasyList from bundle")
            // Fall back to basic rules
            await compileBasicRules()
            return
        }
        
        // Parse and compile rules
        let rules = FilterListParser.parseEasyList(easyListContent)
        self.rulesCount = rules.count
        
        guard let jsonRules = FilterListParser.rulesToJSON(rules) else {
            print("Failed to convert rules to JSON")
            await compileBasicRules()
            return
        }
        
        await compileRules(jsonRules)
    }
    
    /// Check for cached compiled rules
    private func getCachedRules() async -> WKContentRuleList? {
        return await withCheckedContinuation { continuation in
            WKContentRuleListStore.default().lookUpContentRuleList(forIdentifier: ruleListIdentifier) { ruleList, error in
                continuation.resume(returning: ruleList)
            }
        }
    }
    
    /// Compile rules from JSON string
    private func compileRules(_ jsonRules: String) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: ruleListIdentifier,
                encodedContentRuleList: jsonRules
            ) { [weak self] ruleList, error in
                if let error = error {
                    print("Failed to compile content rules: \(error)")
                } else {
                    self?.contentRuleList = ruleList
                    self?.isLoaded = true
                }
                continuation.resume()
            }
        }
    }
    
    /// Load EasyList from app bundle
    private func loadBundledEasyList() -> String? {
        guard let url = Bundle.main.url(forResource: "easylist", withExtension: "txt") else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }
    
    /// Compile basic fallback rules if EasyList fails
    private func compileBasicRules() async {
        let basicRules = """
        [
            {
                "trigger": {
                    "url-filter": ".*",
                    "if-domain": ["*doubleclick.net", "*googlesyndication.com", "*googleadservices.com", "*google-analytics.com", "*googletagmanager.com", "*facebook.net", "*fbcdn.net", "*amazon-adsystem.com", "*advertising.com", "*adnxs.com", "*adsrvr.org", "*criteo.com", "*outbrain.com", "*taboola.com", "*scorecardresearch.com", "*quantserve.com", "*pubmatic.com", "*rubiconproject.com", "*openx.net", "*casalemedia.com", "*moatads.com", "*serving-sys.com", "*adroll.com", "*bidswitch.net", "*contextweb.com"]
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^https?://.*(/ads/|/ad/|/advertisement|/banner|/popup|/tracking|/analytics|/pixel)"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^https?://.*\\.(gif|png|jpg|jpeg)\\?.*tracking",
                    "resource-type": ["image"]
                },
                "action": {
                    "type": "block"
                }
            }
        ]
        """
        
        self.rulesCount = 3
        await compileRules(basicRules)
    }
    
    /// Apply rules to WebView configuration
    func applyRules(to configuration: WKWebViewConfiguration) {
        guard let ruleList = contentRuleList else { return }
        configuration.userContentController.add(ruleList)
    }
    
    /// Force refresh rules (e.g., after update)
    func refreshRules() async {
        // Remove cached rules
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            WKContentRuleListStore.default().removeContentRuleList(forIdentifier: ruleListIdentifier) { error in
                continuation.resume()
            }
        }
        
        // Reload
        self.isLoaded = false
        self.contentRuleList = nil
        await loadRules()
    }
}

