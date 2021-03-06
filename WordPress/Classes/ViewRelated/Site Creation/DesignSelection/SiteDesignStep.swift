import Foundation

/// Site Creation. First screen: Allows selection of the home page which translates to the initial theme as well.
final class SiteDesignStep: WizardStep {
    typealias SiteDesignSelection = (_ design: RemoteSiteDesign?) -> Void
    weak var delegate: WizardDelegate?
    private let creator: SiteCreator

    private(set) lazy var content: UIViewController = {
        return SiteDesignContentCollectionViewController { [weak self] (design) in
            self?.didSelect(design)
        }
    }()

    init(creator: SiteCreator) {
        self.creator = creator
    }

    private func didSelect(_ design: RemoteSiteDesign?) {
        creator.design = design
        delegate?.nextStep()
    }
}
