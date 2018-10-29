/// Coordinates the UI flow for creating a new site
final class SiteCreationWizard: Wizard {

    // The sequence of steps to complete the wizard.
    let steps: [WizardStep]

    init(steps: [WizardStep]) {
        self.steps = steps
    }
}

extension SiteCreationWizard: WizardDelegate {
    func wizard(_ origin: WizardStep, willNavigateTo destination: Identifier) {}
    func wizard(_ origin: WizardStep, didNavigateTo destination: Identifier) {}
}
