import Foundation

struct DomainsStateViewModel {
    let title: String
    let description: String
    let button: Button?

    struct Button {
        let title: String
        let action: () -> Void
    }
}

extension DomainsStateViewModel {
    static func errorMessageViewModel(from error: Error, action: @escaping () -> Void) -> DomainsStateViewModel {
        let title: String
        let description: String
        let button: DomainsStateViewModel.Button = .init(title: Strings.errorStateButtonTitle) {
            action()
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorNotConnectedToInternet {
            title = Strings.offlineEmptyStateTitle
            description = Strings.offlineEmptyStateDescription
        } else {
            title = Strings.errorEmptyStateTitle
            description = Strings.errorEmptyStateDescription
        }

        return .init(title: title, description: description, button: button)
    }
}

extension DomainsStateViewModel {
    enum Strings {
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
            value: "We encountered an error while loading your domains. Please contact support if the issue persists.",
            comment: "The empty state description in All Domains screen when an error occurs"
        )
        static let errorStateButtonTitle = NSLocalizedString(
            "domain.management.error.state.button.title",
            value: "Try again",
            comment: "The empty state button title in All Domains screen when an error occurs"
        )
    }
}
