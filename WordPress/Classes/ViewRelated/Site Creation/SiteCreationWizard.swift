/// Coordinates the UI flow for creating a new site
final class SiteCreationWizard: Wizard {
    private lazy var firstContentViewController: UIViewController? = {
        guard let firstStep = self.steps.first else {
            return nil
        }
        return firstStep.content
    }()

    private lazy var navigation: WizardNavigation? = {
        guard let first = self.firstContentViewController else {
            return nil
        }

        return WizardNavigation(root: first)
    }()

    lazy var content: UIViewController? = {
        return navigation?.content
    }()

    // The sequence of steps to complete the wizard.
    let steps: [WizardStep]

    init(steps: [WizardStep]) {
        self.steps = steps
        configureSteps()
    }

    /// This probably won't fly for too long.
    private func configureSteps() {
        for var step in steps {
            step.delegate = self
        }
    }
}

extension SiteCreationWizard: WizardDelegate {
    func wizard(_ origin: WizardStep, willNavigateTo destination: Identifier) {
        navigate(to: destination)
    }

    func wizard(_ origin: WizardStep, didNavigateTo destination: Identifier) {
    }

    private func navigate(to: Identifier) {
        guard let destinationStep = step(identifier: to) else {
            return
        }

        navigation?.push(destinationStep.content)
    }

    private func step(identifier: Identifier) -> WizardStep? {
        return steps.filter {
                $0.identifier == identifier
            }.first
    }
}
