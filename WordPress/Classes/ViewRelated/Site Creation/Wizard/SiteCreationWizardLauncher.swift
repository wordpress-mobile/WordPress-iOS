/// Puts together the Site creation wizard, assembling steps.
final class SiteCreationWizardLauncher {
    private lazy var creator: SiteCreator = {
        return SiteCreator()
    }()

    private lazy var segmentsStep: WizardStep = {
        let segmentsService = SiteCreationSegmentsService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        return SiteSegmentsStep(creator: self.creator, service: segmentsService)
    }()

    private lazy var designStep: WizardStep = {
        return SiteDesignStep(creator: self.creator)
    }()

    private lazy var addressStep: WizardStep = {
        let addressService = DomainsServiceAdapter(managedObjectContext: ContextManager.sharedInstance().mainContext)
        return WebAddressStep(creator: self.creator, service: addressService)
    }()

    private lazy var siteAssemblyStep: WizardStep = {
        let siteAssemblyService = EnhancedSiteCreationService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        return SiteAssemblyStep(creator: self.creator, service: siteAssemblyService)
    }()

    private lazy var steps: [WizardStep] = {
        let initialStep = FeatureFlag.siteCreationHomePagePicker.enabled ? self.designStep : self.segmentsStep
        return [
            initialStep,
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

        if FeatureFlag.siteCreationHomePagePicker.enabled {
            if #available(iOS 13.0, *) {
                wizardContent.modalPresentationStyle = .pageSheet
                wizardContent.isModalInPresentation = true
            } else {
                // Specifically using fullScreen instead of pageSheet to get the desired behavior on Max devices running iOS 12 and below.
                wizardContent.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .pad ? .pageSheet : .fullScreen
            }
        } else {
            wizardContent.modalPresentationStyle = .fullScreen
        }

        return wizardContent
    }()
}
