final class SiteInformationStep: WizardStep {
    private let creator: SiteCreator

    private(set) lazy var content: UIViewController = {
        return SiteInformationWizardContent(completion: didGoNext)
    }()

    var delegate: WizardDelegate?

    init(creator: SiteCreator) {
        self.creator = creator
    }

    private func didGoNext(_ data: SiteInformation) {
        creator.information = data
        delegate?.wizard(self, willNavigateTo: WebAddressStep.identifier)
    }
}
