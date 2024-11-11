import UIKit
import SwiftUI
import WordPressShared

struct ReaderSearchSuggestionsView: View {
    @ObservedObject var viewModel: ReaderSearchSuggestionsViewModel

    var body: some View {
        List {
            ForEach(viewModel.suggestions.prefix(7), id: \.self) { suggestion  in
                Button {
                    viewModel.onSelection?(suggestion)
                } label: {
                    makeItem(for: suggestion)
                }
            }
            .onDelete(perform: viewModel.delete)

            if !viewModel.suggestions.isEmpty {
                Button {
                    viewModel.buttonClearSearchHistoryTapped()
                } label: {
                    Text(Strings.clearHistory)
                        .foregroundStyle(AppColor.brand)
                }
            }
        }
        .listStyle(.plain)
    }

    private func makeItem(for suggestion: String) -> some View {
        HStack {
            Text(suggestion)
            Spacer()
            Button {
                viewModel.delete([suggestion])
            } label: {
                Image(systemName: "xmark")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .swipeActions(edge: .trailing) {
            Button(SharedStrings.Button.delete, role: .destructive) {
                viewModel.delete([suggestion])
            }.tint(.red)
        }
    }
}

final class ReaderSearchSuggestionsViewModel: ObservableObject {
    @Published private(set) var suggestions: [String] = []
    @Published private(set) var allSuggestions: [String] = []

    var onSelection: ((String) -> Void)?

    init() {
        reloadSuggestions()
    }

    var searchText: String = "" {
        didSet { updateDisplayedSuggesions() }
    }

    private func reloadSuggestions() {
        self.allSuggestions = UserDefaults.standard.readerSearchHistory
        self.updateDisplayedSuggesions()
    }

    private func updateDisplayedSuggesions() {
        let searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if searchText.isEmpty {
            suggestions = allSuggestions
        } else {
            suggestions = StringRankedSearch(searchTerm: searchText)
                .search(in: allSuggestions, input: \.self)
        }
    }

    func delete(at indexSet: IndexSet) {
        delete(indexSet.map { suggestions[$0] })
    }

    func delete(_ deleted: [String]) {
        let deleted = Set(deleted)
        allSuggestions.removeAll(where: deleted.contains)
        saveSuggestions()
    }

    func buttonClearSearchHistoryTapped() {
        allSuggestions = []
        saveSuggestions()
        WPAnalytics.trackReader(.readerSearchHistoryCleared)
    }

    func saveSearchText(_ searchText: String) {
        if let index = allSuggestions.firstIndex(of: searchText) {
            allSuggestions.remove(at: index)
        }
        allSuggestions.insert(searchText, at: 0)
        saveSuggestions()
    }

    private func saveSuggestions() {
        UserDefaults.standard.readerSearchHistory = allSuggestions
        reloadSuggestions()
    }
}

private enum Strings {
    static let clearHistory = NSLocalizedString("reader.search.clearHistory", value: "Clear History", comment: "Reader Search")
}
