import Foundation
import CoreData

@objc final class SuggestionsListSection: NSObject {
    @objc var title: String?
    @objc var rows: [SuggestionViewModel] = []
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
    @objc private(set) var sections = [SuggestionsListSection]()

    private(set) var suggestions = Suggestions.users([])

    private var searchResult: SearchResult?

    var suggestionTrigger: String {
        return suggestionType.trigger
    }

    @objc private(set) var searchText: String = ""

    // MARK: - Callback

    /// Called when the search result is updated.
    @objc var searchResultUpdated: StateUpdatedHandler?

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
            self.searchResult = nil
        }

        // Map searchResult to sections
        self.sections = Self.sectionsFromSearchResult(searchResult)

        // Call callback and return result
        self.searchResultUpdated?(self)
        return sections.count > 0
    }

    private static func searchResult(searchQuery: String, suggestions: Suggestions, suggestionType: SuggestionType, prominentSuggestionsIds: [NSNumber]) -> SearchResult {
        var suggestions = suggestions
        if !searchQuery.isEmpty {
            let predicate = Self.predicate(for: searchQuery, suggestionType: suggestionType)
            suggestions = suggestions.filtered(using: predicate)
        }
        switch suggestions {
        case .users(let userSuggestions):
            let sortedUserSuggestions = Self.sort(
                userSuggestions: userSuggestions, by: searchQuery
            )
            return Self.searchResultByMovingProminentSuggestionsToTop(
                userSuggestions: sortedUserSuggestions,
                prominentSuggestionsIds: prominentSuggestionsIds
            )
        case .sites(let siteSuggestions):
            return .sites(siteSuggestions)
        }
    }

    /// Sort user suggestions by prefix first, then alphabetically. The collection is sorted first by checking if username or displayName begins with the provided prefix. The remaining items are sorted alphabetically by displayName. The prefix comparison is both case-insensitive and diacritic-insensitive.
    /// - Parameter userSuggestions: The user suggestions collection to be sorted.
    /// - Parameter prefix: The prefix to be used when checking the usernames and displayNames.
    /// - Returns: The sorted user suggestion collection.
    private static func sort(userSuggestions: [UserSuggestion], by prefix: String) -> [UserSuggestion] {
        guard !userSuggestions.isEmpty, !prefix.isEmpty else { return userSuggestions }
        let triagedList = Dictionary(grouping: userSuggestions) { suggestion in
            suggestion.username?.beginsWith(prefix: prefix, with: Self.compareOptions) == true || suggestion.displayName?.beginsWith(prefix: prefix, with: Self.compareOptions) == true
        }
        return (triagedList[true] ?? []).sorted() + (triagedList[false] ?? []).sorted()
    }

    private static func searchResultByMovingProminentSuggestionsToTop(userSuggestions: [UserSuggestion], prominentSuggestionsIds ids: [NSNumber]) -> SearchResult {
        // Do not proceed if `searchResults` or `prominentSuggestionsIds` is empty.
        guard !(userSuggestions.isEmpty || ids.isEmpty) else { return .users(prominent: [], regular: userSuggestions) }

        // Loop through `searchResults` and find the following data:
        //
        // 1. suggestionIndexesToRemove: User Suggestions should be removed from their old position.
        //
        // 2. suggestionsToInsert: User Suggestions to insert at the beginning of `searchResults`
        //                         while maintaining their order from `prominentSuggestionsIds`.
        //
        var suggestionIndexesToRemove = [Int]()
        var prominentSuggestions: [UserSuggestion?] = Array(repeating: nil, count: ids.count)
        for (index, suggestion) in userSuggestions.enumerated() {
            guard let position = ids.firstIndex(where: { suggestion.userID == $0 }) else { continue }
            suggestionIndexesToRemove.append(index)
            prominentSuggestions[position] = suggestion
        }

        // Move suggestions to the beginning of `searchResults` array.
        var userSuggestions = userSuggestions
        if !prominentSuggestions.isEmpty && suggestionIndexesToRemove.count > 0 {
            let prominentSuggestions = prominentSuggestions.compactMap { $0 }
            suggestionIndexesToRemove = suggestionIndexesToRemove.sorted(by: >)
            suggestionIndexesToRemove.forEach { userSuggestions.remove(at: $0) }
            return .users(prominent: prominentSuggestions, regular: userSuggestions)
        } else {
            return .users(prominent: [], regular: userSuggestions)
        }
    }

    private static func sectionsFromSearchResult(_ searchResult: SearchResult?) -> [Section] {
        guard let searchResult = searchResult else { return [] }
        switch searchResult {
        case .users(let prominent, let regular):
            let shouldShowSectionTitle = !prominent.isEmpty && !regular.isEmpty
            var sections = [Section]()
            if !prominent.isEmpty {
                let section = Section()
                if shouldShowSectionTitle {
                    section.title = NSLocalizedString("suggestions.section.prominent", value: "In this conversation", comment: "Section title for prominent suggestions")
                }
                section.rows = prominent.map { SuggestionViewModel(suggestion: $0) }
                sections.append(section)
            }
            if !regular.isEmpty {
                let section = Section()
                if shouldShowSectionTitle {
                    section.title = NSLocalizedString("suggestions.section.regular", value: "Site members", comment: "Section title for regular suggestions")
                }
                section.rows = regular.map { SuggestionViewModel(suggestion: $0) }
                sections.append(section)
            }
            return sections
        case .sites(let sites):
            let section = Section()
            section.rows = sites.map { SuggestionViewModel(suggestion: $0) }
            return [section]
        }
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

    typealias Section = SuggestionsListSection

    enum SearchResult {
        case users(prominent: [UserSuggestion], regular: [UserSuggestion])
        case sites([SiteSuggestion])
    }

    enum Suggestions {
        case users([UserSuggestion])
        case sites([SiteSuggestion])

        var users: [UserSuggestion] {
            switch self {
            case .users(let suggestions): return suggestions
            default: return []
            }
        }

        var sites: [SiteSuggestion] {
            switch self {
            case .sites(let suggestions): return suggestions
            default: return []
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
