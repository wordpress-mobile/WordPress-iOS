final class VerticalsStep: WizardStep {
    private let creator: SiteCreator
    private let service: SiteVerticalsService

    private(set) lazy var header: UIViewController = {
        let title = NSLocalizedString("What's the focus of your business?", comment: "Create site, step 2. Select focus of the business. Title")
        let subtitle = NSLocalizedString("We'll use your answer to add sections to your website.", comment: "Create site, step 2. Select focus of the business. Subtitle")
        let headerData = SiteCreationHeaderData(title: title, subtitle: subtitle)

        return SiteCreationWizardTitle(data: headerData)
    }()

    private(set) lazy var content: UIViewController = {
        return VerticalsWizardContent(segment: self.creator.segment, service: self.service, selection: self.didSelect)
    }()

    var delegate: WizardDelegate?

    init(creator: SiteCreator, service: SiteVerticalsService) {
        self.creator = creator
        self.service = service
    }

    private func didSelect(_ vertical: SiteVertical) {
        creator.vertical = vertical
        //delegate?.wizard(self, willNavigateTo: VerticalsStep.identifier)
    }
}
