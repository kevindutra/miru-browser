//
//  Item.swift
//  Miru Browser
//
//  Created by Kevin Dutra on 12/2/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
