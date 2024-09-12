//
//  TextStyle.swift
//  VerbaRhythm
//
//  Created by Austin Condiff on 9/10/24.
//

import SwiftUI

enum TextStyle: String, CaseIterable {
    case sansSerif = "Sans Serif"
    case serif = "Serif"
    case monospaced = "Monospaced"
    case rounded = "Rounded"

    func toFont(size: CGFloat, weight: TextWeight, width: TextWidth) -> Font {
        switch self {
        case .sansSerif:
            return .system(size: size, weight: weight.toFontWeight(), design: .default).width(width.toFontWidth())
        case .serif:
            return .system(size: size, weight: weight.toFontWeight(), design: .serif).width(width.toFontWidth())
        case .monospaced:
            return .system(size: size, weight: weight.toFontWeight(), design: .monospaced).width(width.toFontWidth())
        case .rounded:
            return .system(size: size, weight: weight.toFontWeight(), design: .rounded).width(width.toFontWidth())
        }
    }
}
