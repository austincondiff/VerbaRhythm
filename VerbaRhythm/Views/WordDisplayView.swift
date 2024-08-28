//
//  WordDisplayView.swift
//  Verbarhythm
//
//  Created by Austin Condiff on 8/18/24.
//

import SwiftUI

struct WordDisplayView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    @EnvironmentObject var settings: SettingsViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                if viewModel.phraseText.isEmpty {
                    Image(systemName: "waveform")
                        .opacity(0.25)
                        .font(.system(size: 64))
                } else {
                    if viewModel.words.count != 0 {
                        Text(viewModel.words.count > 0 && viewModel.words.count >= viewModel.currentIndex+1 ? viewModel.words[viewModel.currentIndex] : " ")
                            .overlay(alignment: .bottom) {
                                if settings.showGuides {
                                    Rectangle()
                                        #if os(macOS)
                                        .fill(Color(.separatorColor))
                                        #else
                                        .fill(Color(.separator))
                                        #endif
                                        .frame(width: 1, height: viewModel.currentWordSize.height)
                                        .offset(y: -viewModel.currentWordSize.height*1.5)
                                }
                            }
                            .overlay(alignment: .top) {
                                if settings.showGuides {
                                    Rectangle()
                                        #if os(macOS)
                                        .fill(Color(.separatorColor))
                                        #else
                                        .fill(Color(.separator))
                                        #endif
                                        .frame(width: 1, height: viewModel.currentWordSize.height)
                                        .offset(y: viewModel.currentWordSize.height*1.5)
                                }
                            }
                            .background(
                                GeometryReader { geo in
                                    Color.clear.onAppear {
                                        viewModel.currentWordSize = geo.size
                                    }
                                    .onChange(of: viewModel.words[viewModel.currentIndex]) { _ in
                                        viewModel.currentWordSize = geo.size
                                    }
                                    .onChange(of: settings.fontStyle) { _ in viewModel.currentWordSize = geo.size }
                                    .onChange(of: settings.fontSize) { _ in viewModel.currentWordSize = geo.size }
                                    .onChange(of: settings.fontWeight) { _ in viewModel.currentWordSize = geo.size }
                                    .onChange(of: settings.fontWidth) { _ in viewModel.currentWordSize = geo.size }
                                }
                            )
                            .truncationMode(.middle)
                    }
                    if settings.showGhostText && viewModel.words.count > 1 && viewModel.currentIndex > 0 {
                        Text(viewModel.getPreviousWords())
                            .background(
                                GeometryReader { geo in
                                    Color.clear.onAppear {
                                        viewModel.prevWordSize = geo.size
                                    }
                                    .onChange(of: viewModel.words[viewModel.currentIndex - 1]) { _ in
                                        viewModel.prevWordSize = geo.size
                                    }
                                    .onChange(of: settings.fontStyle) { _ in viewModel.prevWordSize = geo.size }
                                    .onChange(of: settings.fontSize) { _ in viewModel.prevWordSize = geo.size }
                                    .onChange(of: settings.fontWeight) { _ in viewModel.prevWordSize = geo.size }
                                    .onChange(of: settings.fontWidth) { _ in viewModel.prevWordSize = geo.size }
                                }
                            )
                            .opacity(0.33)
                            .offset(x: -(viewModel.currentWordSize.width / 2 + viewModel.prevWordSize.width / 2))
                            .truncationMode(.head)
                    }
                    if settings.showGhostText && viewModel.words.count > 1 && viewModel.currentIndex < viewModel.words.count - 1 {
                        Text(viewModel.getNextWords())
                            .background(
                                GeometryReader { geo in
                                    Color.clear.onAppear {
                                        viewModel.nextWordSize = geo.size
                                    }
                                    .onChange(of: viewModel.words[viewModel.currentIndex + 1]) { _ in
                                        viewModel.nextWordSize = geo.size
                                    }
                                    .onChange(of: settings.fontStyle) { _ in viewModel.nextWordSize = geo.size }
                                    .onChange(of: settings.fontSize) { _ in viewModel.nextWordSize = geo.size }
                                    .onChange(of: settings.fontWeight) { _ in viewModel.nextWordSize = geo.size }
                                    .onChange(of: settings.fontWidth) { _ in viewModel.nextWordSize = geo.size }
                                }
                            )
                            .opacity(0.33)
                            .offset(x: viewModel.currentWordSize.width / 2 + viewModel.nextWordSize.width / 2)
                            .truncationMode(.tail)
                    }
                }
            }
            .font(settings.fontStyle.toFont(size: settings.fontSize, weight: settings.fontWeight, width: settings.fontWidth))
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .padding()
            Spacer()
        }
        .padding(.bottom, viewModel.settingsSheetIsPresented ? viewModel.sheetHeight : 0)
        .mask(fadeMask())
        .contentShape(Rectangle())
        .overlay {
            if !viewModel.drawerIsPresented && !viewModel.words.isEmpty {
                Rectangle()
                    .opacity(0.0001)
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                viewModel.handleWordDisplayDragChanged(value)
                            }
                            .onEnded { value in
                                viewModel.handleWordDisplayDragEnded(value)
                            }
                    )
                    .padding(.horizontal, 50)
            }
        }
    }

    func fadeMask() -> some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.1),
                .init(color: .black, location: 0.9),
                .init(color: .clear, location: 1)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

#Preview {
    WordDisplayView()
}
