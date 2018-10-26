

protocol Wizard {
    var steps: [WizardStep] { get }
}

protocol WizardDelegate {
    // Before
    func wizard(_ wizard: Wizard, willNavigateToDestinationWith identifier: Identifier)

    // After
    func wizard(_ wizard: Wizard, didNavigateToDestinationWith identifier: Identifier)
}

// My thinking with the use of the delegate pattern is that it works well for 1:1 relationships.
// Moreover, having a central place for these callbacks allows us to consolidate things like a state machine, analytics, etc.
// It could also be used if we need to centrally manage either interstitial (i.e. loading indicator) or empty state content
final class SiteCreationWizard: Wizard {

    // The sequence of steps to complete the wizard. This may not be practical if it's too dynamic.
    let steps: [WizardStep]

    init(steps: [WizardStep]) {
        self.steps = steps
    }
}

extension SiteCreationWizard: WizardDelegate {
    func wizard(_ wizard: Wizard, willNavigateToDestinationWith identifier: Identifier) {}
    func wizard(_ wizard: Wizard, didNavigateToDestinationWith identifier: Identifier) {}
}
