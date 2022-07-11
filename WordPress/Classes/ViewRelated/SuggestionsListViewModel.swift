import Foundation

@objc protocol SuggestionsListViewModelType: AnyObject {
    var suggestionType: SuggestionType { get set }
    var prominentSuggestionsIds: [NSNumber]? { get set }

    var stateUpdated: ((SuggestionsListViewModelType) -> Void)? { get set }

    var isLoading: Bool { get }
    var searchText: String { get }

    var items: [SuggestionViewModel] { get }

    func reloadData()
    func searchSuggestions(withWord word: String) -> Bool
}

@objc final class SuggestionsListViewModel: NSObject, SuggestionsListViewModelType {

    // MARK: - Dependencies

    var context = ContextManager.shared.mainContext
    var userSuggestionService = SuggestionService.shared
    var siteSuggestionService = SiteSuggestionService.shared

    // MARK: - Configuration

    @objc var suggestionType: SuggestionType = .mention {
        didSet {
            self.searchSuggestions(withWord: searchText)
        }
    }

    @objc var prominentSuggestionsIds: [NSNumber]? {
        didSet {
            self.searchSuggestions(withWord: searchText)
        }
    }

    // MARK: - Input

    let blog: Blog?

    // MARK: - State

    @objc private(set) var isLoading = false
    @objc private(set) var items = [SuggestionViewModel]()

    private var suggestions = Suggestions.users([])
    private var searchResult = Suggestions.users([])

    var suggestionTrigger: String {
        return suggestionType.trigger
    }

    @objc private(set) var searchText: String = ""

    // MARK: - Callback

    /// Called when the search result is updated.
    @objc var stateUpdated: StateUpdatedHandler?

    // MARK: - Init

    init(blog: Blog?) {
        self.blog = blog
    }

    @objc convenience init(siteID: NSNumber, context: NSManagedObjectContext = ContextManager.shared.mainContext) {
        let blog = Blog.lookup(withID: siteID, in: context)
        self.init(blog: blog)
        self.context = context
    }

    // MARK: - Load Data

    @objc func reloadData() {
        guard let blog = self.blog else { return }
        self.isLoading = true
        switch suggestionType {
        case .mention:
            self.userSuggestionService.suggestions(for: blog) { [weak self] suggestions in
                guard let self = self else { return }
                self.suggestions = Suggestions.users(suggestions ?? [])
                self.isLoading = false
                self.searchSuggestions(withWord: self.searchText)
            }
        case .xpost:
            self.siteSuggestionService.suggestions(for: blog) { [weak self] suggestions in
                guard let self = self else { return }
                self.suggestions = Suggestions.sites(suggestions ?? [])
                self.isLoading = false
                self.searchSuggestions(withWord: self.searchText)
            }
        }
    }

    // MARK: - Performing Search

    /// Searches suggestions for the given word.
    /// - Parameter word: The suggestions that contain this word.
    /// - Returns: True when there is at least one suggestion.
    @discardableResult @objc func searchSuggestions(withWord word: String) -> Bool {
        if word.hasPrefix(suggestionTrigger) {
            let searchQuery = NSString(string: word).substring(from: suggestionTrigger.count)
            self.searchText = word
            self.searchResult = Self.searchResult(
                searchQuery: searchQuery,
                suggestions: suggestions,
                suggestionType: suggestionType,
                prominentSuggestionsIds: prominentSuggestionsIds ?? []
            )
        } else {
            self.searchText = ""
            self.searchResult = searchResult.cleared()
        }

        switch self.searchResult {
        case .users(let users): self.items = users.map { SuggestionViewModel(suggestion: $0) }
        case .sites(let sites):  self.items = sites.map { SuggestionViewModel(suggestion: $0) }
        }

        self.stateUpdated?(self)

        return items.count > 0
    }

    private static func searchResult(searchQuery: String, suggestions: Suggestions, suggestionType: SuggestionType, prominentSuggestionsIds: [NSNumber]) -> Suggestions {
        var searchResult: Suggestions
        if !searchQuery.isEmpty {
            let predicate = Self.predicate(for: searchQuery, suggestionType: suggestionType)
            searchResult = suggestions.filtered(using: predicate)
        } else {
            searchResult = suggestions
        }
        if case let .users(userSuggestions) = searchResult {
            searchResult = .users(Self.moveProminentSuggestionsToTop(searchResults: userSuggestions, prominentSuggestionsIds: prominentSuggestionsIds))
        }
        return searchResult
    }

    private static func moveProminentSuggestionsToTop(searchResults: [UserSuggestion], prominentSuggestionsIds ids: [NSNumber]) -> [UserSuggestion] {
        // Do not proceed if `searchResults` or `prominentSuggestionsIds` is empty.
        guard !(searchResults.isEmpty || ids.isEmpty) else { return searchResults }

        // Loop through `searchResults` and find the following data:
        //
        // 1. suggestionIndexesToRemove: User Suggestions should be removed from their old position.
        //
        // 2. suggestionsToInsert: User Suggestions to insert at the beginning of `searchResults`
        //                         while maintaining their order from `prominentSuggestionsIds`.
        //
        var suggestionIndexesToRemove = [Int]()
        var suggestionsToInsert: [UserSuggestion?] = Array(repeating: nil, count: ids.count)
        for (index, suggestion) in searchResults.enumerated() {
            guard let position = ids.firstIndex(where: { suggestion.userID == $0 }) else { continue }
            suggestionIndexesToRemove.append(index)
            suggestionsToInsert[position] = suggestion
        }

        // Move suggestions to the beginning of `searchResults` array.
        var searchResults = searchResults
        if !suggestionsToInsert.isEmpty && suggestionIndexesToRemove.count > 0 {
            let suggestionsToInsert = suggestionsToInsert.compactMap { $0 }
            suggestionIndexesToRemove = suggestionIndexesToRemove.sorted(by: >)
            suggestionIndexesToRemove.forEach { searchResults.remove(at: $0) }
            searchResults = suggestionsToInsert + searchResults
        }
        return searchResults
    }

    private static func predicate(for searchQuery: String, suggestionType: SuggestionType) -> NSPredicate {
        switch suggestionType {
        case .mention:
            return NSPredicate(format: "(displayName contains[c] %@) OR (username contains[c] %@)", searchQuery, searchQuery)
        case .xpost:
            return NSPredicate(format: "(title contains[cd] %@) OR (siteURL.absoluteString contains[cd] %@)", searchQuery, searchQuery)
        }
    }

    // MARK: - Types

    typealias StateUpdatedHandler = (SuggestionsListViewModelType) -> Void

}

// MARK: - List Type

extension SuggestionsListViewModel {

    enum Suggestions {
        case users([UserSuggestion])
        case sites([SiteSuggestion])

        var array: [Any] {
            switch self {
            case .users(let array): return array
            case .sites(let array): return array
            }
        }

        var count: Int {
            return array.count
        }

        func cleared() -> Suggestions {
            switch self {
            case .sites: return Suggestions.sites([])
            case .users: return Suggestions.users([])
            }
        }

        func filtered(using predicate: NSPredicate) -> Suggestions {
            switch self {
            case .users(let array):
                return .users(NSMutableArray(array: array).filtered(using: predicate) as! [UserSuggestion])
            case .sites(let array):
                return .sites(NSMutableArray(array: array).filtered(using: predicate) as! [SiteSuggestion])
            }
        }
    }

}
