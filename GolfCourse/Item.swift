//
//  Item.swift
//  GolfCourse
//
//  Created by Ringo Wathelet on 2026/11/17.
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
