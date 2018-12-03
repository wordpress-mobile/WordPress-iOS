
/// Site Creation. First screen: Site Segments
final class SiteSegmentsStep: WizardStep {
    private let creator: SiteCreator
    private let service: SiteSegmentsService

    private(set) lazy var content: UIViewController = {
        return SiteSegmentsWizardContent(service: self.service, selection: self.didSelect)
    }()

    var delegate: WizardDelegate?

    init(creator: SiteCreator, service: SiteSegmentsService) {
        self.creator = creator
        self.service = service
    }

    private func didSelect(_ segment: SiteSegment) {
        creator.segment = segment
        delegate?.nextStep()
    }
}
