//
//  ToolbarView.swift
//  VerbaRhythm
//
//  Created by Austin Condiff on 8/18/24.
//

import SwiftUI

struct ToolbarView: View {
    @EnvironmentObject var viewModel: ContentViewModel

    var body: some View {
        HStack(spacing: 28) {
            Button {
                viewModel.dragOffset = 0
                viewModel.drawerIsPresented.toggle()
            } label: {
                Label(
                    "Toggle Drawer",
                    systemImage: "list.bullet"
                )
            }
            .opacity(viewModel.drawerIsPresented ? 0 : 1)
            .help("Toggle Drawer")

            Spacer()

            if !viewModel.phraseText.isEmpty && !viewModel.focusedField {
                Button {
                    viewModel.focusedField = false
                    if viewModel.isKeyboardVisible {
                        // Wait for the keyboard to dismiss before toggling full screen
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak viewModel] in
                            withAnimation {
                                viewModel?.isFullScreen.toggle()
                            }
                        }
                    } else {
                        // Directly toggle full screen if the keyboard is not visible
                        withAnimation {
                            viewModel.isFullScreen.toggle()
                        }
                    }
                } label: {
                    Label(
                        "Toggle Full Screen",
                        systemImage: viewModel.isFullScreen
                        ? "arrow.down.right.and.arrow.up.left"
                        : "arrow.up.left.and.arrow.down.right"
                    )
                }
                .help("Toggle Full Screen")
//                .disabled(viewModel.focusedField)
            }

            if !viewModel.focusedField {
                MoreMenu()
            }

            if viewModel.focusedField {
                Button {
                    viewModel.focusedField = false
                } label: {
                    Text("Done")
                        .bold()
                        .font(.system(size: 17, weight: .semibold))
                }
                .help("Done")
                .disabled(viewModel.phraseText.isEmpty)
            }
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 22, weight: .regular))
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
        .onChange(of: viewModel.drawerIsPresented) { newValue in
            print("ToolbarView drawerIsPresented: \(newValue)")
        }
        .onChange(of: viewModel.isFullScreen) { newValue in
            if !newValue {
                Task {
                    viewModel.scrollToCurrentWord()
                }
            }
        }
    }
}

#Preview {
    ToolbarView()
}
