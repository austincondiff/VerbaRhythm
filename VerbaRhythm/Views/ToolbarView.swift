//
//  ToolbarView.swift
//  Verbarhythm
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
            if !viewModel.phraseText.isEmpty {
                Button {
                    viewModel.focusedField = false
                    withAnimation {
                        viewModel.isFullScreen.toggle()
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
            }
            Menu {
                Button {
                    viewModel.currentIndex = 0
                } label: {
                    Label("Go to beginning", systemImage: "arrow.counterclockwise")
                }
                Button {
                    viewModel.currentIndex = viewModel.words.count - 1
                }  label: {
                    Label("Go to end", systemImage: "arrow.clockwise")
                }

                Divider()

                Toggle(isOn: $viewModel.showGhostText) {
                    Label("Ghost Text", systemImage: "eyes")
                }

                Divider()

                Picker(selection: $viewModel.speedMultiplier) {
                    ForEach(viewModel.speedOptions, id: \.self) { speed in
                        Text(String(format: "%.2fx", speed))
                            .tag(speed)
                    }
                } label: {
                    Label(title: {
                        Text("Speed")
                        Text(String(format: "%.2fx", viewModel.speedMultiplier))
                    }, icon: {
                        Image(systemName: "hare.fill")
                    })
                }
                .pickerStyle(.menu)
                Toggle(isOn: $viewModel.isDynamicSpeedOn) {
                    Label("Dynamic Speed", systemImage: "speedometer")
                }
                Divider()
                Button(role: .destructive) {
                    viewModel.phraseText = ""
                    viewModel.focusedField = true
                }  label: {
                    Label("Delete all text", systemImage: "delete.left.fill")
                }
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
            .help("More")
            if viewModel.focusedField {
                Button {
                    viewModel.focusedField = false
                } label: {
                    Text("Done")
                        .bold()
                        .font(.system(size: 17, weight: .semibold))
                }
                .help("Done")
            }
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 22, weight: .regular))
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
}

#Preview {
    ToolbarView()
}
