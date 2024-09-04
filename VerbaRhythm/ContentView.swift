//
//  ContentView.swift
//  Verbarhythm
//
//  Created by Austin Condiff on 9/21/23.
//

import SwiftUI

struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


struct ContentView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    @State var wordDisplayIsPresented = true

    var body: some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            content
                .inspector(isPresented: $viewModel.settingsSheetIsPresented) {
                    SettingsForm()
                        .overlay {
                            GeometryReader { geometry in
                                Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
                            }
                        }
                        .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
                            viewModel.sheetHeight = newHeight
                        }
                }
        } else {
            content
                .sheet(isPresented: $viewModel.settingsSheetIsPresented) {
                    SettingsForm()
                }
        }
    }

    var content: some View {
        VStack(spacing: 0) {
            if !wordDisplayIsPresented {
                WordDisplayView()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if !viewModel.isFullScreen && !viewModel.settingsSheetIsPresented {
                VStack(spacing: 0) {
                    Divider()
                    TextEntryView()
                        .clipped()
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            VStack(spacing: 0) {
                                Divider()
                                PlaybackControlsView()
                            }
                        }
                }
                .transition(.move(edge: .bottom))
            }
        }
        .clipped()
        .safeAreaInset(edge: .top) {
            ToolbarView()
        }
        #if os(iOS)
        .sidePanel(isPresented: $viewModel.drawerIsPresented) {
            SidePanelView()
        }
        #endif
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
        .onChange(of: viewModel.focusedField) { newValue in
            withAnimation {
                wordDisplayIsPresented = newValue
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
