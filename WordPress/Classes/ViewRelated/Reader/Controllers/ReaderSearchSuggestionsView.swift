import UIKit
import SwiftUI
import WordPressShared

struct ReaderSearchSuggestionsView: View {
    @ObservedObject var viewModel: ReaderSearchSuggestionsViewModel

    var body: some View {
        List {
            ForEach(viewModel.suggestions.prefix(7), id: \.self) { suggestion  in
                Button {
                    viewModel.onSelection?(suggestion.searchPhrase)
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

    private func makeItem(for suggestion: ReaderSearchSuggestion) -> some View {
        HStack {
            Text(suggestion.searchPhrase)
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
    @Published private(set) var suggestions: [ReaderSearchSuggestion] = []
    @Published private(set) var allSuggestions: [ReaderSearchSuggestion] = []

    var onSelection: ((String) -> Void)?

    private let coreData = ContextManager.shared

    init() {
        reloadSuggestions()
    }

    var searchText: String = "" {
        didSet { updateDisplayedSuggesions() }
    }

    private func reloadSuggestions() {
        let request = NSFetchRequest<ReaderSearchSuggestion>(entityName: "ReaderSearchSuggestion")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        self.allSuggestions = (try? coreData.mainContext.fetch(request)) ?? []
        self.updateDisplayedSuggesions()
    }

    private func updateDisplayedSuggesions() {
        let searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if searchText.isEmpty {
            suggestions = allSuggestions
        } else {
            suggestions = StringRankedSearch(searchTerm: searchText)
                .search(in: allSuggestions, input: \.searchPhrase)
        }
    }

    func delete(at indexSet: IndexSet) {
        delete(indexSet.map { suggestions[$0] })
    }

    func delete(_ suggestions: [ReaderSearchSuggestion]) {
        let context = coreData.mainContext
        for suggestion in suggestions {
            context.delete(suggestion)
        }
        reloadSuggestions()
    }

    func buttonClearSearchHistoryTapped() {
        let service = ReaderSearchSuggestionService(coreDataStack: coreData)
        service.deleteAllSuggestions()
        allSuggestions = []
        suggestions = []
        WPAnalytics.trackReader(.readerSearchHistoryCleared)
    }

    func saveSearchText(_ searchText: String) {
        ReaderSearchSuggestionService(coreDataStack: coreData)
            .createOrUpdateSuggestion(forPhrase: searchText)
        reloadSuggestions()
    }
}

private enum Strings {
    static let clearHistory = NSLocalizedString("reader.search.clearHistory", value: "Clear History", comment: "Reader Search")
}
