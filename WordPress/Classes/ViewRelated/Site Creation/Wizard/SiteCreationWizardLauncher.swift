import AutomatticTracks

/// Puts together the Site creation wizard, assembling steps.
final class SiteCreationWizardLauncher: SiteCreationWizardStepInvoker {
    private var stepOrderer: SiteCreationWizardStepOrderer?

    private lazy var creator: SiteCreator = {
        return SiteCreator()
    }()

    internal lazy var segmentsStep: WizardStep = {
        let segmentsService = SiteCreationSegmentsService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        return SiteSegmentsStep(creator: self.creator, service: segmentsService)
    }()

    internal lazy var intentStep: WizardStep = {
        return SiteIntentStep(creator: self.creator)
    }()

    internal lazy var nameStep: WizardStep = {
        return SiteNameStep(creator: self.creator)
    }()

    internal lazy var designStep: WizardStep = {
        return SiteDesignStep(creator: self.creator)
    }()

    internal lazy var addressStep: WizardStep = {
        let addressService = DomainsServiceAdapter(managedObjectContext: ContextManager.sharedInstance().mainContext)
        return WebAddressStep(creator: self.creator, service: addressService)
    }()

    internal lazy var siteAssemblyStep: WizardStep = {
        let siteAssemblyService = EnhancedSiteCreationService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        return SiteAssemblyStep(creator: self.creator, service: siteAssemblyService, onDismiss: onDismiss)
    }()

    private lazy var wizard: SiteCreationWizard = {
        return SiteCreationWizard(steps: self.stepOrderer?.steps ?? [])
    }()

    lazy var ui: UIViewController? = {
        guard let wizardContent = wizard.content else {
            return nil
        }

        wizardContent.modalPresentationStyle = .pageSheet
        wizardContent.isModalInPresentation = true

        return wizardContent
    }()

    /// Closure to be executed upon dismissal of the SiteAssemblyWizardContent.
    ///
    private let onDismiss: ((Blog, Bool) -> Void)?

    init(onDismiss: ((Blog, Bool) -> Void)? = nil) {
        self.onDismiss = onDismiss

        stepOrderer = SiteCreationWizardStepOrderer(
            stepInvoker: self,
            siteIntentVariant: SiteIntentAB.shared.variant,
            siteNameVariant: ABTest.siteNameV1.variation
        )
    }
}
