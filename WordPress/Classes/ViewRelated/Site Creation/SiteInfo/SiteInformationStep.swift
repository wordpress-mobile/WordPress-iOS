final class SiteInformationStep: WizardStep {
    private let creator: SiteCreator
    private let service: SiteInformationService

    private(set) lazy var content: UIViewController = {
        return SiteInfoWizardContent(service: self.service)
    }()

    var delegate: WizardDelegate?

    init(creator: SiteCreator, service: SiteInformationService) {
        self.creator = creator
        self.service = service
    }
}
