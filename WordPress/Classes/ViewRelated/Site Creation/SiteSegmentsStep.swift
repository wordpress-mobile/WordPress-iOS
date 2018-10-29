
/// Site Creation. First screen: Site Segments
final class SiteSegmentsStep: WizardStep {
    private let service: SiteSegmentsService

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

    init(service: SiteSegmentsService) {
        self.service = service
    }
}
