
import UIKit

/// Site Creation, Last screen: Site Assembly.
///
final class SiteAssemblyStep: WizardStep {

    // MARK: Properties

    private let creator: SiteCreator

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
