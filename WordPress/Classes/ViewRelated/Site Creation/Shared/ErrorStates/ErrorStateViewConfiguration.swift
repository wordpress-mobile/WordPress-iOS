
import Foundation

// MARK: ErrorViewType

/// Describes the possible states of an error view presented during the Site Creation flow.
///
/// - general:              Describes an unforeseen problem occurred.
/// - siteLoading:          Describes a error that specifically occurred while attempting to create a site.
/// - networkUnreachable:   Describes a case where network connectivity was explicitly not available (see also : `NetworkAware`)
///
enum ErrorStateViewType {
    case general
    case networkUnreachable
    case siteLoading
}

// MARK: ErrorViewConfiguration

typealias ErrorStateViewActionHandler = () -> Void

/// Describes the desired appearance & behavior of an `ErrorStateView`
///
struct ErrorStateViewConfiguration {

    /// The title to display in the error state view
    let title: String

    /// The subtitle to display in the error state view. If not specified, it label will not be visible.
    let subtitle: String?

    /// The action to perform if a user taps the "Retry" button. If not specified, the button will not be visible.
    var retryActionHandler: ErrorStateViewActionHandler?

    /// The action to perform if a user taps the "Contact Support" label. If not specified, the label will not be visible.
    var contactSupportActionHandler: ErrorStateViewActionHandler?

    /// The action to perform if a user taps the "Dismiss" button. If not specified, the image will not be visible.
    var dismissalActionHandler: ErrorStateViewActionHandler?

    init(title: String, subtitle: String? = nil, retryActionHandler: ErrorStateViewActionHandler? = nil, contactSupportActionHandler: ErrorStateViewActionHandler? = nil, dismissalActionHandler: ErrorStateViewActionHandler? = nil) {

        self.title = title
        self.subtitle = subtitle
        self.retryActionHandler = retryActionHandler
        self.contactSupportActionHandler = contactSupportActionHandler
        self.dismissalActionHandler = dismissalActionHandler
    }
}

// MARK: ErrorStateViewConfiguration support

extension ErrorStateViewType {
    var localizedTitle: String {
        switch self {
        case .general, .siteLoading:
            return NSLocalizedString("There was a problem",
                                     comment: "This primary message message is displayed if a user encounters a general error.")
        case .networkUnreachable:
            return NSLocalizedString("No internet connection",
                                     comment: "This primary error message is displayed if a user encounters an issue with network reachability.")
        }
    }

    var localizedSubtitle: String? {
        switch self {
        case .general, .siteLoading:
            return NSLocalizedString("Error communicating with the server, please try again",
                                     comment: "This secondary message is displayed if a user encounters a general error.")
        case .networkUnreachable:
            return nil
        }
    }
}

extension ErrorStateViewConfiguration {
    /// Convenience method to instantiate a configuration of a known type.
    ///
    /// - Parameter type: the pre-defined configuration to create.
    /// - Returns: a configuration of the type specified.
    static func configuration(type: ErrorStateViewType) -> ErrorStateViewConfiguration {
        return ErrorStateViewConfiguration(title: type.localizedTitle, subtitle: type.localizedSubtitle)
    }
}
