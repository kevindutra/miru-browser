//
//  FilterUpdateService.swift
//  Miru Browser
//
//  Created by Kevin Dutra on 12/2/25.
//

import Foundation

/// Service to check for and download EasyList filter updates
actor FilterUpdateService {
    
    private let easyListURL = URL(string: "https://easylist.to/easylist/easylist.txt")!
    private let lastUpdateKey = "lastEasyListUpdate"
    private let updateIntervalDays: Double = 7 // Update weekly
    
    /// Check if an update is needed and download if so
    func checkForUpdates() async -> Bool {
        // Check last update time
        let lastUpdate = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date ?? .distantPast
        let daysSinceUpdate = Date().timeIntervalSince(lastUpdate) / (24 * 60 * 60)
        
        if daysSinceUpdate < updateIntervalDays {
            return false
        }
        
        return await downloadUpdate()
    }
    
    /// Download the latest EasyList
    func downloadUpdate() async -> Bool {
        do {
            let (data, response) = try await URLSession.shared.data(from: easyListURL)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Failed to download EasyList: Invalid response")
                return false
            }
            
            guard let content = String(data: data, encoding: .utf8) else {
                print("Failed to decode EasyList content")
                return false
            }
            
            // Save to documents directory
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsURL.appendingPathComponent("easylist.txt")
            
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Update last update timestamp
            UserDefaults.standard.set(Date(), forKey: lastUpdateKey)
            
            print("Successfully updated EasyList with \(content.count) characters")
            return true
            
        } catch {
            print("Failed to download EasyList: \(error)")
            return false
        }
    }
    
    /// The most recently downloaded EasyList, if one has been downloaded
    func downloadedEasyListContent() -> String? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let downloadedURL = documentsURL.appendingPathComponent("easylist.txt")
        return try? String(contentsOf: downloadedURL, encoding: .utf8)
    }
    
    /// Get the date of the last successful update
    func lastUpdateDate() -> Date? {
        return UserDefaults.standard.object(forKey: lastUpdateKey) as? Date
    }
}

