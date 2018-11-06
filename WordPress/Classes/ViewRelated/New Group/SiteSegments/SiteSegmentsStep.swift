
/// Site Creation. First screen: Site Segments
final class SiteSegmentsStep: WizardStep {
    private let creator: SiteCreator
    private let service: SiteSegmentsService

    private(set) lazy var header: UIViewController = {
        let title = NSLocalizedString("Tell us what kind of site you'd like to make", comment: "Create site, step 1. Select type of site. Title")
        let subtitle = NSLocalizedString("This helps us suggest a solid foundation. But you're never locked in -- all sites evolve!", comment: "Create site, step 1. Select type of site. Subtitle")
        let headerData = SiteCreationHeaderData(title: title, subtitle: subtitle)

        return SiteCreationWizardTitle(data: headerData)
    }()

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
        delegate?.wizard(self, willNavigateTo: Identifier(value: "hola"))
    }
}
