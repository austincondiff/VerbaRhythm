//
//  TextSize.swift
//  VerbaRhythm
//
//  Created by Austin Condiff on 9/10/24.
//

import SwiftUI

enum TextSize: String, CaseIterable {
    case xs = "Extra Small"
    case sm = "Small"
    case md = "Medium"
    case lg = "Large"
    case xl = "Extra Large"

    func toSize() -> CGFloat {
        switch self {
        case .xs:
            return 20
        case .sm:
            return 28
        case .md:
            return 34
        case .lg:
            return 40
        case .xl:
            return 48
        }
    }
}
