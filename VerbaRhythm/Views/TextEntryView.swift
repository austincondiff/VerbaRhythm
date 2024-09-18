//
//  TextEntryView.swift
//  VerbaRhythm
//
//  Created by Austin Condiff on 8/18/24.
//

import SwiftUI

struct TextEntryView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    @FocusState private var isFieldFocused: Bool

#if os(macOS)
    var textEditorInsets = CGSize(width: 24, height: 24)
#else
    var textEditorInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
#endif

    var body: some View {
        TextEditorWithInsets(
            text: $viewModel.phraseText,
            insets: textEditorInsets,
            currentWordIndex: viewModel.currentIndex,
            viewModel: viewModel
        )
        .focused($isFieldFocused, equals: true)
#if os(macOS)
        .background(Color(.textBackgroundColor))
#else
        .background(Color(UIColor.systemBackground))
#endif
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

            for parsedWord in parsedWords {
                let wordLength = parsedWord.word.count

                if !parsedWord.isSeparator {
                    if cursorPosition <= currentCharacterCount + wordLength {
                        parent.viewModel.currentIndex = min(wordIndex, parsedWords.count - 1)
                        return
                    }
                    wordIndex += 1
                }

                if parsedWord.isSeparator && cursorPosition == currentCharacterCount + wordLength {
                    parent.viewModel.currentIndex = min(wordIndex - 1, parsedWords.count - 1)
                    return
                }

                currentCharacterCount += wordLength
            }

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
                clearSelection()
            }
            return resignedFirstResponder
        }

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
            if textView.string != text {
                context.coordinator.externalUpdateInProgress = true
                textView.string = text
                context.coordinator.externalUpdateInProgress = false

                let parsedWords = viewModel.parseWords(from: text)

                if !context.coordinator.isFocused && (viewModel.currentIndex >= parsedWords.count) {
                    viewModel.currentIndex = max(parsedWords.count - 1, 0)
                }
            }

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
                textView.scrollRangeToVisible(nsRange)
            }
            wordIndex += 1
        }
    }
}
#elseif os(iOS)
struct TextEditorWithInsets: UIViewRepresentable {
    @Binding var text: String
    var insets: UIEdgeInsets
    var currentWordIndex: Int
    var viewModel: ContentViewModel

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextEditorWithInsets
        var previousText: String
        var isFocused: Bool = false
        var externalUpdateInProgress = false

        init(_ parent: TextEditorWithInsets) {
            self.parent = parent
            self.previousText = parent.text
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            isFocused = true
            externalUpdateInProgress = false
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            isFocused = false
        }

        func textViewDidChange(_ textView: UITextView) {
            previousText = textView.text
            parent.text = textView.text

            if !externalUpdateInProgress && isFocused {
                updateCurrentWordIndex(for: textView.selectedRange.location, in: textView.text)
            }
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !externalUpdateInProgress else { return }

            if isFocused {
                let cursorPosition = textView.selectedRange.location
                updateCurrentWordIndex(for: cursorPosition, in: textView.text)
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

            for parsedWord in parsedWords {
                let wordLength = parsedWord.word.count

                if !parsedWord.isSeparator {
                    if cursorPosition <= currentCharacterCount + wordLength {
                        parent.viewModel.currentIndex = min(wordIndex, parsedWords.count - 1)
                        return
                    }
                    wordIndex += 1
                }

                if parsedWord.isSeparator && cursorPosition == currentCharacterCount + wordLength {
                    parent.viewModel.currentIndex = min(wordIndex - 1, parsedWords.count - 1)
                    return
                }

                currentCharacterCount += wordLength
            }

            parent.viewModel.currentIndex = min(wordIndex - 1, parsedWords.count - 1)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.isScrollEnabled = true
        textView.textContainerInset = insets
        
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            context.coordinator.externalUpdateInProgress = true
            uiView.text = text
            context.coordinator.externalUpdateInProgress = false

            let parsedWords = viewModel.parseWords(from: text)

            if !context.coordinator.isFocused && (viewModel.currentIndex >= parsedWords.count) {
                viewModel.currentIndex = max(parsedWords.count - 1, 0)
            }
        }

        if context.coordinator.isFocused {
            let fullRange = NSRange(location: 0, length: text.count)
            uiView.textStorage.removeAttribute(.foregroundColor, range: fullRange)
            uiView.textStorage.addAttribute(.foregroundColor, value: UIColor.label, range: fullRange)
        } else {
            highlightCurrentWord(in: uiView)
        }
    }

    private func highlightCurrentWord(in textView: UITextView) {
        let parsedWords = viewModel.parseWords(from: text)
        let attributedString = NSMutableAttributedString(string: text)

        var wordIndex = 0

        for parsedWord in parsedWords {
            guard !parsedWord.isSeparator else { continue }

            let nsRange = NSRange(parsedWord.range, in: text)
            if wordIndex == currentWordIndex {
                attributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: nsRange)
                textView.scrollRangeToVisible(nsRange)
            } else {
                attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: nsRange)
            }
            wordIndex += 1
        }

        textView.attributedText = attributedString
        textView.font = UIFont.preferredFont(forTextStyle: .body)
    }
}
#endif

#Preview {
    TextEntryView()
}
