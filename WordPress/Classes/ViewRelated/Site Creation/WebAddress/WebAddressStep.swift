
/// Site Creation. Third screen: Domains
final class WebAddressStep: WizardStep {
    private let creator: SiteCreator
    private let service: SiteAddressService

    private(set) lazy var content: UIViewController = {
        return WebAddressWizardContent(creator: creator, service: self.service) { [weak self] (address) in
            self?.didSelect(address)
        }
    }()

    weak var delegate: WizardDelegate?

    init(creator: SiteCreator, service: SiteAddressService) {
        self.creator = creator
        self.service = service
    }

    private func didSelect(_ address: DomainSuggestion) {
        creator.address = address
        delegate?.nextStep()
    }
}
