/// Site Creation. Second screen: Site Verticals
final class VerticalsStep: WizardStep {
    private let creator: SiteCreator
    private let service: SiteVerticalsService

    private(set) lazy var content: UIViewController = {
        return VerticalsWizardContent(segment: self.creator.segment, service: self.service, selection: self.didSelect)
    }()

    var delegate: WizardDelegate?

    init(creator: SiteCreator, service: SiteVerticalsService) {
        self.creator = creator
        self.service = service
    }

    private func didSelect(_ vertical: SiteVertical) {
        creator.vertical = vertical
        // Will have to change to the basic information instead
        delegate?.wizard(self, willNavigateTo: WebAddressStep.identifier)
    }
}
