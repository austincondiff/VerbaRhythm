//
//  ViewCommands.swift
//  VerbaRhythm
//
//  Created by Austin Condiff on 9/9/24.
//

import SwiftUI

struct ViewCommands: Commands {
    @ObservedObject var viewModel: ContentViewModel
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
            Button(viewModel.columnVisibility == .all ? "Hide Navigator" : "Show Navigator") {
                withAnimation {
                    if viewModel.columnVisibility == .all {
                        viewModel.columnVisibility = .detailOnly
                    } else {
                        viewModel.columnVisibility = .all
                    }
                }
            }
            Button(viewModel.settingsSheetIsPresented ? "Hide Inspector" : "Show Inspector") {
                withAnimation {
                    if viewModel.settingsSheetIsPresented {
                        viewModel.settingsSheetIsPresented = false
                    } else {
                        viewModel.settingsSheetIsPresented = true
                    }
                }
            }
            Button(viewModel.isFullScreen ? "Show Text Editor" : "Hide Text Editor") {
                withAnimation {
                    if viewModel.isFullScreen {
                        viewModel.isFullScreen = false
                    } else {
                        viewModel.isFullScreen = true
                    }
                }
            }
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
