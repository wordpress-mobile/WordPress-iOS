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
            value: "Tap below to find your perfect domain.",
            comment: "The empty state description in All Domains screen when the user doesn't have any domains"
        )
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
