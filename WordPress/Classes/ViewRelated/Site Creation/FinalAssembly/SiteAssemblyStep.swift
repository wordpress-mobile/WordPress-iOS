
import UIKit

/// Site Creation, Last screen: Site Assembly.
///
final class SiteAssemblyStep: WizardStep {

    // MARK: Properties

    /// The creator collects user input as they advance through the wizard flow.
    private let creator: SiteCreator

    /// The service with which the final assembly interacts to coordinate site creation.
    private let service: SiteAssemblyService

    // MARK: WizardStep

    let content: UIViewController

    var delegate: WizardDelegate? = nil

    // MARK: SiteAssemblyStep

    init(creator: SiteCreator, service: SiteAssemblyService) {
        self.creator = creator
        self.service = service
        self.content = SiteAssemblyWizardContent(creator: creator, service: service)
    }
}
