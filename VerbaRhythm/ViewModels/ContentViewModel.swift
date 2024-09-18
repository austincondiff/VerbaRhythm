//
//  ContentViewModel.swift
//  VerbaRhythm
//
//  Created by Austin Condiff on 8/18/24.
//


import SwiftUI
import Combine

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
            print("ContentViewModel drawerIsPresented: \(drawerIsPresented)")
            if drawerIsPresented {
                focusedField = false
                settingsSheetIsPresented = false
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

    init(settings: SettingsViewModel = SettingsViewModel()) {
        self.settings = settings

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

    func play() {
        isPlaying = true
        startTimer()
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
    }

    func toEnd() {
        focusedField = false
        if isPlaying { pause() }
        currentIndex = words.count - 1
    }

    func atBeginning() -> Bool {
        currentIndex == 0
    }

    func atEnd() -> Bool {
        currentIndex == words.count - 1
    }

    func startTimer() {
        let word = words[currentIndex]
        var interval: Double = 0.15 * max(Double(word.count), 2)

        if settings.isDynamicSpeedOn {
            // Handle newlines as separate "words" with longer pauses
            if word == "\n" {
                interval += 10
            } else {
                let punctuation = word.last
                if punctuation == "," {
                    interval += 3
                } else if punctuation == "." || punctuation == "?" || punctuation == "!" {
                    interval += 6
                } else if punctuation == ";" || punctuation == ":" {
                    interval += 4
                }

                // Account for the space separating the word
                interval += 0.5

                // Syllable-based interval adjustment
                let syllableCount = countSyllables(in: String(word))
                interval = 0.18 * max(Double(syllableCount), interval)
            }

            // Introduce small random variation for natural rhythm
            let randomVariation = Double.random(in: -0.05...0.05) * interval
            interval += randomVariation
        } else {
            interval = 0.5 // Default fixed interval
        }

        // Adjust for user-defined speed multiplier
        interval /= settings.speedMultiplier

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [self] _ in
            if self.currentIndex < self.words.count - 1 && self.words.count > 0 {
                currentIndex += 1
                startTimer()
            } else {
                isPlaying = false
                timer?.invalidate()
                timer = nil
            }
        }
    }

    func getPreviousWords() -> String {
        guard currentIndex > 0 else { return "" }
        let start = max(0, currentIndex - ghostWordCount)
        let end = currentIndex - 1
        return "\(words[start...end].joined(separator: " ")) "
    }

    func getNextWords() -> String {
        guard currentIndex < words.count - 1 else { return "" }
        let start = currentIndex + 1
        let end = min(words.count - 1, currentIndex + ghostWordCount)
        return " \(words[start...end].joined(separator: " "))"
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
        if let savedHistory = UserDefaults.standard.object(forKey: "history") as? Data {
            let decoder = JSONDecoder()
            if let loadedHistory = try? decoder.decode([Entry].self, from: savedHistory) {
                history = loadedHistory
                lastSavedEntry = history.last
            }
        }
    }

    func saveHistoryEntry() {
        let currentText = phraseText.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()

        if history.contains(where: { $0.text == currentText }) {
            return
        }

        if let lastEntry = lastSavedEntry {
            if Calendar.current.isDate(now, inSameDayAs: lastEntry.timestamp) && currentText == lastEntry.text {
                return
            }
        }

        let newEntry = Entry(id: UUID(), text: currentText, timestamp: now)
        history.append(newEntry)
        lastSavedEntry = newEntry
        saveHistory()
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
        history.removeAll { entry in
            selectedHistoryEntries.contains(entry.id)
        }
        selectedHistoryEntries.removeAll()
        saveHistory()
    }

    func deleteHistoryEntries(historyEntries: Set<UUID>) {
        history.removeAll { entry in
            historyEntries.contains(entry.id)
        }

        selectedHistoryEntries.subtract(historyEntries)

        if selectedHistoryEntries.isEmpty, let firstEntry = history.first {
            selectedHistoryEntries.insert(firstEntry.id)
        }

        saveHistory()
    }

    func deleteAllHistoryEntries() {
        history.removeAll()
        selectedHistoryEntries.removeAll()
        saveHistory()
    }

    func addNewEntry() {
        // Clear selection and create a new entry
        selectedHistoryEntries.removeAll()

        let now = Date()
        let newEntry = Entry(id: UUID(), text: "", timestamp: now)

        withAnimation {
            history.append(newEntry)
            selectedHistoryEntries.insert(newEntry.id)
            isFullScreen = false
        }

        phraseText = newEntry.text // Set the phraseText to the new entry's text
        focusedField = true
    }
}
