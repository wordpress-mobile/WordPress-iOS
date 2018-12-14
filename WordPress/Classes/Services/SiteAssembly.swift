
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

// MARK: - SiteAssemblyService

typealias SiteAssemblyStatusChangedHandler = (SiteAssemblyStatus) -> Void

/// Describes a service used to create a site.
protocol SiteAssemblyService {

    /// Describes the current state of the service.
    var currentStatus: SiteAssemblyStatus { get }

    /// This method serves as the primary means with which to initiate site assembly.
    ///
    /// - Parameters:
    ///   - assemblyInput: the parameters that should be used to assemble the site
    ///   - changeHandler: a closure to execute when the status of the site assembly changes, invoked on the main queue
    func createSite(creatorOutput assemblyInput: SiteCreatorOutput, changeHandler: SiteAssemblyStatusChangedHandler?)
}

// MARK: - MockSiteAssemblyService

/// Fabricated instance of a `SiteAssemblyService`.
final class MockSiteAssemblyService: NSObject, SiteAssemblyService {

    // MARK: Properties

    private(set) var currentStatus: SiteAssemblyStatus = .idle {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.statusChangeHandler?(strongSelf.currentStatus)
            }
        }
    }

    private(set) var statusChangeHandler: SiteAssemblyStatusChangedHandler?

    // MARK: SiteAssemblyService

    func createSite(creatorOutput assemblyInput: SiteCreatorOutput, changeHandler: SiteAssemblyStatusChangedHandler?) {
        self.statusChangeHandler = changeHandler
        currentStatus = .inProgress

        let contrivedDelay = DispatchTimeInterval.seconds(3)
        let dispatchDelay = DispatchTime.now() + contrivedDelay
        DispatchQueue.main.asyncAfter(deadline: dispatchDelay) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.currentStatus = .succeeded
        }
    }
}
