/// Coordinates the UI flow for creating a new site
final class SiteCreationWizard: Wizard {
    private lazy var firstContentViewController: UIViewController? = {
        guard let firstStep = self.steps.first else {
            return nil
        }
        return firstStep.content
    }()

    private lazy var navigation: WizardNavigation? = {
        return WizardNavigation(steps: self.steps)
    }()

    lazy var content: UIViewController? = {
        return navigation?.content
    }()

    // The sequence of steps to complete the wizard.
    let steps: [WizardStep]

    init(steps: [WizardStep]) {
        self.steps = steps
    }
}
