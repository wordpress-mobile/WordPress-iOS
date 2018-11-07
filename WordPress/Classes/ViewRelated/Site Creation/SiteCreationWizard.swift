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
    func wizard(_ origin: WizardStep, willNavigateTo destination: Identifier) {
        debugPrint("==== will navigate ====")
        navigate(to: destination)
    }

    func wizard(_ origin: WizardStep, didNavigateTo destination: Identifier) {
        debugPrint("==== did navigate ====")
    }

    private func navigate(to: Identifier) {
        guard let destinationStep = step(identifier: to) else {
            return
        }

        guard let navigationController = content as? UINavigationController else {
            return
        }

        let newViewController = WizardViewController()
        navigationController.pushViewController(newViewController, animated: true)
        newViewController.render(step: destinationStep)
    }

    private func step(identifier: Identifier) -> WizardStep? {
        return steps.filter {
                $0.identifier == identifier
            }.first
    }
}
