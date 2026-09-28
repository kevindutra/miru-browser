//
//  FilterListParser.swift
//  Miru Browser
//
//  Created by Kevin Dutra on 12/2/25.
//

import Foundation

/// Parses EasyList/AdBlock Plus filter syntax and converts to WebKit content blocking JSON format
struct FilterListParser {
    
    // WebKit has a limit of ~50,000 rules
    private static let maxRules = 50000
    
    struct WebKitRule: Codable {
        let trigger: Trigger
        let action: Action
        
        struct Trigger: Codable {
            let urlFilter: String
            var urlFilterIsCaseSensitive: Bool?
            var ifDomain: [String]?
            var unlessDomain: [String]?
            var resourceType: [String]?
            var loadType: [String]?
            
            enum CodingKeys: String, CodingKey {
                case urlFilter = "url-filter"
                case urlFilterIsCaseSensitive = "url-filter-is-case-sensitive"
                case ifDomain = "if-domain"
                case unlessDomain = "unless-domain"
                case resourceType = "resource-type"
                case loadType = "load-type"
            }
        }
        
        struct Action: Codable {
            let type: String
            var selector: String?
        }
    }
    
    /// Parse EasyList format and convert to WebKit JSON rules
    static func parseEasyList(_ content: String) -> [WebKitRule] {
        let lines = content.components(separatedBy: .newlines)
        var rules: [WebKitRule] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("!") || trimmed.hasPrefix("[") {
                continue
            }
            
            // Skip element hiding rules for now (## syntax)
            if trimmed.contains("##") || trimmed.contains("#@#") || trimmed.contains("#?#") {
                continue
            }
            
            // Skip exception rules for simplicity (@@)
            if trimmed.hasPrefix("@@") {
                continue
            }
            
            if let rule = parseBlockingRule(trimmed) {
                rules.append(rule)
            }
            
            // Stop if we hit the limit
            if rules.count >= maxRules {
                break
            }
        }
        
        return rules
    }
    
    /// Resource-type options WebKit can express, mapped to its `resource-type` values
    private static let resourceTypeOptions: [String: String] = [
        "script": "script",
        "image": "image",
        "stylesheet": "style-sheet",
        "xmlhttprequest": "fetch",
        "subdocument": "document",
        "font": "font",
        "media": "media",
        "ping": "ping",
        "websocket": "websocket",
        "other": "raw",
    ]

    /// Parse a single blocking rule. Returns nil for rules WebKit can't express faithfully —
    /// dropping an option would broaden the rule, and one invalid rule fails the whole list.
    private static func parseBlockingRule(_ line: String) -> WebKitRule? {
        // WebKit only accepts ASCII url-filters
        guard line.allSatisfy(\.isASCII) else { return nil }

        var pattern = line
        var includeDomains: [String] = []
        var excludeDomains: [String] = []
        var resourceTypes: [String] = []
        var thirdParty: Bool?
        var caseSensitive = false

        // Parse options after $
        if let dollarIndex = pattern.lastIndex(of: "$") {
            let optionsString = String(pattern[pattern.index(after: dollarIndex)...])
            pattern = String(pattern[..<dollarIndex])

            for option in optionsString.components(separatedBy: ",") {
                let opt = option.trimmingCharacters(in: .whitespaces).lowercased()

                if opt == "third-party" || opt == "3p" {
                    thirdParty = true
                } else if opt == "~third-party" || opt == "1p" {
                    thirdParty = false
                } else if opt == "match-case" {
                    caseSensitive = true
                } else if opt.hasPrefix("domain=") {
                    for domain in opt.dropFirst(7).components(separatedBy: "|") where !domain.isEmpty {
                        if domain.hasPrefix("~") {
                            excludeDomains.append("*" + domain.dropFirst())
                        } else {
                            includeDomains.append("*" + domain)
                        }
                    }
                } else if let type = resourceTypeOptions[opt] {
                    resourceTypes.append(type)
                } else {
                    // Unsupported option ($popup, $csp, $redirect, ~script, ...)
                    return nil
                }
            }
        }

        guard let urlFilter = convertToRegex(pattern) else {
            return nil
        }

        var trigger = WebKitRule.Trigger(urlFilter: urlFilter)
        if caseSensitive {
            trigger.urlFilterIsCaseSensitive = true
        }
        if !resourceTypes.isEmpty {
            trigger.resourceType = resourceTypes
        }
        if thirdParty == true {
            trigger.loadType = ["third-party"]
        } else if thirdParty == false {
            trigger.loadType = ["first-party"]
        }

        // WebKit forbids if-domain and unless-domain on the same trigger; the
        // include list is the narrower of the two, so keep it
        if !includeDomains.isEmpty {
            trigger.ifDomain = includeDomains
        } else if !excludeDomains.isEmpty {
            trigger.unlessDomain = excludeDomains
        }

        return WebKitRule(trigger: trigger, action: WebKitRule.Action(type: "block"))
    }

    /// Convert an EasyList pattern to a WebKit url-filter. WebKit's regex subset has
    /// no alternation (`|`), so every construct here maps to single-branch syntax.
    private static func convertToRegex(_ pattern: String) -> String? {
        var body = pattern

        // Raw /regex/ rules usually rely on syntax WebKit doesn't support
        if body.count > 1, body.hasPrefix("/"), body.hasSuffix("/") {
            return nil
        }

        var prefix = ""
        var suffix = ""
        if body.hasPrefix("||") {
            // Domain anchor: the host or any subdomain of it
            body.removeFirst(2)
            prefix = "^[^:]+://+([^:/]+\\.)?"
        } else if body.hasPrefix("|") {
            body.removeFirst()
            prefix = "^"
        }
        if body.hasSuffix("|") {
            body.removeLast()
            suffix = "$"
        }

        // A remaining | would need alternation
        guard !body.contains("|") else { return nil }

        // Drop wildcards at the edges — url-filter already matches anywhere
        while body.hasPrefix("*") && prefix.isEmpty { body.removeFirst() }
        while body.hasSuffix("*") && suffix.isEmpty { body.removeLast() }
        guard !body.isEmpty || !prefix.isEmpty else { return nil }

        var regex = prefix
        for character in body {
            switch character {
            case "*":
                regex += ".*"
            case "^":
                // Separator: any non-URL-token character. WebKit normalizes URLs, so a
                // bare host always ends in "/" and this still matches "||example.com^"
                regex += "[/:?=&]"
            case ".", "+", "?", "(", ")", "[", "]", "{", "}", "\\", "$":
                regex += "\\" + String(character)
            default:
                regex += String(character)
            }
        }
        return regex + suffix
    }

    /// Convert rules to JSON string for WebKit
    static func rulesToJSON(_ rules: [WebKitRule]) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        
        guard let data = try? encoder.encode(rules) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
}

