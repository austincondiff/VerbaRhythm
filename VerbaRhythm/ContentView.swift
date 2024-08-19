//
//  ContentView.swift
//  Verbarhythm
//
//  Created by Austin Condiff on 9/21/23.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var viewModel: ContentViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                WordDisplayView()
                if !viewModel.isFullScreen {
                    TextEntryView()
                        .transition(.move(edge: .bottom))
                }
            }
            .clipped()
            Divider()
            PlaybackControlsView()
        }
        .safeAreaInset(edge: .top) {
            ToolbarView()
        }
        .sidePanel(isPresented: $viewModel.drawerIsPresented) {
            SidePanelView()
        }
        .onOpenURL { url in
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               components.scheme == "verbarhythm",
               let queryItems = components.queryItems,
               let text = queryItems.first(where: { $0.name == "sharedText" })?.value {
                viewModel.phraseText = text
                viewModel.focusedField = false
            }
        }
        .onAppear {
            viewModel.focusedField = true
            viewModel.loadHistory()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
