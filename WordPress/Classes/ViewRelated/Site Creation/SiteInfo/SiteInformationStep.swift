
/// Site Creation. Fourth screen: Site Info
final class SiteInformationStep: WizardStep {
    private let creator: SiteCreator

    private(set) lazy var content: UIViewController = {
        return SiteInformationWizardContent(completion: didSelect)
    }()

    var delegate: WizardDelegate?

    init(creator: SiteCreator) {
        self.creator = creator
    }

    private func didSelect(_ data: SiteInformation) {
        creator.information = data
        delegate?.nextStep()
    }
}
