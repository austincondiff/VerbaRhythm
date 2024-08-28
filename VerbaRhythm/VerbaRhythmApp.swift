//
//  VerbarhythmApp.swift
//  Verbarhythm
//
//  Created by Austin Condiff on 9/21/23.
//

import SwiftUI

@main
struct VerbarhythmApp: App {
    @StateObject var settings: SettingsViewModel
    @StateObject var viewModel: ContentViewModel

    init() {
        let settings = SettingsViewModel()
        _settings = StateObject(wrappedValue: settings)
        _viewModel = StateObject(wrappedValue: ContentViewModel(settings: settings))
    }
    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            NavigationSplitView(sidebar: {
                SidePanelView()
                    .environmentObject(viewModel)
                    .environmentObject(settings)
                    .toolbar {
                        ToolbarItem(id: "play", placement: .primaryAction) {
                            Button {
                                viewModel.play()
                            } label: {
                                Label("Play", systemImage: "play.fill")
                                    .labelStyle(.iconOnly)
                            }
                        }
                        ToolbarItem(id: "inspector", placement: .primaryAction) {
                            Button {
                                viewModel.settingsSheetIsPresented.toggle()
                            } label: {
                                Label("Inspector", systemImage: "sidebar.right")
                                    .labelStyle(.iconOnly)
                            }
                        }
                    }
            }, detail: {
                ContentView()
                    .environmentObject(viewModel)
                    .environmentObject(settings)
            })
            .navigationTitle("")
        }
        #else
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(settings)
        }
        #endif
    }
}
