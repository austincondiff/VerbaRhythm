//
//  TextEntryView.swift
//  Verbarhythm
//
//  Created by Austin Condiff on 8/18/24.
//

import SwiftUI

struct TextEntryView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack {
            Divider()
            ScrollView {
#if os(macOS)
                placeholder
                    .overlay {
                        textEditor
                    }
#else
                placeholder
                    .padding(.horizontal, 5)
                    .overlay {
                        textEditor
                            .padding(.vertical, -8)
                            .padding(.horizontal, 5)
                    }
#endif

            }
            .disabled(viewModel.drawerIsPresented || viewModel.dragOffset != 0)
            .onTapGesture {
                if !viewModel.drawerIsPresented {
                    viewModel.focusedField = true
                }
            }
        }
        .onChange(of: isFieldFocused) { newValue in
            viewModel.focusedField = newValue
        }
        .onChange(of: viewModel.focusedField) { newValue in
            if newValue != isFieldFocused {
                isFieldFocused = newValue
            }
        }
//        .onAppear {
//            if viewModel.phraseText.isEmpty {
//                isFieldFocused = true
//            }
//        }
    }

    var textEditor: some View {
        TextEditor(text: $viewModel.phraseText)
            .focused($isFieldFocused, equals: true)
            .font(.body)
            .foregroundColor(.primary)
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .padding(.top)
            .padding(.horizontal)
            .padding(.horizontal, -5)
    }

    var placeholder: some View {
        Text(viewModel.phraseText.isEmpty ? "Enter phrase here..." : viewModel.phraseText)
            .font(.body)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(viewModel.phraseText.isEmpty ? 0.5 : 0)
            .padding()
    }
}

#Preview {
    TextEntryView()
}
