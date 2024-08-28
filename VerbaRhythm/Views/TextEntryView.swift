//
//  TextEntryView.swift
//  Verbarhythm
//
//  Created by Austin Condiff on 8/18/24.
//

import SwiftUI

struct ScrollContentHeightPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct TextEntryView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    @FocusState private var isFieldFocused: Bool
    @State private var cursorPosition: Int = 0

    var body: some View {
        VStack(spacing: 0) {
//            Divider()

            GeometryReader { proxy in
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        VStack {
#if os(macOS)
                            placeholder
                                .overlay {
                                    textEditor
                                }
#else
                            placeholder
                                .background {
                                    textEditor
                                        .padding(.vertical, -8)
                                }
#endif
                        }
                        .id("textContent")
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(key: ScrollContentHeightPreferenceKey.self, value: geometry.size.height)
                            }
                        )
                    }
                    .onAppear {
                        viewModel.scrollViewProxy = scrollViewProxy
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .disabled(viewModel.drawerIsPresented || viewModel.dragOffset != 0)
                    .onTapGesture {
                        if !viewModel.drawerIsPresented {
                            viewModel.focusedField = true
                        }
                    }
                    .onPreferenceChange(ScrollContentHeightPreferenceKey.self) { height in
                        viewModel.scrollContentHeight = height
                    }
                    .task {
                        viewModel.scrollViewHeight = proxy.size.height
                    }
                }
            }
        }
        .onChange(of: isFieldFocused) { newValue in
            isFieldFocused = viewModel.focusedField
            print("self changed: \(newValue)")
        }
        .onChange(of: viewModel.focusedField) { newValue in
            if newValue != isFieldFocused {
                isFieldFocused = newValue
                print("vm changed: \(newValue)")
            }
        }
        .onChange(of: cursorPosition) { newPosition in
            updateCurrentWord(at: newPosition)
        }
        .onChange(of: viewModel.currentIndex) { newIndex in
            updateCursorPosition(for: newIndex)
            withAnimation {
                viewModel.scrollToCurrentWord()
            }
        }
    }

    var textEditor: some View {
        TextEditorWithCursor(text: $viewModel.phraseText, cursorPosition: $cursorPosition)
            .focused($isFieldFocused, equals: true)
            .font(.body)
            .foregroundColor(.primary)
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top)
            .padding(.horizontal)
            .padding(.horizontal, -5)
    }

    var placeholder: some View {
        HStack {
            if viewModel.phraseText.isEmpty {
                Text("Enter text...")
                    .opacity(0.5)
            } else {
                highlightedPlaceholder
                    .allowsHitTesting(false)
                    .opacity(isFieldFocused ? 0 : 1)
            }
        }
        .font(.body)
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
    }

    var highlightedPlaceholder: some View {
        var result = Text("")
        let regex = try! NSRegularExpression(pattern: "[ \t\n—]+", options: [])

        var wordIndex = 0
        var currentPosition = 0

        let fullText = viewModel.phraseText as NSString
        let matches = regex.matches(in: viewModel.phraseText, options: [], range: NSRange(location: 0, length: fullText.length))

        for match in matches {
            let range = NSRange(location: currentPosition, length: match.range.location - currentPosition)
            let word = fullText.substring(with: range)
            let separator = fullText.substring(with: match.range)

            if !word.isEmpty {
                let highlightedWord = Text(word)
                    .foregroundColor(viewModel.currentIndex == wordIndex ? Color.accentColor : Color.primary)
                result = result + highlightedWord
                wordIndex += 1
            }

            result = result + Text(separator)
            currentPosition = match.range.location + match.range.length
        }

        // Append the remaining text after the last separator
        let remainingRange = NSRange(location: currentPosition, length: fullText.length - currentPosition)
        if remainingRange.length > 0 {
            let remainingText = fullText.substring(with: remainingRange)
            let highlightedWord = Text(remainingText)
                .foregroundColor(viewModel.currentIndex == wordIndex ? Color.accentColor : Color.primary)

            result = result + highlightedWord
        }

        return result
    }

    private func updateCurrentWord(at position: Int) {
        let regex = try! NSRegularExpression(pattern: "[ \t\n—]+", options: [])
        let fullText = viewModel.phraseText as NSString

        var currentCharacterCount = 0
        var wordIndex = 0

        let matches = regex.matches(in: viewModel.phraseText, options: [], range: NSRange(location: 0, length: fullText.length))

        for match in matches {
            let range = NSRange(location: currentCharacterCount, length: match.range.location - currentCharacterCount)

            // If cursor is in between a set of matched characters do not change word
            if position > match.range.location && position < match.range.location + match.range.length {
                return
            }

            if position < match.range.location {
                viewModel.currentIndex = wordIndex
                return
            } else if position == match.range.location {
                // Cursor is directly on a separator
                viewModel.currentIndex = wordIndex
                return
            }

            currentCharacterCount = match.range.location + match.range.length
            wordIndex += 1
        }

        // If the cursor is beyond the last separator, set to the last word
        if wordIndex < viewModel.words.count {
            viewModel.currentIndex = wordIndex
        }
    }

    private func updateCursorPosition(for wordIndex: Int) {
        let regex = try! NSRegularExpression(pattern: "[ \t\n—]+", options: [])
        let fullText = viewModel.phraseText as NSString

        var currentWordIndex = 0

        let matches = regex.matches(in: viewModel.phraseText, options: [], range: NSRange(location: 0, length: fullText.length))

        for match in matches {
            if currentWordIndex == wordIndex {
                if (cursorPosition < match.range.location - viewModel.words[currentWordIndex].count || cursorPosition > match.range.location) {
                    cursorPosition = match.range.location // Set to the end of the current word
                }
                return
            }
            currentWordIndex += 1
        }

        // If the word index is beyond the last word, set the cursor at the end of the text
        cursorPosition = fullText.length
    }
}

#if os(macOS)
struct TextEditorWithCursor: NSViewRepresentable {
    @Binding var text: String
    @Binding var cursorPosition: Int

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()

        scrollView.hasVerticalScroller = true
        scrollView.documentView = textView

        textView.delegate = context.coordinator
        textView.font = NSFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakStrategy = .pushOut

        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: text.count))
        attributedString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: NSRange(location: 0, length: text.count))

        textView.textStorage?.setAttributedString(attributedString)

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakStrategy = .pushOut

        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: text.count))
        attributedString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: NSRange(location: 0, length: text.count))

        textView.textStorage?.setAttributedString(attributedString)
        textView.font = NSFont.preferredFont(forTextStyle: .body)

        setCursorPosition(in: textView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func setCursorPosition(in textView: NSTextView) {
        let location = NSRange(location: cursorPosition, length: 0)
        textView.setSelectedRange(location)
        textView.scrollRangeToVisible(location)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TextEditorWithCursor

        init(_ parent: TextEditorWithCursor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let selectedRange = textView.selectedRange()
            if selectedRange.length == 0 {
                parent.cursorPosition = selectedRange.location
            }
        }
    }
}
#else
struct TextEditorWithCursor: UIViewRepresentable {
    @Binding var text: String
    @Binding var cursorPosition: Int

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakStrategy = .pushOut

        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: text.count))
        attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: text.count))

        textView.attributedText = attributedString

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakStrategy = .pushOut

        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: text.count))
        attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: text.count))

        uiView.attributedText = attributedString
        uiView.font = UIFont.preferredFont(forTextStyle: .body)

        setCursorPosition(in: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func setCursorPosition(in textView: UITextView) {
        let position = textView.position(from: textView.beginningOfDocument, offset: cursorPosition) ?? textView.endOfDocument
        textView.selectedTextRange = textView.textRange(from: position, to: position)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextEditorWithCursor

        init(_ parent: TextEditorWithCursor) {
            self.parent = parent
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            if let selectedRange = textView.selectedTextRange {
                if selectedRange.start == selectedRange.end {
                    let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
                    parent.cursorPosition = cursorPosition
                }
            }
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}
#endif

#Preview {
    TextEntryView()
}
