//
//  SettingsViewModel.swift
//  VerbaRhythm
//
//  Created by Austin Condiff on 8/27/24.
//

import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    @Published var showGhostText: Bool {
        didSet { UserDefaults.standard.set(showGhostText, forKey: "showGhostText") }
    }
    @Published var showGuides: Bool {
        didSet { UserDefaults.standard.set(showGuides, forKey: "showGuides") }
    }
    @Published var fontSize: CGFloat {
        didSet { UserDefaults.standard.set(fontSize, forKey: "fontSize") }
    }
    @Published var fontStyle: TextStyle {
        didSet { UserDefaults.standard.set(fontStyle.rawValue, forKey: "fontStyle") }
    }
    @Published var fontWeight: TextWeight {
        didSet { UserDefaults.standard.set(fontWeight.rawValue, forKey: "fontWeight") }
    }
    @Published var fontWidth: TextWidth {
        didSet { UserDefaults.standard.set(fontWidth.rawValue, forKey: "fontWidth") }
    }
    @Published var speedMultiplier: Double {
        didSet { UserDefaults.standard.set(speedMultiplier, forKey: "speedMultiplier") }
    }
    @Published var isDynamicSpeedOn: Bool {
        didSet { UserDefaults.standard.set(isDynamicSpeedOn, forKey: "isDynamicSpeedOn") }
    }

    // Default values
    private let defaultShowGhostText = true
    private let defaultShowGuides = true
    private let defaultFontSize: CGFloat = 34.0
    private let defaultFontStyle: TextStyle = .sansSerif
    private let defaultFontWeight: TextWeight = .bold
    private let defaultFontWidth: TextWidth = .standard
    private let defaultSpeedMultiplier: Double = 1.0
    private let defaultIsDynamicSpeedOn = true

    init() {
        self.showGhostText = UserDefaults.standard.object(forKey: "showGhostText") as? Bool ?? defaultShowGhostText
        self.showGuides = UserDefaults.standard.object(forKey: "showGuides") as? Bool ?? defaultShowGuides
        self.fontSize = UserDefaults.standard.object(forKey: "fontSize") as? CGFloat ?? defaultFontSize
        self.fontStyle = TextStyle(rawValue: UserDefaults.standard.string(forKey: "fontStyle") ?? defaultFontStyle.rawValue) ?? defaultFontStyle
        self.fontWeight = TextWeight(rawValue: UserDefaults.standard.string(forKey: "fontWeight") ?? defaultFontWeight.rawValue) ?? defaultFontWeight
        self.fontWidth = TextWidth(rawValue: UserDefaults.standard.string(forKey: "fontWidth") ?? defaultFontWidth.rawValue) ?? defaultFontWidth
        self.speedMultiplier = UserDefaults.standard.object(forKey: "speedMultiplier") as? Double ?? defaultSpeedMultiplier
        self.isDynamicSpeedOn = UserDefaults.standard.object(forKey: "isDynamicSpeedOn") as? Bool ?? defaultIsDynamicSpeedOn
    }

    // Function to reset settings to default values
    func resetToDefaults() {
        showGhostText = defaultShowGhostText
        showGuides = defaultShowGuides
        fontSize = defaultFontSize
        fontStyle = defaultFontStyle
        fontWeight = defaultFontWeight
        fontWidth = defaultFontWidth
        speedMultiplier = defaultSpeedMultiplier
        isDynamicSpeedOn = defaultIsDynamicSpeedOn
    }
}
