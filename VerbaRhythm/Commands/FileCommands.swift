//
//  FileCommands.swift
//  VerbaRhythm
//
//  Created by Austin Condiff on 9/9/24.
//

import SwiftUI

struct FileCommands: Commands {
    @ObservedObject var viewModel: ContentViewModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Entry", action: viewModel.addNewEntry)
                .keyboardShortcut("N", modifiers: .command)
        }
    }
}
