/// Terrible name. Puts together the Site creation wizard, assembling steps.
final class SiteCreationWizardLauncher {
    private lazy var creator: SiteCreator = {
        return SiteCreator()
    }()

    private lazy var segmentsStep: WizardStep = {
        // It seems like we might need to pass the builder to all the steps. I am not too fond of inheritance in general, but this might make a good case for a base Step.
        // Actually, the address site looks exactly like this, so a generics-based approach might actually work better. I'll reconsider this setup after implementing the address step
        return SiteSegmentsStep(creator: self.creator, service: MockSiteSegmentsService())
    }()

    private lazy var verticalsStep: WizardStep = {
        return VerticalsStep(creator: self.creator, service: MockSiteVerticalsService())
    }()

    private lazy var addressStep: WizardStep = {
        return WebAddressStep(creator: self.creator, service: MockSiteAddressService())
    }()

    private lazy var siteInfoStep: WizardStep = {
        return SiteInformationStep(creator: self.creator)
    }()

    private lazy var siteAssemblyStep: WizardStep = {
        return SiteAssemblyStep(creator: self.creator, service: MockSiteAssemblyService(shouldSucceed: false))
    }()

    private lazy var steps: [WizardStep] = {
        return [
            self.segmentsStep,
            self.verticalsStep,
            self.siteInfoStep,
            self.addressStep,
            self.siteAssemblyStep
        ]
    }()

    private lazy var wizard: SiteCreationWizard = {
        return SiteCreationWizard(steps: self.steps)
    }()

    lazy var ui: UIViewController? = {
        guard let wizardContent = wizard.content else {
            return nil
        }
        return wizardContent
    }()
}
