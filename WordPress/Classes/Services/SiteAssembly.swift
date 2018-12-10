
import Foundation

// MARK: - SiteAssembly

/// Describes the possible states of a site creation assembly service.
///
/// - idle:         Returned when the service is available to service requests.
/// - inProgress:   Returned once an assembly has begun.
/// - failed:       Returned if an assembly has failed to complete.
/// - succeeded:    Returned when an assembly has proceeded to completion.
///
enum SiteAssemblyStatus {
    case idle
    case inProgress
    case failed
    case succeeded
}

extension SiteAssemblyStatus: CustomStringConvertible {
    var description: String {
        // NB: The values not localized below are not user-facing.
        switch self {
        case .idle:
            return "Idle"
        case .inProgress:
            return NSLocalizedString("We’re creating your new site.",
                                     comment: "User-facing string, presented to reflect that site assembly is underway.")
        case .failed:
            return "Failed"
        case .succeeded:
            return "Succeeded"
        }
    }
}

// MARK: - SiteAssemblyService

/// Describes a service used to create a site.
protocol SiteAssemblyService {

    /// Describes the current state of the service.
    var currentStatus: SiteAssemblyStatus { get }
}

// MARK: - MockSiteAssemblyService

/// Fabricated instance of a `SiteAssemblyService`.
final class MockSiteAssemblyService: SiteAssemblyService {

    private(set) var currentStatus: SiteAssemblyStatus = .idle
}
