import Foundation
import AutomatticTracks

struct SiteCreationWizardStepOrderer {
    let stepInvoker: SiteCreationWizardStepInvoker
    let siteIntentVariant: SiteIntentAB.Variant
    let siteNameVariant: Variation

    private var shouldShowSiteIntent: Bool {
        return siteIntentVariant == .treatment && FeatureFlag.siteIntentQuestion.enabled
    }

    private var shouldShowSiteName: Bool {
        return siteNameVariant == .treatment(nil) && FeatureFlag.siteName.enabled
    }

    lazy var steps: [WizardStep] = {
        guard shouldShowSiteIntent else {
            return [
                stepInvoker.designStep,
                stepInvoker.addressStep,
                stepInvoker.siteAssemblyStep
            ]
        }

        guard shouldShowSiteName else {
            return [
                stepInvoker.intentStep,
                stepInvoker.designStep,
                stepInvoker.addressStep,
                stepInvoker.siteAssemblyStep
            ]
        }

        return [
            stepInvoker.intentStep,
            stepInvoker.nameStep,
            stepInvoker.designStep,
            stepInvoker.siteAssemblyStep
        ]
    }()
}
