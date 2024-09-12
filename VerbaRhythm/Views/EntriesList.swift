//
//  SidePanelView.swift
//  VerbaRhythm
//
//  Created by Austin Condiff on 8/18/24.
//

import SwiftUI

struct SidePanelView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    @State var searchText: String = ""

    var filteredHistory: [Entry] {
        if searchText.isEmpty {
            return viewModel.history
        } else {
            return viewModel.history.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        VStack {
            if viewModel.history.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.title)
                    Text("No History")
                        .font(.title3)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.secondary)
                Spacer()
            } else {
                List(selection: $viewModel.selectedHistoryEntries) {
                    if searchText.isEmpty {
                        ForEach(EntryGroup.allCases, id: \.self) { group in
                            if let entries = viewModel.groupedHistory[group], !entries.isEmpty {
                                Section(header: HStack(spacing: 5) {
                                    if group == .pinned {
                                        Image(systemName: "pin.fill")
                                    }
                                    Text(group.rawValue)
                                }) {
                                    ForEach(entries, id: \.id) { entry in
                                        historyEntryView(entry)
                                    }
                                }
                            }
                        }
                    } else {
                        Section {
                            ForEach(filteredHistory, id: \.id) { entry in
                                historyEntryView(entry)
                            }
                        }
                    }
                }
                .searchable(text: $searchText, placement: .sidebar)
                .contextMenu(
                    forSelectionType: UUID.self,
                    menu: { selectedIDs in
                        if !selectedIDs.isEmpty {
                            Group {
                                // Check if all selected entries are pinned
                                if selectedIDs.allSatisfy({ id in
                                    viewModel.history.first(where: { $0.id == id })?.pinned == true
                                }) {
                                    Button("Unpin") {
                                        selectedIDs.forEach { id in
                                            if let index = viewModel.history.firstIndex(where: { $0.id == id }) {
                                                viewModel.history[index].pinned = false
                                            }
                                        }
                                    }
                                } else {
                                    Button("Pin") {
                                        selectedIDs.forEach { id in
                                            if let index = viewModel.history.firstIndex(where: { $0.id == id }) {
                                                viewModel.history[index].pinned = true
                                            }
                                        }
                                    }
                                }
                                Button("Delete") {
                                    viewModel.deleteHistoryEntries(historyEntries: selectedIDs)
                                }
                            }
                        } else {
                            EmptyView()
                        }
                    }
                )
#if os(iOS)
                .environment(\.editMode, .constant(viewModel.editingHistory ? .active : .inactive))
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
                .safeAreaInset(edge: .top, spacing: 0) {
                    HStack(spacing: 28) {
                        Button {
                            viewModel.drawerIsPresented.toggle()
                        } label: {
                            Label(
                                "Toggle Drawer",
                                systemImage: "list.bullet"
                            )
                        }
                        Spacer()
                        Button {
                            withAnimation {
                                viewModel.editingHistory.toggle()
                            }
                        } label: {
                            Text(viewModel.editingHistory ? "Done" : "Edit")
                                .font(.system(size: 17, weight: .medium))
                        }
                    }
                    .labelStyle(.iconOnly)
                    .font(.system(size: 22, weight: .regular))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if viewModel.editingHistory {
                        VStack(spacing: 0) {
                            Divider()
                            HStack(spacing: 28) {
                                if !viewModel.selectedHistoryEntries.isEmpty {
                                    Button {
                                        viewModel.showDeleteConfirmation = true
                                        viewModel.deleteAction = .deleteSelected
                                    } label: {
                                        Text("Delete (\(viewModel.selectedHistoryEntries.count))")
                                            .font(.system(size: 17, weight: .medium))
                                    }
                                }
                                Spacer()
                                Button {
                                    viewModel.showDeleteConfirmation = true
                                    viewModel.deleteAction = .deleteAll
                                } label: {
                                    Text("Delete All")
                                        .font(.system(size: 17, weight: .medium))
                                }
                            }
                            .padding(.vertical)
                            .padding(.horizontal, 20)
                        }
                        .labelStyle(.iconOnly)
                        .font(.system(size: 22, weight: .regular))
                        .background(Color(.secondarySystemBackground))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
#endif
                .confirmationDialog(
                    "Delete Confirmation",
                    isPresented: $viewModel.showDeleteConfirmation,
                    titleVisibility: .hidden,
                    actions: {
                        Button(role: .destructive) {
                            if viewModel.deleteAction == .deleteAll {
                                viewModel.deleteAllHistoryEntries()
                            } else {
                                viewModel.deleteSelectedHistoryEntries()
                            }
                        } label: {
                            Text(viewModel.deleteAction == .deleteAll ? "Delete All" : "Delete")
                        }
                        Button("Cancel", role: .cancel) {}
                    },
                    message: {
                        let count = viewModel.selectedHistoryEntries.count
                        Text(
                            viewModel.deleteAction == .deleteAll
                            ? "All entries will be deleted. This action cannot be undone."
                            : count == 1
                            ? "This entry will be deleted. This action cannot be undone."
                            : "These (\(count)) entries will be deleted. This action cannot be undone."
                        )
                    }
                )
            }
        }
    }

    @ViewBuilder
    private func historyEntryView(_ entry: Entry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.text == "" ? "New Entry" : entry.text)
                .font(.body)
                .lineLimit(3)
                .truncationMode(.tail)
            Group {
                Text(entry.timestamp, style: .date) + Text(" at ") + Text(entry.timestamp, style: .time)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
#if !os(macOS)
        .padding(.vertical, 4)
        .gesture(
            viewModel.editingHistory ? nil : TapGesture().onEnded {
                viewModel.phraseText = entry.text
                viewModel.currentIndex = 0
                viewModel.drawerIsPresented = false
            }
        )
        .listRowBackground(
            viewModel.editingHistory
            ? (viewModel.selectedHistoryEntries.contains(entry.id) ? Color.accentColor.opacity(0.2) : Color.clear) // Background when editing
            : (entry.text == viewModel.phraseText ? Color(.tertiarySystemBackground) : Color.clear) // Background when not editing
        )
#endif
    }
}

#Preview {
    SidePanelView()
}
