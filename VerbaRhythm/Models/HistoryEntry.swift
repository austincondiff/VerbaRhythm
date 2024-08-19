//
//  HistoryEntry.swift
//  Verbarhythm
//
//  Created by Austin Condiff on 8/18/24.
//

import Foundation

struct HistoryEntry: Identifiable, Hashable, Codable, Equatable {
    let id: UUID
    var text: String
    var timestamp: Date
}
