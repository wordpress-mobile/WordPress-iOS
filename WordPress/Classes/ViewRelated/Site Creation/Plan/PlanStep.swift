final class PlanStep: WizardStep {
    weak var delegate: WizardDelegate?

    private let creator: SiteCreator

    private(set) lazy var content: UIViewController = {
        return PlanWizardContent()
    }()

    init(creator: SiteCreator) {
        self.creator = creator
    }
}
