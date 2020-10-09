import Foundation

@objc public extension SuggestionsTableView {
    func suggestions(for siteID: NSNumber, completion: @escaping ([AtMentionSuggestion]?) -> Void) {
        SuggestionService.shared.suggestions(for: siteID, completion: completion)
    }
}
