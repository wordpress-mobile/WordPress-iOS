
/// Site Creation. Second screen: Site Verticals
final class VerticalsStep: WizardStep {
    private let creator: SiteCreator
    private let promptService: SiteVerticalsPromptService
    private let verticalsService: SiteVerticalsService

    private(set) lazy var content: UIViewController = {
        return VerticalsWizardContent(creator: self.creator, promptService: promptService, verticalsService: self.verticalsService, selection: self.didSelect)
    }()

    var delegate: WizardDelegate?

    init(creator: SiteCreator, promptService: SiteVerticalsPromptService, verticalsService: SiteVerticalsService) {
        self.creator = creator
        self.promptService = promptService
        self.verticalsService = verticalsService
    }

    private func didSelect(_ vertical: SiteVertical?) {
        creator.vertical = vertical
        delegate?.nextStep()
    }
}
