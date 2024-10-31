import Foundation

@objc protocol SuggestionsListViewModelType: AnyObject {
    var suggestionType: SuggestionType { get set }
    var prominentSuggestionsIds: [NSNumber]? { get set }

    var searchResultUpdated: ((SuggestionsListViewModelType) -> Void)? { get set }

    var isLoading: Bool { get }
    var searchText: String { get }

    var sections: [SuggestionsListSection] { get }

    func reloadData()
    func searchSuggestions(withWord word: String) -> Bool
}

extension SuggestionsListViewModelType {

    var numberOfSections: Int {
        return sections.count
    }

    var numberOfItems: Int {
        return sections.reduce(0) { $0 + $1.rows.count }
    }

    func numberOfItems(inSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func item(at indexPath: IndexPath) -> SuggestionViewModel {
        return sections[indexPath.section].rows[indexPath.row]
    }
}
