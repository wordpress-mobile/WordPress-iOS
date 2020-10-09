import Foundation

@objc public extension CommentViewController {
    func shouldShowSuggestions(for siteID: NSNumber?) -> Bool {
        guard let siteID = siteID else { return false }
        return SuggestionService.shared.shouldShowSuggestions(for: siteID)
    }
}
