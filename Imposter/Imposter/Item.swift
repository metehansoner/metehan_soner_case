//
//  Item.swift
//  Imposter
//
//  Created by Metehan Soner on 24.07.2026.
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
