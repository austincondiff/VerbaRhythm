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
#if os(macOS)
                TextEditorWithInsets(text: $viewModel.phraseText, insets: CGSize(width: 24, height: 24), currentWordIndex: viewModel.currentIndex, viewModel: viewModel)
                    .focused($isFieldFocused, equals: true)
                    .frame(height: proxy.size.height)
//                    .padding(24)
                    .font(.body)
                    .background(Color(.textBackgroundColor))
#else
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        VStack {

                            placeholder
                                .background {
                                    textEditor
                                        .padding(.vertical, -8)
                                }
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
#endif
            }
        }
        .onChange(of: isFieldFocused) { newValue in
            if newValue != viewModel.focusedField {
                viewModel.focusedField = newValue
            }
        }
        .onChange(of: viewModel.focusedField) { newValue in
            if newValue != isFieldFocused {
                isFieldFocused = newValue
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
#if !os(macOS)
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
#endif
    var highlightedPlaceholder: some View {
        var result = Text("")

        let parsedWords = viewModel.parseWords(from: viewModel.phraseText)
        var wordIndex = 0

        for parsedWord in parsedWords {
            if !parsedWord.isSeparator {
                let highlightedWord = Text(parsedWord.word)
                    .foregroundColor(viewModel.currentIndex == wordIndex ? Color.accentColor : Color.primary)
                result = result + highlightedWord
                wordIndex += 1
            } else {
                result = result + Text(parsedWord.word)
            }
        }

        return result
    }

    private func updateCurrentWord(at position: Int) {
        let parsedWords = viewModel.parseWords(from: viewModel.phraseText)
        var currentCharacterCount = 0
        var wordIndex = 0

        for parsedWord in parsedWords {
            let wordLength = parsedWord.word.count

            if !parsedWord.isSeparator {
                if position <= currentCharacterCount + wordLength {
                    viewModel.currentIndex = wordIndex
                    return
                }
                wordIndex += 1
            }
            currentCharacterCount += wordLength
        }

        viewModel.currentIndex = wordIndex
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
struct TextEditorWithInsets: NSViewRepresentable {
    @Binding var text: String
    var insets: NSSize
    var currentWordIndex: Int
    var viewModel: ContentViewModel

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TextEditorWithInsets
        var previousText: String
        var isFocused: Bool = false
        var externalUpdateInProgress = false

        init(_ parent: TextEditorWithInsets) {
            self.parent = parent
            self.previousText = parent.text
        }

        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                let undoManager = textView.undoManager

                // Register undo
                undoManager?.registerUndo(withTarget: self, handler: { target in
                    target.performUndoRedo(textView)
                })

                undoManager?.setActionName("Typing")

                previousText = textView.string
                parent.text = textView.string

                // Ensure currentWordIndex is updated safely
                if !externalUpdateInProgress && isFocused {
                    updateCurrentWordIndex(for: textView.selectedRange().location, in: textView.string)
                }
            }
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard !externalUpdateInProgress else { return }

            if let textView = notification.object as? NSTextView, isFocused {
                let cursorPosition = textView.selectedRange().location
                updateCurrentWordIndex(for: cursorPosition, in: textView.string)
            }
        }

        private func updateCurrentWordIndex(for cursorPosition: Int, in text: String) {
            let parsedWords = parent.viewModel.parseWords(from: text)
            guard !parsedWords.isEmpty else {
                parent.viewModel.currentIndex = 0
                return
            }

            var currentCharacterCount = 0
            var wordIndex = 0

            // Safeguard against out-of-range errors by ensuring we stay within bounds
            for parsedWord in parsedWords {
                let wordLength = parsedWord.word.count

                if !parsedWord.isSeparator {
                    if cursorPosition <= currentCharacterCount + wordLength {
                        // Ensure wordIndex doesn't exceed the number of words
                        parent.viewModel.currentIndex = min(wordIndex, parsedWords.count - 1)
                        return
                    }
                    wordIndex += 1
                }

                // If the cursor is at the last separator, keep currentWordIndex at the last word
                if parsedWord.isSeparator && cursorPosition == currentCharacterCount + wordLength {
                    parent.viewModel.currentIndex = min(wordIndex - 1, parsedWords.count - 1)
                    return
                }

                currentCharacterCount += wordLength
            }

            // If the cursor is at the end of the text and there are trailing separators, set to the last word
            parent.viewModel.currentIndex = min(wordIndex - 1, parsedWords.count - 1)
        }

        func performUndoRedo(_ textView: NSTextView) {
            let currentText = textView.string
            textView.string = previousText
            parent.text = previousText
            previousText = currentText
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class CustomTextView: NSTextView {
        var onFocusChange: ((Bool) -> Void)?

        override func becomeFirstResponder() -> Bool {
            let becameFirstResponder = super.becomeFirstResponder()
            if becameFirstResponder {
                onFocusChange?(true)
            }
            return becameFirstResponder
        }

        override func resignFirstResponder() -> Bool {
            let resignedFirstResponder = super.resignFirstResponder()
            if resignedFirstResponder {
                onFocusChange?(false)
                clearSelection() // Clear the selection when focus is lost
            }
            return resignedFirstResponder
        }

        // Helper function to clear any selection or text state
        private func clearSelection() {
            if let selectedRange = selectedRanges.first as? NSRange, selectedRange.length > 0 {
                setSelectedRange(NSRange(location: selectedRange.location, length: 0))
            }
        }
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = CustomTextView()
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.backgroundColor = .clear
        textView.textContainerInset = insets
        textView.delegate = context.coordinator
        textView.allowsUndo = true

        textView.onFocusChange = { isFocused in
            context.coordinator.isFocused = isFocused
            if isFocused {
                context.coordinator.externalUpdateInProgress = false
            }
        }

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.documentView = textView
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        textView.minSize = NSSize(width: 0, height: scrollView.contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? NSTextView {
            // Update text content only if it changed externally
            if textView.string != text {
                context.coordinator.externalUpdateInProgress = true
                textView.string = text
                context.coordinator.externalUpdateInProgress = false

                // Only update currentWordIndex if it's meaningful, such as when the text editor is not focused and
                // currentIndex is out of bounds (e.g., due to text length changes)
                let parsedWords = viewModel.parseWords(from: text)

                if !context.coordinator.isFocused && (viewModel.currentIndex >= parsedWords.count) {
                    viewModel.currentIndex = max(parsedWords.count - 1, 0) // Set to the last valid word, or 0 if empty
                }
            }

            // Remove highlighting when focused
            if context.coordinator.isFocused {
                let fullRange = NSRange(location: 0, length: text.count)
                textView.textStorage?.removeAttribute(.foregroundColor, range: fullRange)
                textView.textStorage?.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
            } else {
                highlightCurrentWord(in: textView)
            }
        }
    }

    private func highlightCurrentWord(in textView: NSTextView) {
        let parsedWords = viewModel.parseWords(from: text)
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        textView.textStorage?.removeAttribute(.foregroundColor, range: fullRange)
        textView.textStorage?.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)

        var wordIndex = 0

        for parsedWord in parsedWords {
            guard !parsedWord.isSeparator else { continue }

            let nsRange = NSRange(parsedWord.range, in: text)
            if wordIndex == currentWordIndex {
                textView.textStorage?.addAttribute(.foregroundColor, value: NSColor.controlAccentColor, range: nsRange)
            }
            wordIndex += 1
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
