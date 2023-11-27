final class PlanStep: WizardStep {
    weak var delegate: WizardDelegate?

    private let creator: SiteCreator

    internal var content: UIViewController {
        let viewModel = PlanWizardContentViewModel(siteCreator: creator)
        return PlanWizardContent(viewModel: viewModel) { [weak self] planId, domainName in
            self?.creator.planId = planId
            self?.creator.addressFromPlanSelection = domainName
            self?.delegate?.nextStep()
        }
    }

    init(creator: SiteCreator) {
        self.creator = creator
    }
}
