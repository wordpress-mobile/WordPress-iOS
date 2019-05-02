
import Foundation

// MARK: - SiteAssembly

/// Describes the possible states of a site creation assembly service.
///
/// - idle:         Returned when the service is available to service requests.
/// - inProgress:   Returned once an assembly has begun.
/// - failed:       Returned if an assembly has failed to complete.
/// - succeeded:    Returned when an assembly has proceeded to completion.
///
enum SiteAssemblyStatus: Equatable {
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

    /// Returns the created `Blog` if available; `nil` otherwise
    var createdBlog: Blog? { get }

    /// This method serves as the primary means with which to initiate site assembly.
    ///
    /// - Parameters:
    ///   - creationRequest:    the parameters that should be used to assemble the site
    ///   - changeHandler:      a closure to execute when the status of the site assembly changes, invoked on the main queue
    func createSite(creationRequest: SiteCreationRequest, changeHandler: SiteAssemblyStatusChangedHandler?)
}

// MARK: - MockSiteAssemblyService

/// Fabricated instance of a `SiteAssemblyService`.
final class MockSiteAssemblyService: NSObject, SiteAssemblyService {

    // MARK: Properties

    private(set) var shouldMockSuccess: Bool

    private(set) var currentStatus: SiteAssemblyStatus = .idle {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.statusChangeHandler?(self.currentStatus)
            }
        }
    }

    private(set) var statusChangeHandler: SiteAssemblyStatusChangedHandler?

    let createdBlog: Blog? = nil

    // MARK: SiteAssemblyService

    init(shouldSucceed: Bool = true) {
        self.shouldMockSuccess = shouldSucceed
        super.init()
    }

    func createSite(creationRequest: SiteCreationRequest, changeHandler: SiteAssemblyStatusChangedHandler?) {
        self.statusChangeHandler = changeHandler
        currentStatus = .inProgress

        let contrivedDelay = DispatchTimeInterval.milliseconds(50)
        let dispatchDelay = DispatchTime.now() + contrivedDelay
        DispatchQueue.main.asyncAfter(deadline: dispatchDelay) { [weak self] in
            guard let self = self else {
                return
            }

            let mockStatus: SiteAssemblyStatus
            if self.shouldMockSuccess {
                mockStatus = .succeeded
            } else {
                mockStatus = .failed
            }
            self.currentStatus = mockStatus
        }
    }
}
