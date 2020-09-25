import Foundation

@objc public extension CommentViewController {
    func shouldShowSuggestions(for siteID: NSNumber?) -> Bool {
        return SuggestionService.sharedInstance().shouldShowSuggestions(for: siteID)
    }
}
