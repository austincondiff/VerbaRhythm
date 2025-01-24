//
//  Entry.swift
//  VerbaRhythm
//
//  Created by Austin Condiff on 8/18/24.
//

import SwiftData
import Foundation

@Model
final class Entry: Codable {
    var id: UUID
    var text: String
    var timestamp: Date
    var pinned: Bool
    
    init(id: UUID = UUID(), text: String, timestamp: Date = Date(), pinned: Bool = false) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.pinned = pinned
    }
    
    // Codable conformance
    enum CodingKeys: CodingKey {
        case id, text, timestamp, pinned
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        pinned = try container.decode(Bool.self, forKey: .pinned)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(pinned, forKey: .pinned)
    }
}
