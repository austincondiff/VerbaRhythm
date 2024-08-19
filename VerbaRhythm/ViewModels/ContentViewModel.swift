//
//  ContentViewModel.swift
//  Verbarhythm
//
//  Created by Austin Condiff on 8/18/24.
//


import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var focusedField: Bool = false {
        didSet {
            if (!focusedField && !phraseText.isEmpty && phraseText != lastSavedEntry?.text) {
                saveHistoryEntry()
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
        }
    }
    @Published var temporaryPause = false
    @Published var initialDragPosition: CGFloat?
    @Published var timer: Timer?
    @Published var prevWordSize: CGSize = CGSize(width: 0, height: 0)
    @Published var currentWordSize: CGSize = CGSize(width: 0, height: 0)
    @Published var nextWordSize: CGSize = CGSize(width: 0, height: 0)
    @Published var showGhostText: Bool = true
    @Published var editingHistory: Bool = false
    @Published var selectedHistoryEntries = Set<HistoryEntry>()
    @Published var isFullScreen: Bool = false
    @Published var drawerIsPresented: Bool = false {
        didSet {
            focusedField = false
            if isPlaying {
                pause()
            }
        }
    }
    @Published var dragOffset: CGFloat = 0
    @Published var words: [String.SubSequence] = []
    @Published var history: [HistoryEntry] = []
    @Published var lastSavedEntry: HistoryEntry? = nil
    @Published var isDynamicSpeedOn: Bool = true
    @Published var speedMultiplier: Double = 1.0
    @Published var fontSizeMultiplier: Double = 1.0
    @Published var ghostWordCount: Int = 5;
    @Published var showDeleteConfirmation = false
    @Published var deleteAction: DeleteAction? = nil

    let speedOptions: [Double] = Array(stride(from: 0.25, through: 2.0, by: 0.25))

    func onPhraseTextChange() {
        words = phraseText.split(separator: Regex(/[ \t\n—]/))
        if words.count == 0 {
            currentIndex = 0
        } else if currentIndex > words.count - 1 {
            currentIndex = words.count - 1
        }
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

    func prev() {
        currentIndex = currentIndex - 1
    }

    func next() {
        currentIndex = currentIndex + 1
    }

    func toBeginning() {
        currentIndex = 0
    }

    func toEnd() {
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
        let punctuation = word.last
        var interval: Double = 0.15 * max(Double(word.count), 2)

        if isDynamicSpeedOn {
            if punctuation == "," {
                interval += 1
            } else if punctuation == "." || punctuation == ";" || punctuation == ":" || punctuation == "!" || punctuation == "?" {
                interval += 1.5
            } else if word.contains("\n") {
                interval += 2
            }

            if word.filter({ $0 == "\n" }).count > 1 {
                interval += 2
            }

            let syllableCount = countSyllables(in: String(word))
            interval = 0.25 * max(Double(syllableCount), interval)
        } else {
            interval = 0.5
        }

        interval /= speedMultiplier

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

    func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func handleWordDisplayDragChanged(_ value: DragGesture.Value) {
        if drawerIsPresented || value.startLocation.x <= 20 {
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

    func handleWordDisplayDragEnded() {
        initialDragPosition = nil

        if temporaryPause {
            temporaryPause = false
            play()
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
            if let loadedHistory = try? decoder.decode([HistoryEntry].self, from: savedHistory) {
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

        let newEntry = HistoryEntry(id: UUID(), text: currentText, timestamp: now)
        history.append(newEntry)
        lastSavedEntry = newEntry
        saveHistory()
    }

    var groupedHistory: [HistoryGroup: [HistoryEntry]] {
        var grouped: [HistoryGroup: [HistoryEntry]] = [:]

        let now = Date()
        for entry in history {
            let daysDifference = Calendar.current.dateComponents([.day], from: entry.timestamp, to: now).day ?? 0

            let group: HistoryGroup
            switch daysDifference {
            case 0:
                group = .today
            case 1...7:
                group = .last7Days
            case 8...30:
                group = .last30Days
            default:
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
            selectedHistoryEntries.contains(entry)
        }
        selectedHistoryEntries.removeAll()
        saveHistory()
    }

    func deleteAllHistoryEntries() {
        history.removeAll()
        selectedHistoryEntries.removeAll()
        saveHistory()
    }
}
