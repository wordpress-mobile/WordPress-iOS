/// Puts together the Site creation wizard, assembling steps.
final class SiteCreationWizardLauncher {
    private lazy var creator: SiteCreator = {
        return SiteCreator()
    }()

    private lazy var segmentsStep: WizardStep = {
        let segmentsService = SiteCreationSegmentsService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        return SiteSegmentsStep(creator: self.creator, service: segmentsService)
    }()

    private lazy var verticalsStep: WizardStep = {
        let promptService = SiteCreationVerticalsPromptService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        let verticalsService = SiteCreationVerticalsService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        return VerticalsStep(creator: self.creator, promptService: promptService, verticalsService: verticalsService)
    }()

    private lazy var addressStep: WizardStep = {
        let addressService = DomainsServiceAdapter(managedObjectContext: ContextManager.sharedInstance().mainContext)
        return WebAddressStep(creator: self.creator, service: addressService)
    }()

    private lazy var siteInfoStep: WizardStep = {
        return SiteInformationStep(creator: self.creator)
    }()

    private lazy var siteAssemblyStep: WizardStep = {
        let siteAssemblyService = EnhancedSiteCreationService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        return SiteAssemblyStep(creator: self.creator, service: siteAssemblyService)
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

        wizardContent.modalPresentationStyle = .fullScreen
        return wizardContent
    }()
}
