import SwiftData
import SwiftUI

@MainActor
class EntryManager {
    static let shared = EntryManager()
    
    private var modelContainer: ModelContainer
    
    private init() {
        do {
            modelContainer = try ModelContainer(for: Entry.self)
        } catch {
            fatalError("Failed to create ModelContainer for Entry: \(error.localizedDescription)")
        }
    }
    
    var mainContext: ModelContext {
        modelContainer.mainContext
    }
    
    func fetchEntries() -> [Entry] {
        let descriptor = FetchDescriptor<Entry>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        do {
            return try mainContext.fetch(descriptor)
        } catch {
            print("Failed to fetch entries: \(error.localizedDescription)")
            return []
        }
    }
    
    func saveEntry(_ text: String) {
        let entry = Entry(text: text)
        mainContext.insert(entry)
        
        do {
            try mainContext.save()
        } catch {
            print("Failed to save entry: \(error.localizedDescription)")
        }
    }
    
    func deleteEntry(_ entry: Entry) {
        mainContext.delete(entry)
        
        do {
            try mainContext.save()
        } catch {
            print("Failed to delete entry: \(error.localizedDescription)")
        }
    }
} 
