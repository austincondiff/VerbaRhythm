//
//  ViewCommands.swift
//  VerbaRhythm
//
//  Created by Austin Condiff on 9/9/24.
//

import SwiftUI

struct ViewCommands: Commands {
    @ObservedObject var settings: SettingsViewModel

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Menu("Font Size") {
                Button("Increase", action: increaseFontSize)
                    .keyboardShortcut("+", modifiers: .command)
                Button("Decrease", action: decreaseFontSize)
                    .keyboardShortcut("-", modifiers: .command)
                Divider()
                Button("Reset", action: resetFontSize)
                    .keyboardShortcut("0", modifiers: .command)
            }
            Divider()
        }
    }

    func increaseFontSize() {
        settings.fontSize += 1
    }

    func decreaseFontSize() {
        settings.fontSize -= 1
    }

    func resetFontSize() {
        settings.fontSize = 33.0
    }
}
