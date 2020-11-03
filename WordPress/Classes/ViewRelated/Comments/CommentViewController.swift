import Foundation

@objc public extension CommentViewController {
    func shouldShowSuggestions(for siteID: NSNumber?) -> Bool {
        guard let siteID = siteID, let blog = SuggestionService.shared.persistedBlog(for: siteID) else { return false }
        return SuggestionService.shared.shouldShowSuggestions(for: blog)
    }
}
