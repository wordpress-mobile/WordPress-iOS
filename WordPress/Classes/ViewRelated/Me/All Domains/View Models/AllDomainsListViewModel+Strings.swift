import Foundation

extension AllDomainsListViewModel {

    enum Strings {
        static let emptyStateButtonTitle = NSLocalizedString(
            "domain.management.default.empty.state.button.title",
            value: "Find a domain",
            comment: "The empty state button title in All Domains screen when the user doesn't have any domains"
        )
        static let emptyStateTitle = NSLocalizedString(
            "domain.management.default.empty.state.title",
            value: "You don't have any domains",
            comment: "The empty state title in All Domains screen when the user doesn't have any domains"
        )
        static let emptyStateDescription = NSLocalizedString(
            "domain.management.default.empty.state.description",
            value: "Tap below to find your perfect domain.",
            comment: "The empty state description in All Domains screen when the user doesn't have any domains"
        )
        static let searchEmptyStateTitle = NSLocalizedString(
            "domain.management.search.empty.state.title",
            value: "No Matching Domains Found",
            comment: "The empty state title in All Domains screen when the are no domains matching the search criteria"
        )
        static func searchEmptyStateDescription(_ searchQuery: String) -> String {
            let format = NSLocalizedString(
                "domain.management.search.empty.state.description",
                value: "We couldn't find any domains that match your search for '%@'",
                comment: "The empty state description in All Domains screen when the are no domains matching the search criteria"
            )
            return String(format: format, searchQuery)
        }
    }
}
