//
//  NavigateCommands.swift
//  VerbaRhythm
//
//  Created by Austin Condiff on 9/9/24.
//

import SwiftUI

struct NavigateCommands: Commands {
    @ObservedObject var viewModel: ContentViewModel

    var body: some Commands {
        CommandMenu("Navigate") {
            Button(viewModel.isPlaying ? "Pause" : "Play", action: viewModel.togglePlayback)
                .keyboardShortcut(.space, modifiers: viewModel.focusedField ? .control : [])
                .disabled(viewModel.words.count == 0 || viewModel.currentIndex == viewModel.words.count-1)
            Button("Next Word", action: viewModel.next)
                .keyboardShortcut(.rightArrow, modifiers: viewModel.focusedField ? .control : [])
                .disabled(viewModel.words.count == 0 || viewModel.currentIndex == viewModel.words.count-1)
            Button("Previous Word", action: viewModel.prev)
                .keyboardShortcut(.leftArrow, modifiers: viewModel.focusedField ? .control : [])
                .disabled(viewModel.words.count == 0 || viewModel.currentIndex == 0)
            Button("Last Word", action: viewModel.toEnd)
                .keyboardShortcut(.rightArrow, modifiers: viewModel.focusedField ? .control : .command)
                .disabled(viewModel.words.count == 0 || viewModel.currentIndex == viewModel.words.count-1)
            Button("First Word", action: viewModel.toBeginning)
                .keyboardShortcut(.leftArrow, modifiers: viewModel.focusedField ? .control : .command)
                .disabled(viewModel.words.count == 0 || viewModel.currentIndex == 0)
        }
    }
}
