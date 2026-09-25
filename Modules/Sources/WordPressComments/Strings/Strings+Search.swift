import Foundation

extension Strings {
    enum Search {
        static let prompt = NSLocalizedString(
            "commentsSearch.prompt",
            value: "Search comments",
            comment: "Comments search field placeholder and initial empty prompt"
        )
        static let noResults = NSLocalizedString(
            "commentsSearch.noResults",
            value: "No results",
            comment: "Shown after a comments search returns no matches"
        )
    }
}
