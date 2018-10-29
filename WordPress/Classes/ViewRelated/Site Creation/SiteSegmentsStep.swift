
/// Site Creation. First screen: Site Segments
final class SiteSegmentsStep: WizardStep {
    var identifier: Identifier {
        return Identifier(value: String(describing: self))
    }

    var header: UIViewController {
        return UIViewController()
    }

    var content: UIViewController {
        return UIViewController()
    }

    var delegate: WizardDelegate? 
}
