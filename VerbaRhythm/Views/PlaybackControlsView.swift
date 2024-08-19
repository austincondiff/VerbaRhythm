//
//  PlaybackControlsView.swift
//  Verbarhythm
//
//  Created by Austin Condiff on 8/18/24.
//

import SwiftUI

struct PlaybackControlsView: View {
    @EnvironmentObject var viewModel: ContentViewModel

    var body: some View {
        HStack {
            Button {
                viewModel.pause()
                viewModel.prev()
            } label: {
                Label(title: {
                    Text("Previous")
                }, icon: {
                    Image(systemName: "backward.fill")
                        .frame(height: 20)
                })
                .labelStyle(.iconOnly)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(viewModel.currentIndex == 0 || viewModel.words.count == 0)
            .keyboardShortcut(.leftArrow, modifiers: [])
            ZStack {
                if (viewModel.isPlaying) {
                    Button {
                        withAnimation {
                            viewModel.pause()
                        }
                    } label: {
                        Label(title: {
                            Text("Pause")
                        }, icon: {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 24))
                                .frame(height: 20)
                        })
                        .transition(.scale)
                        .labelStyle(.iconOnly)
                        .frame(maxWidth: .infinity)
                        .opacity(0)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                } else {
                    Button {
                        if viewModel.atEnd() {
                            viewModel.toBeginning()
                        } else {
                            withAnimation {
                                viewModel.play()
                            }
                        }
                    } label: {
                        Label(title: {
                            Text(viewModel.words.count > 1 && viewModel.atEnd() ? "Restart" : "Play")
                        }, icon: {
                            Image(systemName: viewModel.words.count > 1 && viewModel.atEnd() ? "arrow.counterclockwise" : "play.fill")
                                .font(.system(size: 24))
                                .frame(height: 20)
                        })
                        .transition(.scale)
                        .labelStyle(.iconOnly)
                        .frame(maxWidth: .infinity)
                        .opacity(0)
                    }
                    .disabled(viewModel.words.count == 0)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.space, modifiers: [])
                }
                Group {
                    if #available(iOS 17, *) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : viewModel.words.count > 1 && viewModel.atEnd() ? "arrow.counterclockwise" : "play.fill")
                            .contentTransition(.symbolEffect(.replace))
                    } else {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : viewModel.words.count > 1 && viewModel.atEnd() ? "arrow.counterclockwise" : "play.fill")
                    }
                }
                .font(.system(size: 24))
                .frame(height: 20)
                .foregroundStyle(viewModel.words.isEmpty ? Color(.quaternaryLabel) : viewModel.isPlaying ? Color(.tintColor) : Color(.white))
            }

            Button {
                viewModel.pause()
                viewModel.next()
            } label: {
                Label(title: {
                    Text("Next")
                }, icon: {
                    Image(systemName: "forward.fill")
                        .frame(height: 20)
                })
                .labelStyle(.iconOnly)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(viewModel.currentIndex == viewModel.words.count - 1 || viewModel.words.count == 0)
            .keyboardShortcut(.rightArrow, modifiers: [])
        }
        .padding()
    }
}

#Preview {
    PlaybackControlsView()
}
