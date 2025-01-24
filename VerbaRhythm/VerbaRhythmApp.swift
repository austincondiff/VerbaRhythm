//
//  VerbaRhythmApp.swift
//  VerbaRhythm
//
//  Created by Austin Condiff on 9/21/23.
//

import SwiftUI

@main
struct VerbaRhythmApp: App {
    @StateObject var settings: SettingsViewModel
    @StateObject var viewModel: ContentViewModel

    init() {
        let settings = SettingsViewModel()
        _settings = StateObject(wrappedValue: settings)
        _viewModel = StateObject(wrappedValue: ContentViewModel(settings: settings))
    }

    var window: some View {
        NavigationSplitView(columnVisibility: $viewModel.columnVisibility, sidebar: {
            SidePanelView()
                .environmentObject(viewModel)
                .environmentObject(settings)
        }, detail: {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(settings)
            #if os(macOS)
                .toolbar {
                    ToolbarItem(id: "new", placement: .navigation) {
                        Button {
                            viewModel.addNewEntry()
                        } label: {
                            Label("New", systemImage: "square.and.pencil")
                                .labelStyle(.iconOnly)
                        }
                        .disabled(viewModel.phraseText == "")
                    }
                    ToolbarItem(id: "playbackControls", placement: .secondaryAction) {
                        HStack(spacing: 0) {
                            Button {
                                viewModel.focusedField = false
                                if viewModel.isPlaying { viewModel.pause() }
                                viewModel.toBeginning()
                            } label: {
                                Label("Beginning", systemImage: "backward.end.fill")
                                    .labelStyle(.iconOnly)
                                    .scaleEffect(0.75)
                            }
                            .keyboardShortcut(.leftArrow, modifiers: viewModel.focusedField ? [.control, .command] : .command)
                            .disabled(viewModel.words.count == 0 || viewModel.currentIndex == 0)
                            Button {
                                viewModel.prev()
                            } label: {
                                Label("Previous", systemImage: "backward.fill")
                                    .labelStyle(.iconOnly)
                            }
                            .keyboardShortcut(.leftArrow, modifiers: viewModel.focusedField ? .control : [])
                            .disabled(viewModel.words.count == 0 || viewModel.currentIndex == 0)
                            Button {
                                viewModel.togglePlayback()
                            } label: {
                                Label(viewModel.isPlaying ? "Pause" : "Play", systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                    .labelStyle(.iconOnly)
                                    .scaleEffect(1.25)
                                    .frame(width: 24)
                            }
                            .disabled(viewModel.words.count == 0 || viewModel.currentIndex == viewModel.words.count-1)
                            Button {
                                viewModel.next()
                            } label: {
                                Label("Next", systemImage: "forward.fill")
                                    .labelStyle(.iconOnly)
                            }
                            .keyboardShortcut(.rightArrow, modifiers: viewModel.focusedField ? .control : [])
                            .disabled(viewModel.words.count == 0 || viewModel.currentIndex == viewModel.words.count-1)
                            Button {
                                viewModel.toEnd()
                            } label: {
                                Label("End", systemImage: "forward.end.fill")
                                    .labelStyle(.iconOnly)
                                    .scaleEffect(0.75)
                            }
                            .keyboardShortcut(.rightArrow, modifiers: viewModel.focusedField ? [.control, .command] : .command)
                            .disabled(viewModel.words.count == 0 || viewModel.currentIndex == viewModel.words.count-1)
                        }
                    }
                    ToolbarItem(id: "spacer", placement: .automatic) {
                        Spacer()
                    }
                    if viewModel.focusedField == true {
                        ToolbarItem(id: "stopEditing", placement: .primaryAction) {
                            Button {
                                handleDoneEditing()
                            } label: {
                                Text("Done")
                                    .padding(.horizontal, 5)
                            }
                            .keyboardShortcut(.return, modifiers: .command)
                            .onAppear {
                                NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                                    if event.keyCode == 53 { // 53 is the keyCode for Escape
                                        handleDoneEditing()
                                        return nil // Returning nil stops the key press from propagating further
                                    }
                                    return event // Continue with other events
                                }
                            }
                        }
                    }
                    ToolbarItem(id: "fullscreen", placement: .primaryAction) {
                        Button {
                            withAnimation {
                                viewModel.isFullScreen.toggle()
                            }
                        } label: {
                            Label("Fullscreen", systemImage: viewModel.isFullScreen ? "arrow.down.forward.and.arrow.up.backward" : "arrow.up.backward.and.arrow.down.forward")
                                .labelStyle(.iconOnly)
                        }
                    }
                }
            #endif
        })
        .navigationTitle("")
    }

    func handleDoneEditing() {
        viewModel.focusedField = false

        if viewModel.phraseText.isEmpty {
            if let entryID = viewModel.selectedHistoryEntries.first {
                viewModel.deleteHistoryEntries(historyEntries: Set([entryID]))
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(settings)
        }
        .modelContainer(for: Entry.self)
    }
}
