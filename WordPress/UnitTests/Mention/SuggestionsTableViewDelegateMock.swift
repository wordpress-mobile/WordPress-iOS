import Foundation

@testable import WordPress

final class SuggestionsTableViewDelegateMock: NSObject, SuggestionsTableViewDelegate {

    private(set) var selectedSuggestion: String?
    private(set) var searchText: String?

    func suggestionsTableView(_ suggestionsTableView: SuggestionsTableView, didSelectSuggestion suggestion: String?, forSearchText text: String) {
        self.selectedSuggestion = suggestion
        self.searchText = text
    }
}
