/// Terrible name. Puts together the Site creation wizard, assembling steps.
final class SiteCreationWizardLauncher: NSObject {
    private lazy var builder: SiteCreationBuilder = {
        return SiteCreationBuilder()
    }()

    private lazy var segmentsStep: WizardStep = {
        // It seems like we might need to pass the builder to all the steps. I am not too fond of inheritance in general, but this might make a good case for a base Step
        return SiteSegmentsStep(builder: self.builder, service: MockSiteSegmentsService())
    }()

    private lazy var steps: [WizardStep] = {
        return [self.segmentsStep]
    }()

    private lazy var wizard: SiteCreationWizard = {
        return SiteCreationWizard(steps: self.steps)
    }()

    @objc
    lazy var ui: UIViewController = {
        return wizard.ui
    }()
}
