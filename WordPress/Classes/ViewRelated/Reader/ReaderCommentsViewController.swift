import Foundation

@objc public extension ReaderCommentsViewController {
    func shouldShowSuggestions(for siteID: NSNumber?) -> Bool {
        return SuggestionService.shared.shouldShowSuggestions(for: siteID)
    }
}
