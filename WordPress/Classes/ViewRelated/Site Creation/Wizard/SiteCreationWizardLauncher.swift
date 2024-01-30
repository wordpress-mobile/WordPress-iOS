import AutomatticTracks

/// Puts together the Site creation wizard, assembling steps.
final class SiteCreationWizardLauncher {
    private lazy var creator: SiteCreator = {
        return SiteCreator()
    }()

    let steps: [SiteCreationStep] = {
        if RemoteFeatureFlag.plansInSiteCreation.enabled() && AppConfiguration.isJetpack {
            return [
                .intent,
                .design,
                .address,
                .plan,
                .siteAssembly
            ]
        } else {
            return [
                .intent,
                .design,
                .address,
                .siteAssembly
            ]
        }
    }()

    private lazy var wizard: SiteCreationWizard = {
        return SiteCreationWizard(steps: steps.map { initStep($0) })
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

    init(
        onDismiss: ((Blog, Bool) -> Void)? = nil
    ) {
        self.onDismiss = onDismiss
    }

    private func initStep(_ step: SiteCreationStep) -> WizardStep {
        switch step {
        case .address:
            let addressService = DomainsServiceAdapter(coreDataStack: ContextManager.shared)
            return WebAddressStep(creator: self.creator, service: addressService)
        case .plan:
            return PlanStep(creator: self.creator)
        case .design:
            // we call dropLast to remove .siteAssembly
            let isLastStep = steps.dropLast().last == .design
            return SiteDesignStep(creator: self.creator, isLastStep: isLastStep)
        case .intent:
            return SiteIntentStep(creator: self.creator)
        case .segments:
            let segmentsService = SiteCreationSegmentsService(coreDataStack: ContextManager.sharedInstance())
            return SiteSegmentsStep(creator: self.creator, service: segmentsService)
        case .siteAssembly:
            let siteAssemblyService = EnhancedSiteCreationService(coreDataStack: ContextManager.sharedInstance())
            return SiteAssemblyStep(creator: self.creator, service: siteAssemblyService, onDismiss: onDismiss)
        }
    }
}
