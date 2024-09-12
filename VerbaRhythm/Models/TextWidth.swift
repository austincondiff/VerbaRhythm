//
//  TextWidth.swift
//  VerbaRhythm
//
//  Created by Austin Condiff on 9/10/24.
//

import SwiftUI

enum TextWidth: String, CaseIterable {
    case compressed = "Compressed"
    case condensed = "Condensed"
    case standard = "Standard"
    case expanded = "Expanded"

    func toFontWidth() -> Font.Width {
        switch self {
        case .compressed:
            return .compressed
        case .condensed:
            return .condensed
        case .standard:
            return .standard
        case .expanded:
            return .expanded
        }
    }
}
