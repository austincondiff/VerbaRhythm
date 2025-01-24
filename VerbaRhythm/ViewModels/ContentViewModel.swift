//
//  ContentViewModel.swift
//  VerbaRhythm
//
//  Created by Austin Condiff on 8/18/24.
//


import SwiftUI
import Combine
import SwiftData

@MainActor
class ContentViewModel: ObservableObject {
    @Published var focusedField: Bool = false {
        didSet {
            if (!focusedField && !phraseText.isEmpty && phraseText != lastSavedEntry?.text) {
                saveHistoryEntry()
            }
            if focusedField && isPlaying {
                pause()
            }
        }
    }
    @Published var phraseText: String = "" {
        didSet {
            onPhraseTextChange()
        }
    }
    @Published var currentIndex = 0
    @Published var isFocused: Bool = false
    @Published var editing: Bool = false
    @Published var isPlaying = false {
        didSet {
            editing = false
            if isPlaying {
                focusedField = false
            }
        }
    }
    @Published var temporaryPause = false
    @Published var initialDragPosition: CGFloat?
    @Published var timer: Timer?
    @Published var prevWordSize: CGSize = CGSize(width: 0, height: 0)
    @Published var currentWordSize: CGSize = CGSize(width: 0, height: 0)
    @Published var nextWordSize: CGSize = CGSize(width: 0, height: 0)

    @Published var history: [Entry] = []

    @Published var editingHistory: Bool = false
    @Published var selectedHistoryEntries = Set<UUID>() {
        didSet {
#if os(macOS)
            if let firstSelectedID = selectedHistoryEntries.first,
               let selectedEntry = history.first(where: { $0.id == firstSelectedID }) {
                phraseText = selectedEntry.text
                currentIndex = 0
            } else {
                phraseText = "" // Default to empty if no match found
            }

            if isPlaying {
                pause()
            }
#endif
        }
    }
    @Published var isFullScreen: Bool = false
    @Published var columnVisibility: NavigationSplitViewVisibility = .all
    @Published var drawerIsPresented: Bool = false {
        didSet {
            if drawerIsPresented {
                focusedField = false
                settingsSheetIsPresented = false
            } else {
#if os(iOS)
                if (phraseText.isEmpty) {
                    focusedField = true
                }
#endif
            }
            if isPlaying {
                pause()
            }
        }
    }
    @Published var dragOffset: CGFloat = 0
    @Published var words: [String.SubSequence] = []
    @Published var lastSavedEntry: Entry? = nil

    @Published var ghostWordCount: Int = 20;
    @Published var showDeleteConfirmation = false
    @Published var deleteAction: DeleteAction? = nil
    @Published var scrollViewHeight: CGFloat = 0
    @Published var scrollContentHeight: CGFloat = 0
    @Published var scrollViewProxy: ScrollViewProxy? = nil
    @Published var settingsSheetIsPresented: Bool = false {
        didSet {
#if !os(macOS)
            if settingsSheetIsPresented {
                drawerIsPresented = false
                focusedField = false
            }
#endif
        }
    }
    @Published var sheetHeight: CGFloat = .zero

    @Published var isKeyboardVisible: Bool = false

    @Published var settingsResetConfirmationIsPresented: Bool = false

    private var cancellables = Set<AnyCancellable>()

    let settings: SettingsViewModel
    private let entryManager: EntryManager

    init(settings: SettingsViewModel = SettingsViewModel(), entryManager: EntryManager = .shared) {
        self.settings = settings
        self.entryManager = entryManager

#if os(iOS)
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] _ in
                self?.isKeyboardVisible = true
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                self?.isKeyboardVisible = false
            }
            .store(in: &cancellables)
#endif
    }

    var characterIndexForCurrentWord: Int {
        let words = phraseText.split(separator: " ")
        let range = words.prefix(currentIndex).joined(separator: " ").count
        return range + (currentIndex > 0 ? currentIndex : 0) // Adding spaces
    }

    let speedOptions: [Double] = Array(stride(from: 0.25, through: 3.0, by: 0.25))

    func onPhraseTextChange() {
        let parsedWords = parseWords(from: phraseText)

        // Filter out the separators and keep only the words
        words = parsedWords.filter { !$0.isSeparator }.map { $0.word[...]} // Preserves the SubSequence type

        if words.isEmpty {
            currentIndex = 0
        } else if currentIndex > words.count - 1 {
            currentIndex = words.count - 1
        }

#if os(macOS)
        if !selectedHistoryEntries.isEmpty {
            if let selectedID = selectedHistoryEntries.first,
               let historyIndex = history.firstIndex(where: { $0.id == selectedID }) {
                var entry = history[historyIndex]
                let now = Date()

                // Update entry with new text and timestamp
                entry.text = phraseText
                entry.timestamp = now

                // Only save the history if the text has changed
                if history[historyIndex].text != entry.text {
                    history[historyIndex] = entry
                    saveHistory() // Save history, consider throttling for efficiency
                }
            }
        }
#endif
    }

    func parseWords(from text: String) -> [(word: String, isSeparator: Bool, range: Range<String.Index>)] {
        let regex = try! NSRegularExpression(pattern: "[ \t\n—]+", options: [])
        let nsText = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

        var parsedWords: [(word: String, isSeparator: Bool, range: Range<String.Index>)] = []
        var lastRangeEnd = text.startIndex

        for match in matches {
            let separatorRange = Range(match.range, in: text)!

            // Add the word before the separator (if any)
            if lastRangeEnd < separatorRange.lowerBound {
                let wordRange = lastRangeEnd..<separatorRange.lowerBound
                let word = String(text[wordRange])
                parsedWords.append((word, false, wordRange))
            }

            // Add the separator itself
            let separator = String(text[separatorRange])
            parsedWords.append((separator, true, separatorRange))

            // Move the last range end to after the separator
            lastRangeEnd = separatorRange.upperBound
        }

        // Add any remaining word after the last separator
        if lastRangeEnd < text.endIndex {
            let wordRange = lastRangeEnd..<text.endIndex
            let word = String(text[wordRange])
            parsedWords.append((word, false, wordRange))
        }

        return parsedWords
    }

    var parsedWords: [(word: String, isSeparator: Bool, range: Range<String.Index>)] {
        parseWords(from: phraseText)
    }

    func play() {
        // Reset parsedWordIndex based on currentIndex when starting playback
        parsedWordIndex = 0
        // Find the correct parsedWordIndex that corresponds to currentIndex
        var wordCount = 0
        for (index, word) in parsedWords.enumerated() {
            if !word.isSeparator {
                if wordCount == currentIndex {
                    parsedWordIndex = index
                    break
                }
                wordCount += 1
            }
        }
        
        isPlaying = true
        
        // Add initial delay before starting playback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5/settings.speedMultiplier) { [weak self] in
            guard let self = self, self.isPlaying else { return }
            self.startTimer()
        }
    }

    func pause() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }

    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            focusedField = false
            play()
        }
    }

    func prev() {
        focusedField = false
        if isPlaying { pause() }
        currentIndex = currentIndex - 1
    }

    func next() {
        focusedField = false
        if isPlaying { pause() }
        currentIndex = currentIndex + 1
    }

    func toBeginning() {
        focusedField = false
        if isPlaying { pause() }
        currentIndex = 0
        parsedWordIndex = 0  // Reset parsed index
    }

    func toEnd() {
        focusedField = false
        if isPlaying { pause() }
        currentIndex = words.count - 1
        // Find the last non-separator word's index
        parsedWordIndex = parsedWords.count - 1
        while parsedWordIndex > 0 && parsedWords[parsedWordIndex].isSeparator {
            parsedWordIndex -= 1
        }
    }

    func atBeginning() -> Bool {
        currentIndex == 0
    }

    func atEnd() -> Bool {
        currentIndex == words.count - 1
    }

    // Add this property to your view model or wherever you're tracking state
    var parsedWordIndex = 0 // Tracks the index in parsedWords, including separators

    func startTimer() {
        guard parsedWordIndex < parsedWords.count else {
            // End playback if we reach the end of parsed words
            isPlaying = false
            timer?.invalidate()
            timer = nil
            return
        }

        let parsedWord = parsedWords[parsedWordIndex]
        
        // Check if this is the last non-separator word
        let isLastWord = parsedWordIndex >= parsedWords.count - 1 || 
                         !parsedWords.suffix(from: parsedWordIndex + 1).contains(where: { !$0.isSeparator })
        
        if isLastWord {
            // Immediately end playback on last word without delay
            parsedWordIndex = parsedWords.count
            isPlaying = false
            timer?.invalidate()
            timer = nil
            return
        }

        var interval: Double = 0

        if settings.isDynamicSpeedOn {
            if parsedWord.isSeparator {
                // Handle separator cases with fixed intervals
                if parsedWord.word == "\n" {
                    interval = 10 // Longer pause for newlines
                } else if parsedWord.word == "-" {
                    interval = 3 // Pause for "-"
                } else if parsedWord.word == "–" {
                    interval = 4 // Pause for "–"
                } else if parsedWord.word == "—" {
                    interval = 6 // Pause for "—"
                }
            } else {
                // Handle word cases with dynamic speed
                interval = 0.15 * max(Double(parsedWord.word.count), 2) // Base interval for word length

                // Handle punctuation at the end of a word
                if let punctuation = parsedWord.word.last {
                    if punctuation == "," {
                        interval += 3
                    } else if punctuation == "." || punctuation == "?" || punctuation == "!" {
                        interval += 6
                    } else if punctuation == ";" || punctuation == ":" {
                        interval += 4
                    }
                }

                // Account for the space after the word
                interval += 0.5

                // Syllable-based interval adjustment (for words only)
                let syllableCount = countSyllables(in: String(parsedWord.word))
                interval = 0.18 * max(Double(syllableCount), interval)

                // Introduce small random variation for natural rhythm
                let randomVariation = Double.random(in: -0.05...0.05) * interval
                interval += randomVariation
            }
        } else {
            // Fixed interval when dynamic speed is off
            interval = 0.5
        }

        // Adjust for user-defined speed multiplier
        interval /= settings.speedMultiplier

        // Schedule the next word or separator
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [self] _ in
            // Increment parsedWordIndex to move to the next word or separator
            parsedWordIndex += 1

            // Increment currentIndex only for non-separator words
            if parsedWordIndex < parsedWords.count, !parsedWords[parsedWordIndex].isSeparator {
                currentIndex += 1
            }

            startTimer()
        }
    }

    func getPreviousWords() -> String {
        guard currentIndex > 0 else { return "" }

        // Find the corresponding range in parsedWords, excluding separators
        var wordCount = 0
        var start = 0
        var end = 0

        for (i, parsedWord) in parsedWords.enumerated() {
            if !parsedWord.isSeparator {
                if wordCount == max(0, currentIndex - ghostWordCount) {
                    start = i
                }
                if wordCount == currentIndex - 1 {
                    end = i
                    break
                }
                wordCount += 1
            }
        }

        // Ensure the next element after 'end' is a separator if it exists
        let hasSeparatorAfterEnd = (end + 1 < parsedWords.count && parsedWords[end + 1].isSeparator)
        let previousWords = parsedWords[start...(hasSeparatorAfterEnd ? end + 1 : end)].map { $0.word }.joined()

        return previousWords
    }

    func getNextWords() -> String {
        guard currentIndex < parsedWords.filter({ !$0.isSeparator }).count - 1 else { return "" }

        // Find the corresponding range in parsedWords, excluding separators
        var wordCount = 0
        var start = 0
        var end = 0

        for (i, parsedWord) in parsedWords.enumerated() {
            if !parsedWord.isSeparator {
                if wordCount == currentIndex + 1 {
                    start = i
                }
                if wordCount == min(currentIndex + ghostWordCount, parsedWords.filter({ !$0.isSeparator }).count - 1) {
                    end = i
                    break
                }
                wordCount += 1
            }
        }

        // Ensure the previous element before 'start' is a separator if it exists
        let hasSeparatorBeforeStart = (start - 1 >= 0 && parsedWords[start - 1].isSeparator)
        let nextWords = parsedWords[(hasSeparatorBeforeStart ? start - 1 : start)...end].map { $0.word }.joined()

        return nextWords
    }

    func countSyllables(in word: String) -> Int {
        let vowels = "aeiouyäöüàèìòùáéíóúâêîôû"
        let lowercasedWord = word.lowercased()
        var syllableCount = 0
        var lastWasVowel = false

        for character in lowercasedWord {
            if vowels.contains(character) {
                if !lastWasVowel {
                    syllableCount += 1
                }
                lastWasVowel = true
            } else {
                lastWasVowel = false
            }
        }

        if lowercasedWord.hasSuffix("e") && !vowels.contains(lowercasedWord.last ?? " ") {
            syllableCount = max(syllableCount - 1, 1)
        }

        return max(syllableCount, 1)
    }

#if os(iOS)
    func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
#elseif os(macOS)
    func triggerHapticFeedback() {
        let hapticManager = NSHapticFeedbackManager.defaultPerformer
        hapticManager.perform(.alignment, performanceTime: .now)
    }
#endif


    func handleWordDisplayDragChanged(_ value: DragGesture.Value) {
        if drawerIsPresented || value.startLocation.x <= 20 || (abs(value.translation.width) < 10 && abs(value.translation.height) < 10) {
            return
        }

        if !temporaryPause && isPlaying {
            temporaryPause = true
            pause()
        }

        if initialDragPosition == nil {
            initialDragPosition = value.startLocation.x
        }

        let cumulativeDragDistance = value.location.x - initialDragPosition!
        let incrementCount = Int(-cumulativeDragDistance / 20)

        if incrementCount != 0 {
            let newIndex = max(0, min(words.count - 1, currentIndex + incrementCount))

            if newIndex != currentIndex {
                currentIndex = newIndex
                triggerHapticFeedback() // Trigger haptic feedback on index change
            }

            initialDragPosition! += CGFloat(incrementCount) * -20
        }
    }

    func handleWordDisplayDragEnded(_ value: DragGesture.Value) {

        if abs(value.translation.width) < 10 && abs(value.translation.height) < 10 {
            if isPlaying {
                pause()
            } else {
                play()
            }
        } else {
            initialDragPosition = nil

            if temporaryPause {
                temporaryPause = false
                play()
            }
        }
    }

    func handleWordDisplayScrollChanged(_ translation: CGFloat) {
        if drawerIsPresented || abs(translation) == 0 {
            return
        }

        if !temporaryPause && isPlaying {
            temporaryPause = true
            pause()
        }

        if initialDragPosition == nil {
            initialDragPosition = translation
        }

        let cumulativeDragDistance = translation - initialDragPosition!
        let incrementCount = Int(-cumulativeDragDistance/20) // Adjust this factor for more or less sensitivity
        print(translation/20)
        let newIndex = max(0, min(words.count - 1, currentIndex + incrementCount))

        if incrementCount != 0 {
            if newIndex != currentIndex {
                currentIndex = newIndex
                triggerHapticFeedback()
            }

            initialDragPosition! += CGFloat(incrementCount) * -20
        }
    }

    func handleWordDisplayScrollEnded(_ translation: CGFloat) {
        initialDragPosition = nil

        if temporaryPause {
            temporaryPause = false
            play()
        }
    }

    func scrollToCurrentWord() {
        if let scrollViewProxy {
            let totalWords = phraseText.split(separator: " ").count
            guard totalWords > 0 else { return }

            let progress = CGFloat(currentIndex) / CGFloat(totalWords)

            // Adjust the scrollOffset to keep the current word in the center of the scrollView
            let halfScrollViewHeight = scrollViewHeight / 2
            let adjustedOffset = (progress * (scrollContentHeight + scrollViewHeight)) - halfScrollViewHeight

            // Constrain the offset to ensure it doesn't scroll beyond the content bounds
            let scrollOffset = max(0, adjustedOffset)

            scrollViewProxy.scrollTo("textContent", anchor: UnitPoint(x: 0.5, y: scrollOffset / scrollContentHeight))
        }
    }

    func saveHistory() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(history) {
            UserDefaults.standard.set(encoded, forKey: "history")
        }
    }

    func loadHistory() {
        Task {
            history = await entryManager.fetchEntries()
        }
    }

    func saveHistoryEntry() {
        let currentText = phraseText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if entry already exists
        if !history.contains(where: { $0.text == currentText }) {
            Task {
                await entryManager.saveEntry(currentText)
                await loadHistory() // Reload to get updated data
            }
        }
    }

    var groupedHistory: [EntryGroup: [Entry]] {
        var grouped: [EntryGroup: [Entry]] = [:]
        let calendar = Calendar.current
        let now = Date()

        for entry in history {
            let group: EntryGroup

            if entry.pinned == true {
                group = .pinned
            } else if calendar.isDateInToday(entry.timestamp) {
                group = .today
            } else if calendar.isDateInYesterday(entry.timestamp) {
                group = .yesterday
            } else if let daysDifference = calendar.dateComponents([.day], from: entry.timestamp, to: now).day {
                switch daysDifference {
                case 1...7:
                    group = .last7Days
                case 8...30:
                    group = .last30Days
                default:
                    group = .earlier
                }
            } else {
                group = .earlier
            }

            grouped[group, default: []].append(entry)
        }

        for group in grouped.keys {
            grouped[group]?.sort(by: { $0.timestamp > $1.timestamp })
        }

        return grouped
    }

    func deleteSelectedHistoryEntries() {
        Task {
            for id in selectedHistoryEntries {
                if let entry = history.first(where: { $0.id == id }) {
                    await entryManager.deleteEntry(entry)
                }
            }
            selectedHistoryEntries.removeAll()
            await loadHistory()
        }
    }

    func deleteHistoryEntries(historyEntries: Set<UUID>) {
        Task {
            for id in historyEntries {
                if let entry = history.first(where: { $0.id == id }) {
                    await entryManager.deleteEntry(entry)
                }
            }
            selectedHistoryEntries.subtract(historyEntries)
            
            await loadHistory()
            
            if selectedHistoryEntries.isEmpty, let firstEntry = history.first {
                selectedHistoryEntries.insert(firstEntry.id)
            }
        }
    }

    func deleteAllHistoryEntries() {
        Task {
            for entry in history {
                await entryManager.deleteEntry(entry)
            }
            history.removeAll()
            selectedHistoryEntries.removeAll()
        }
    }

    func addNewEntry() {
        // Clear selection and create a new entry
        selectedHistoryEntries.removeAll()

        let now = Date()
        let newEntry = Entry(id: UUID(), text: "", timestamp: now)

        Task {
            await entryManager.saveEntry("")
            await loadHistory()
            
            withAnimation {
                if let entry = history.first(where: { $0.text.isEmpty }) {
                    selectedHistoryEntries.insert(entry.id)
                    isFullScreen = false
                }
            }

            phraseText = "" // Set the phraseText to empty
            focusedField = true
        }
    }
}
