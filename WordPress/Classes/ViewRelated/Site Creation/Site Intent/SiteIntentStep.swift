import Foundation

/// Site Creation: Allows selection of the the site's vertical (a.k.a. intent or industry).
final class SiteIntentStep: WizardStep {
    typealias SiteIntentSelection = (_ vertical: SiteIntentVertical?) -> Void
    weak var delegate: WizardDelegate?
    private let creator: SiteCreator

    private(set) lazy var content: UIViewController = {
        return SiteIntentViewController { [weak self] vertical in
            self?.didSelect(vertical)
        }
    }()

    init(creator: SiteCreator) {
        self.creator = creator
    }

    private func didSelect(_ vertical: SiteIntentVertical?) {
        creator.vertical = vertical
        delegate?.nextStep()
    }
}
