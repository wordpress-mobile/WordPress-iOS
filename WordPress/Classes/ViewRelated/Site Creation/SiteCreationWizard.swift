/// Coordinates the UI flow for creating a new site
final class SiteCreationWizard: Wizard {
    private lazy var contentViewController = {
        WizardViewController()
    }()

    lazy var content: UIViewController = {
        return UINavigationController(rootViewController: self.contentViewController)
    }()

    // The sequence of steps to complete the wizard.
    let steps: [WizardStep]

    init(steps: [WizardStep]) {
        self.steps = steps
        configureSteps()
        runWizard()
    }

    /// This probably won't fly for too long.
    private func configureSteps() {
        for var step in steps {
            step.delegate = self
        }
    }

    private func runWizard() {
        guard let firstStep = steps.first else {
            return
        }

        contentViewController.render(step: firstStep)
    }
}

extension SiteCreationWizard: WizardDelegate {
    func wizard(_ origin: WizardStep, willNavigateTo destination: Identifier) {}
    func wizard(_ origin: WizardStep, didNavigateTo destination: Identifier) {}
}
