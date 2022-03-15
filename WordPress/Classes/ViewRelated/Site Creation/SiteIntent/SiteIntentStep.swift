/// Site Intent: Allows selection of the the site's vertical (a.k.a. intent or industry).
final class SiteIntentStep: WizardStep {
    weak var delegate: WizardDelegate?
    private let creator: SiteCreator

    private(set) lazy var content: UIViewController = {
        return SiteIntentViewController()
    }()

    init?(siteIntentAB: SiteIntentABTestable = SiteIntentAB.shared, creator: SiteCreator) {
        guard FeatureFlag.siteIntentQuestion.enabled && siteIntentAB.variant == .treatment else {
            return nil
        }

        self.creator = creator
    }
}
