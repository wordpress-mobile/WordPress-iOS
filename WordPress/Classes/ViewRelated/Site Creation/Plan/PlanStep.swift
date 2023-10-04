final class PlanStep: WizardStep {
    weak var delegate: WizardDelegate?

    private let creator: SiteCreator

    private(set) lazy var content: UIViewController = {
        let viewModel = PlanWizardContentViewModel(siteCreator: creator)
        return PlanWizardContent(viewModel: viewModel) { [weak self] planId in
            self?.creator.planId = planId
            self?.delegate?.nextStep()
        }
    }()

    init(creator: SiteCreator) {
        self.creator = creator
    }
}
