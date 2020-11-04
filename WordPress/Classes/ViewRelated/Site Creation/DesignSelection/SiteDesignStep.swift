import Foundation

/// Site Creation. First screen: Allows selection of the home page which translates to the initial theme as well.
final class SiteDesignStep: WizardStep {
    var delegate: WizardDelegate?

    private(set) lazy var content: UIViewController = {
        return SiteDesignContentViewController()
    }()
}
