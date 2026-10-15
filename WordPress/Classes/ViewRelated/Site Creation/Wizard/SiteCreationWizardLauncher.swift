import AutomatticTracks
import WordPressData

/// Puts together the Site creation wizard, assembling steps.
final class SiteCreationWizardLauncher {
    private lazy var creator = SiteCreator(flow: flow)

    let flow: SiteCreationFlow

    let steps: [SiteCreationStep]

    /// The WordPress app always runs the current flow and never shows the plan step.
    init(
        isJetpack: Bool = AppConfiguration.isJetpack,
        isShortFlowEnabled: Bool = FeatureFlag.siteCreationShortFlow.enabled,
        isPlansInSiteCreationEnabled: Bool = RemoteFeatureFlag.plansInSiteCreation.enabled()
    ) {
        let flow: SiteCreationFlow = isJetpack && isShortFlowEnabled ? .short : .current
        self.flow = flow
        self.steps = Self.steps(for: flow, includesPlan: isJetpack && isPlansInSiteCreationEnabled)
    }

    private static func steps(for flow: SiteCreationFlow, includesPlan: Bool) -> [SiteCreationStep] {
        let plan: [SiteCreationStep] = includesPlan ? [.plan] : []
        switch flow {
        case .current:
            return [.intent, .design, .address] + plan + [.siteAssembly]
        case .short:
            return [.address] + plan + [.siteAssembly]
        }
    }

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
        case .siteAssembly:
            let siteAssemblyService = EnhancedSiteCreationService(coreDataStack: ContextManager.shared)
            return SiteAssemblyStep(creator: self.creator, service: siteAssemblyService)
        }
    }
}
