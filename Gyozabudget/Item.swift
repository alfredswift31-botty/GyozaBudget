//
//  Item.swift
//  Gyozabudget
//
//  Created by Aung Hpone Moe on 10/04/2026.
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
