//
//  WordDisplayView.swift
//  Verbarhythm
//
//  Created by Austin Condiff on 8/18/24.
//

import SwiftUI

struct WordDisplayView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Group {
                if viewModel.phraseText.isEmpty {
                    Image(systemName: "waveform")
                        .opacity(0.25)
                        .font(.system(size: 64))
                } else {
                    ZStack {
                        if viewModel.words.count != 0 {
                            Text(viewModel.words.count > 0 ? viewModel.words[viewModel.currentIndex] : " ")
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear.onAppear {
                                                viewModel.currentWordSize = geo.size
                                            }
                                            .onChange(of: viewModel.words[viewModel.currentIndex]) { newValue in
                                                viewModel.currentWordSize = geo.size
                                                DispatchQueue.main.async {
                                                    viewModel.currentWordSize = geo.size
                                                }
                                            }
                                            .onChange(of: viewModel.phraseText) { _ in
                                                DispatchQueue.main.async {
                                                    viewModel.currentWordSize = geo.size
                                                }
                                            }
                                        }
                                    )
                                    .truncationMode(.middle)
                            }
                        if viewModel.showGhostText && viewModel.words.count > 1 && viewModel.currentIndex > 0 {
                            Text(viewModel.getPreviousWords())
                                .background(
                                    GeometryReader { geo in
                                        Color.clear.onAppear {
                                            viewModel.prevWordSize = geo.size
                                        }
                                        .onChange(of: viewModel.words[viewModel.currentIndex - 1]) { newValue in
                                            viewModel.prevWordSize = geo.size
                                            DispatchQueue.main.async {
                                                viewModel.prevWordSize = geo.size
                                            }
                                        }
                                        .onChange(of: viewModel.phraseText) { _ in
                                            DispatchQueue.main.async {
                                                viewModel.prevWordSize = geo.size
                                            }
                                        }
                                    }
                                )
                                .opacity(0.33)
                                .offset(x: -(viewModel.currentWordSize.width / 2 + viewModel.prevWordSize.width / 2))
                                .truncationMode(.head)
                            }
                        if viewModel.showGhostText && viewModel.words.count > 1 && viewModel.currentIndex < viewModel.words.count - 1 {
                                Text(viewModel.getNextWords())
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear.onAppear {
                                                viewModel.nextWordSize = geo.size
                                            }
                                            .onChange(of: viewModel.words[viewModel.currentIndex + 1]) { newValue in
                                                viewModel.nextWordSize = geo.size
                                                DispatchQueue.main.async {
                                                    viewModel.nextWordSize = geo.size
                                                }
                                            }
                                            .onChange(of: viewModel.phraseText) { _ in
                                                DispatchQueue.main.async {
                                                    viewModel.nextWordSize = geo.size
                                                }
                                            }
                                        }
                                    )
                                    .opacity(0.33)
                                    .offset(x: viewModel.currentWordSize.width / 2 + viewModel.nextWordSize.width / 2)
                                    .truncationMode(.tail)
                            }
                    }
                }
            }
            .font(.largeTitle)
            .fontWeight(.bold)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .padding()
//            .padding(.top, proxy.safeAreaInsets.top)
            Spacer()
        }
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
                                viewModel.handleWordDisplayDragEnded()
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
