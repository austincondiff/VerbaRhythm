//
//  MoreMenu.swift
//  VerbaRhythm
//
//  Created by Austin Condiff on 8/27/24.
//

import SwiftUI

struct MoreMenu: View {
    @EnvironmentObject var viewModel: ContentViewModel

    var body: some View {
        Menu {
            Button {
                viewModel.currentIndex = 0
            } label: {
                Label("Go to Beginning", systemImage: "backward.end.fill")
            }
            Button {
                viewModel.currentIndex = viewModel.words.count - 1
            } label: {
                Label("Go to End", systemImage: "forward.end.fill")
            }

            Divider()

            Button {
                viewModel.phraseText = ""
                viewModel.focusedField = true
                viewModel.isFullScreen = false
            } label: {
                Label("New Entry", systemImage: "square.and.pencil")
            }

            Divider()

            Button {
                viewModel.settingsSheetIsPresented = true
            } label: {
                Label("Settings", systemImage: "gear")
            }
        } label: {
            Label("More", systemImage: "ellipsis.circle")

        }
        .help("More")
    }
}

#Preview {
    MoreMenu()
}
