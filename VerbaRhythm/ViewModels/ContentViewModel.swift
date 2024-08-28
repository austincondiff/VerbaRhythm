//
//  ContentViewModel.swift
//  Verbarhythm
//
//  Created by Austin Condiff on 8/18/24.
//


import SwiftUI
import Combine

enum TextStyle: String, CaseIterable {
    case sansSerif = "Sans Serif"
    case serif = "Serif"
    case monospaced = "Monospaced"
    case rounded = "Rounded"

    func toFont(size: CGFloat, weight: TextWeight, width: TextWidth) -> Font {
        switch self {
        case .sansSerif:
            return .system(size: size, weight: weight.toFontWeight(), design: .default).width(width.toFontWidth())
        case .serif:
            return .system(size: size, weight: weight.toFontWeight(), design: .serif).width(width.toFontWidth())
        case .monospaced:
            return .system(size: size, weight: weight.toFontWeight(), design: .monospaced).width(width.toFontWidth())
        case .rounded:
            return .system(size: size, weight: weight.toFontWeight(), design: .rounded).width(width.toFontWidth())
        }
    }
}

enum TextSize: String, CaseIterable {
    case xs = "Extra Small"
    case sm = "Small"
    case md = "Medium"
    case lg = "Large"
    case xl = "Extra Large"

    func toSize() -> CGFloat {
        switch self {
        case .xs:
            return 20
        case .sm:
            return 28
        case .md:
            return 34
        case .lg:
            return 40
        case .xl:
            return 48
        }
    }
}

enum TextWeight: String, CaseIterable {
    case ultraLight = "Ultra Light"
    case thin = "Thin"
    case light = "Light"
    case regular = "Regular"
    case medium = "Medium"
    case semibold = "Semibold"
    case bold = "Bold"
    case heavy = "Heavy"
    case black = "Black"

    func toFontWeight() -> Font.Weight {
        switch self {
        case .ultraLight:
            return .ultraLight
        case .thin:
            return .thin
        case .light:
            return .light
        case .regular:
            return .regular
        case .medium:
            return .medium
        case .semibold:
            return .semibold
        case .bold:
            return .bold
        case .heavy:
            return .heavy
        case .black:
            return .black
        }
    }
}

enum TextWidth: String, CaseIterable {
    case compressed = "Compressed"
    case condensed = "Condensed"
    case standard = "Standard"
    case expanded = "Expanded"

    func toFontWidth() -> Font.Width {
        switch self {
        case .compressed:
            return .compressed
        case .condensed:
            return .condensed
        case .standard:
            return .standard
        case .expanded:
            return .expanded
        }
    }
}


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

    @Published var history: [HistoryEntry] = []

    @Published var editingHistory: Bool = false
    @Published var selectedHistoryEntries = Set<HistoryEntry>()
    @Published var isFullScreen: Bool = false
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
    @Published var lastSavedEntry: HistoryEntry? = nil

    @Published var ghostWordCount: Int = 5;
    @Published var showDeleteConfirmation = false
    @Published var deleteAction: DeleteAction? = nil
    @Published var scrollViewHeight: CGFloat = 0
    @Published var scrollContentHeight: CGFloat = 0
    @Published var scrollViewProxy: ScrollViewProxy? = nil
    @Published var settingsSheetIsPresented: Bool = false {
        didSet {
            if settingsSheetIsPresented {
                drawerIsPresented = false
                focusedField = false
            }
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

        if settings.isDynamicSpeedOn {
            if punctuation == "," {
                interval += 2
            } else if punctuation == "." || punctuation == ";" || punctuation == ":" || punctuation == "!" || punctuation == "?" {
                interval += 3
            } else if word.contains("\n") {
                interval += 10
            }

            if word.filter({ $0 == "\n" }).count > 1 {
                interval += 10
            }

            let syllableCount = countSyllables(in: String(word))
            interval = 0.25 * max(Double(syllableCount), interval)
        } else {
            interval = 0.5
        }

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
                #if os(iOS)
                triggerHapticFeedback() // Trigger haptic feedback on index change
                #endif
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
