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
        
        // Prefer the weekly download, then the bundled copy, then basic rules —
        // WebKit rejects the whole list if any rule fails to compile
        var sources: [String] = []
        if let downloaded = await FilterUpdateService().downloadedEasyListContent() {
            sources.append(downloaded)
        }
        if let bundled = loadBundledEasyList() {
            sources.append(bundled)
        }

        for source in sources {
            let rules = FilterListParser.parseEasyList(source)
            guard let jsonRules = FilterListParser.rulesToJSON(rules) else { continue }
            if await compileRules(jsonRules) {
                self.rulesCount = rules.count
                return
            }
        }

        await compileBasicRules()
    }
    
    /// Check for cached compiled rules
    private func getCachedRules() async -> WKContentRuleList? {
        return await withCheckedContinuation { continuation in
            WKContentRuleListStore.default().lookUpContentRuleList(forIdentifier: ruleListIdentifier) { ruleList, error in
                continuation.resume(returning: ruleList)
            }
        }
    }
    
    /// Compile rules from JSON string, returning whether compilation succeeded
    private func compileRules(_ jsonRules: String) async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: ruleListIdentifier,
                encodedContentRuleList: jsonRules
            ) { [weak self] ruleList, error in
                if let error = error {
                    print("Failed to compile content rules: \(error)")
                    continuation.resume(returning: false)
                } else {
                    self?.contentRuleList = ruleList
                    self?.isLoaded = true
                    continuation.resume(returning: true)
                }
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
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?doubleclick\\\\.net[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?googlesyndication\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?googleadservices\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?google-analytics\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?googletagmanager\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?facebook\\\\.net[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?fbcdn\\\\.net[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?amazon-adsystem\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?advertising\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?adnxs\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?adsrvr\\\\.org[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?criteo\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?outbrain\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?taboola\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?scorecardresearch\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?quantserve\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?pubmatic\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?rubiconproject\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?openx\\\\.net[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?casalemedia\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?moatads\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?serving-sys\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?adroll\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?bidswitch\\\\.net[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^[^:]+://+([^:/]+\\\\.)?contextweb\\\\.com[/:?=&]"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^https?://.*/ads/"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^https?://.*/ad/"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^https?://.*/advertisement"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^https?://.*/banner"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^https?://.*/popup"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^https?://.*/tracking"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^https?://.*/analytics"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "^https?://.*/pixel"
                },
                "action": {
                    "type": "block"
                }
            }
        ]
        """
        
        self.rulesCount = 33
        _ = await compileRules(basicRules)
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

