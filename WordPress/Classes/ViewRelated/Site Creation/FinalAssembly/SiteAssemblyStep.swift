
import UIKit

/// Site Creation, Last screen: Site Assembly.
final class SiteAssemblyStep: WizardStep {

    // MARK: Properties

    /// The creator collects user input as they advance through the wizard flow.
    private let creator: SiteCreator

    /// The service with which the final assembly interacts to coordinate site creation.
    private let service: SiteAssemblyService

    // MARK: WizardStep

    let content: UIViewController

    weak var delegate: WizardDelegate? = nil

    // MARK: SiteAssemblyStep

    /// The designated initializer.
    ///
    /// - Parameters:
    ///   - creator: the in-flight creation instance
    ///   - service: the service to use for initiating site creation
    ///   - onDismiss: the closure to be executed upon dismissal of the SiteAssemblyWizardContent
    init(creator: SiteCreator, service: SiteAssemblyService, onDismiss: ((Blog, Bool) -> Void)? = nil) {
        self.creator = creator
        self.service = service
        self.content = SiteAssemblyWizardContent(creator: creator, service: service, onDismiss: onDismiss)
    }
}
