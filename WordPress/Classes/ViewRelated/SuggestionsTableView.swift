import Foundation

@objc public extension SuggestionsTableView {
    func suggestions(for siteID: NSNumber) -> [AtMentionSuggestion]? {
        return SuggestionService.shared.suggestions(for: siteID)
    }
}
