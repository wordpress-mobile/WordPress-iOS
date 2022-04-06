import Foundation
import AutomatticTracks

/// Site Creation: Allows creation of the site's name.
final class SiteNameStep: WizardStep {
    weak var delegate: WizardDelegate?
    private let creator: SiteCreator

    private(set) lazy var content: UIViewController = {
        return SiteNameViewController(creator: creator)
    }()

    init?(
        siteIntentVariation: SiteIntentAB.Variant = SiteIntentAB.shared.variant,
        siteNameVariation: Variation = ABTest.siteNameV1.variation,
        creator: SiteCreator
    ) {
        // TODO: Send an event to track the site name variant.

        guard
            FeatureFlag.siteIntentQuestion.enabled,
            FeatureFlag.siteName.enabled,
            siteIntentVariation == .treatment,
            siteNameVariation == .treatment(nil)
        else {
            return nil
        }

        self.creator = creator
    }

    private func didSet(name: String?) {
        if let name = name {
            let currentTagline = creator.information?.tagLine
            creator.information = SiteInformation(title: name, tagLine: currentTagline)
        }

        delegate?.nextStep()
    }
}
