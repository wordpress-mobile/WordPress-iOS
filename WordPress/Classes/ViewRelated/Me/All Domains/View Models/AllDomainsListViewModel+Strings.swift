import Foundation

extension AllDomainsListViewModel {

    enum Strings {
        static let emptyStateTitle = NSLocalizedString(
            "domain.management.default.empty.state.title",
            value: "You don't have any domains",
            comment: "The empty state title in All Domains screen when the user doesn't have any domains"
        )
        static let emptyStateDescription = NSLocalizedString(
            "domain.management.default.empty.state.description",
            value: "Tap the button below to add a new domain",
            comment: "The empty state description in All Domains screen when the user doesn't have any domains"
        )
        static let searchEmptyStateTitle = NSLocalizedString(
            "domain.management.search.empty.state.title",
            value: "No Matching Domains Found",
            comment: "The empty state title in All Domains screen when the are no domains matching the search criteria"
        )
        static func searchEmptyStateDescription(_ searchQuery: String) -> String {
            NSLocalizedString(
               "domain.management.search.empty.state.description",
               value: "We couldn't find any domains that match your search for '\(searchQuery)'",
               comment: "The empty state description in All Domains screen when the are no domains matching the search criteria"
           )
        }
        static let emptyStateButtonTitle = NSLocalizedString(
            "domain.management.default.empty.state.button.title",
            value: "Add a domain",
            comment: "The empty state button title in All Domains screen when the user doesn't have any domains"
        )
        static let offlineEmptyStateTitle = NSLocalizedString(
            "domain.management.offline.empty.state.title",
            value: "No Internet Connection",
            comment: "The empty state title in All Domains screen when the user is offline"
        )
        static let offlineEmptyStateDescription = NSLocalizedString(
            "domain.management.offline.empty.state.description",
            value: "Please check your network connection and try again.",
            comment: "The empty state description in All Domains screen when the user is offline"
        )
        static let errorEmptyStateTitle = NSLocalizedString(
            "domain.management.error.empty.state.title",
            value: "Something went wrong",
            comment: "The empty state title in All Domains screen when an error occurs"
        )
        static let errorEmptyStateDescription = NSLocalizedString(
            "domain.management.error.empty.state.description",
            value: "Sorry, we encountered an error while loading your domains. Our team has been notified of the issue, and we're working to resolve it as soon as possible. Please try again later.",
            comment: "The empty state description in All Domains screen when an error occurs"
        )
        static let errorStateButtonTitle = NSLocalizedString(
            "domain.management.error.state.button.title",
            value: "Try again",
            comment: "The empty state button title in All Domains screen when an error occurs"
        )
    }
}
