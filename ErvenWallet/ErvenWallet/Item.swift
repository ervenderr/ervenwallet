//
//  Item.swift
//  ErvenWallet
//
//  Created by Ervenderr on 4/12/26.
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
