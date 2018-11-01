/// Coordinates the UI flow for creating a new site
final class SiteCreationWizard: Wizard {
    lazy var ui: UIViewController = {
        let content = WizardViewController()
        return UINavigationController(rootViewController: content)
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
    func wizard(_ origin: WizardStep, willNavigateTo destination: Identifier) {}
    func wizard(_ origin: WizardStep, didNavigateTo destination: Identifier) {}
}
