/// Terrible name. Puts together the Site creation wizard, assembling steps.
final class SiteCreationWizardLauncher: NSObject {
    private lazy var builder: SiteCreationBuilder = {
        return SiteCreationBuilder()
    }()

    private lazy var segmentsStep: WizardStep = {
        return SiteSegmentsStep(builder: self.builder, service: MockSiteSegmentsService())
    }()

    private lazy var steps: [WizardStep] =  {
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
