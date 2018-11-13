final class SiteInformationStep: WizardStep {
    private let creator: SiteCreator
    private let service: SiteInformationService

    private(set) lazy var content: UIViewController = {
        return SiteInformationWizardContent(service: self.service, completion: didGoNext)
    }()

    var delegate: WizardDelegate?

    init(creator: SiteCreator, service: SiteInformationService) {
        self.creator = creator
        self.service = service
    }

    private func didGoNext(_ data: SiteInformationCollectedData) {
        //creator.vertical = vertical
        // Will have to change to the basic information instead
        delegate?.wizard(self, willNavigateTo: WebAddressStep.identifier)
    }
}
