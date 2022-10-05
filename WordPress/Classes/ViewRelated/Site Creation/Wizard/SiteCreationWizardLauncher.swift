import AutomatticTracks

/// Puts together the Site creation wizard, assembling steps.
final class SiteCreationWizardLauncher {
    private lazy var creator: SiteCreator = {
        return SiteCreator()
    }()

    private var shouldShowSiteIntent: Bool {
        return FeatureFlag.siteIntentQuestion.enabled
    }

    private var shouldShowSiteName: Bool {
        return FeatureFlag.siteName.enabled
    }

    lazy var steps: [SiteCreationStep] = {
        // If Site Intent shouldn't be shown, fall back to the original steps.
        guard shouldShowSiteIntent else {
            return [
                .design,
                .address,
                .siteAssembly
            ]
        }

        // If Site Intent should be shown but not the Site Name, only add Site Intent.
        guard shouldShowSiteName else {
            return [
                .intent,
                .design,
                .address,
                .siteAssembly
            ]
        }

        // If Site Name should be shown, swap out the Site Address step.
        return [
            .intent,
            .name,
            .design,
            .siteAssembly
        ]
    }()

    private lazy var wizard: SiteCreationWizard = {
        return SiteCreationWizard(steps: steps.map { initStep($0) })
    }()

    lazy var ui: UIViewController? = {
        guard let wizardContent = wizard.content else {
            return nil
        }
        wizardContent.modalPresentationStyle = .fullScreen
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
            let addressService = DomainsServiceAdapter(managedObjectContext: ContextManager.sharedInstance().mainContext)
            return WebAddressStep(creator: self.creator, service: addressService)
        case .design:
            // we call dropLast to remove .siteAssembly
            let isLastStep = steps.dropLast().last == .design
            return SiteDesignStep(creator: self.creator, isLastStep: isLastStep)
        case .intent:
            return SiteIntentStep(creator: self.creator)
        case .name:
            return SiteNameStep(creator: self.creator)
        case .segments:
            let segmentsService = SiteCreationSegmentsService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            return SiteSegmentsStep(creator: self.creator, service: segmentsService)
        case .siteAssembly:
            let siteAssemblyService = EnhancedSiteCreationService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            return SiteAssemblyStep(creator: self.creator, service: siteAssemblyService, onDismiss: onDismiss)
        }
    }
}
