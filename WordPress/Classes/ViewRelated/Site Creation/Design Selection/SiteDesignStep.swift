import Foundation

/// Site Creation: Allows selection of the home page which translates to the initial theme as well.
final class SiteDesignStep: WizardStep {
    typealias SiteDesignSelection = (_ design: RemoteSiteDesign?) -> Void
    weak var delegate: WizardDelegate?
    private let creator: SiteCreator
    private let isLastStep: Bool

    private(set) lazy var content: UIViewController = {
        return SiteDesignContentCollectionViewController(creator: creator, createsSite: isLastStep) { [weak self] (design) in
            self?.didSelect(design)
        }
    }()

    init(creator: SiteCreator, isLastStep: Bool) {
        self.creator = creator
        self.isLastStep = isLastStep
    }

    private func didSelect(_ design: RemoteSiteDesign?) {
        creator.design = design
        delegate?.nextStep()
    }
}
