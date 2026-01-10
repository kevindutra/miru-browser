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
    
    /// Parse a single blocking rule
    private static func parseBlockingRule(_ line: String) -> WebKitRule? {
        var pattern = line
        var domains: [String]?
        var resourceTypes: [String]?
        var thirdParty: Bool?
        
        // Parse options after $
        if let dollarIndex = pattern.lastIndex(of: "$") {
            let optionsString = String(pattern[pattern.index(after: dollarIndex)...])
            pattern = String(pattern[..<dollarIndex])
            
            let options = optionsString.components(separatedBy: ",")
            for option in options {
                let opt = option.trimmingCharacters(in: .whitespaces)
                
                if opt == "third-party" {
                    thirdParty = true
                } else if opt == "~third-party" {
                    thirdParty = false
                } else if opt.hasPrefix("domain=") {
                    let domainStr = String(opt.dropFirst(7))
                    domains = domainStr.components(separatedBy: "|").map { d in
                        d.hasPrefix("~") ? d : "*\(d)"
                    }
                } else if opt == "script" {
                    resourceTypes = ["script"]
                } else if opt == "image" {
                    resourceTypes = ["image"]
                } else if opt == "stylesheet" {
                    resourceTypes = ["style-sheet"]
                } else if opt == "xmlhttprequest" {
                    resourceTypes = ["fetch"]
                } else if opt == "subdocument" {
                    resourceTypes = ["document"]
                }
            }
        }
        
        // Convert pattern to regex
        guard let urlFilter = convertToRegex(pattern) else {
            return nil
        }
        
        var trigger = WebKitRule.Trigger(urlFilter: urlFilter)
        
        if let types = resourceTypes {
            trigger.resourceType = types
        }
        
        if thirdParty == true {
            trigger.loadType = ["third-party"]
        } else if thirdParty == false {
            trigger.loadType = ["first-party"]
        }
        
        if let doms = domains {
            let includeDomains = doms.filter { !$0.hasPrefix("~") }
            let excludeDomains = doms.filter { $0.hasPrefix("~") }.map { String($0.dropFirst()) }
            
            if !includeDomains.isEmpty {
                trigger.ifDomain = includeDomains
            }
            if !excludeDomains.isEmpty {
                trigger.unlessDomain = excludeDomains
            }
        }
        
        let action = WebKitRule.Action(type: "block")
        
        return WebKitRule(trigger: trigger, action: action)
    }
    
    /// Convert EasyList pattern to WebKit regex
    private static func convertToRegex(_ pattern: String) -> String? {
        var regex = pattern
        
        // Handle domain anchor ||
        if regex.hasPrefix("||") {
            regex = String(regex.dropFirst(2))
            regex = "^https?://([^/]+\\.)?" + escapeRegex(regex)
        }
        // Handle start anchor |
        else if regex.hasPrefix("|") {
            regex = String(regex.dropFirst())
            regex = "^" + escapeRegex(regex)
        }
        // Handle end anchor |
        else if regex.hasSuffix("|") {
            regex = String(regex.dropLast())
            regex = escapeRegex(regex) + "$"
        }
        else {
            regex = escapeRegex(regex)
        }
        
        // Replace separator ^ with regex pattern
        regex = regex.replacingOccurrences(of: "\\^", with: "([/?#]|$)")
        
        // Replace wildcard * with regex pattern
        regex = regex.replacingOccurrences(of: "\\*", with: ".*")
        
        // Basic validation
        if regex.isEmpty {
            return nil
        }
        
        return regex
    }
    
    /// Escape special regex characters
    private static func escapeRegex(_ string: String) -> String {
        let specialChars = ["\\", ".", "+", "?", "[", "]", "{", "}", "(", ")", "^", "$", "|"]
        var result = string
        
        for char in specialChars {
            result = result.replacingOccurrences(of: char, with: "\\\(char)")
        }
        
        // Keep * and ^ as they have special meaning in EasyList
        result = result.replacingOccurrences(of: "\\\\\\*", with: "\\*")
        result = result.replacingOccurrences(of: "\\\\\\^", with: "\\^")
        
        return result
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

