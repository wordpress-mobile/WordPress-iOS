import Foundation

@objc public extension SuggestionsTableView {
    func suggestions(for siteID: NSNumber, completion: @escaping ([UserSuggestion]?) -> Void) {
        guard let blog = SuggestionService.shared.persistedBlog(for: siteID) else { return }
        SuggestionService.shared.suggestions(for: blog, completion: completion)
    }
}
