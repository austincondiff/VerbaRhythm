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
        if #available(iOS 17.0, *) {
            content
#if !os(macOS)
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
#endif
        } else {
            content
                .sheet(isPresented: $viewModel.settingsSheetIsPresented) {
                    SettingsForm()
                }
        }
    }

    var textEntry: some View {
        VStack(spacing: 0) {
            if wordDisplayIsPresented {
                Divider()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            TextEntryView()
                .clipped()
#if !os(macOS)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if wordDisplayIsPresented {
                        VStack(spacing: 0) {
                            Divider()
                            PlaybackControlsView()
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
#endif
        }
        .transition(.move(edge: .bottom))
    }

    var content: some View {
        VStack(spacing: 0) {
            if wordDisplayIsPresented {
                WordDisplayView()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
#if !os(macOS)
            if !viewModel.isFullScreen && !viewModel.settingsSheetIsPresented {
                textEntry
            }
#else
            if !viewModel.isFullScreen {
                textEntry
            }
#endif
        }
        .clipped()
#if !os(macOS)
        .safeAreaInset(edge: .top) {
            ToolbarView()
        }
        .sidePanel(isPresented: $viewModel.drawerIsPresented) {
            SidePanelView()
        }
#else
        .background(Color(.textBackgroundColor))
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
#if os(macOS)
        .onAppear {
            viewModel.addNewEntry()
        }
        .onChange(of: viewModel.selectedHistoryEntries) { newValue in
            viewModel.history.removeAll { entry in
                entry.text.isEmpty && !viewModel.selectedHistoryEntries.contains(where: { $0 == entry.id })
            }
        }
#else
        .onChange(of: viewModel.focusedField) { newValue in
            withAnimation {
                wordDisplayIsPresented = !newValue
            }
        }
#endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
