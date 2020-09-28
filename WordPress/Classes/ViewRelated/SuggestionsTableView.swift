import Foundation

@objc public extension SuggestionsTableView {
    func suggestions(for siteID: NSNumber) -> [Suggestion]? {
        return SuggestionService.shared.suggestions(for: siteID)
    }
}
